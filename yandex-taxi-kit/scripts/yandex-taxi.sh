#!/usr/bin/env bash
# Яндекс Такси через agent-browser. Конфиг: $TAXI_CONFIG или ~/.config/yandex-taxi-kit/config.env
#   preflight                 - браузер, ОС, сеть, гео-блок, конфиг, state
#   stage                     - определить стадию (одно слово) и шаг, куда прыгать
#   state-check [файл]        - проверить state: JSON, Session_id, права 600
#   state-save                - сохранить вход из живого сеанса (tmp -> проверка -> бэкап -> 600)
#   quote FROM TO             - цены и подача, ничего не выбирает
#   prepare FROM TO           - выбрать тариф из разрешённых + карту + скриншот. «Заказать» НЕ нажимает
#   confirm --yes             - нажать «Заказать» в подготовленной сессии
#   status                    - текст экрана + скриншот
#   close                     - закрыть сеанс, удалить временные файлы
# FROM/TO: имя из PLACE_<имя> или "lat,lon"
# Коды выхода: 2 ТОЧКА, 3 LOGIN_LOST, 4 NO_TARIFFS, 5 NO_ALLOWED, 6 TARIFF_FAIL, 7 CARD_FAIL,
#              8 NO_ORDER_BUTTON, 9 GEO_BLOCK, 10 NO_BROWSER, 11 NO_CONFIG, 12 NO_STATE, 13 NOT_CONFIGURED
set -u
CONF="${TAXI_CONFIG:-$HOME/.config/yandex-taxi-kit/config.env}"
# defaults
TAXI_HOST=taxi.yandex.uz; LANG_UI=ru; SESSION=taxi-kit; STATE="$HOME/.config/yandex-taxi-kit/state.json"
TMP=/tmp/yandex-taxi-kit; ACCOUNT_NAME=""; CARD_LABEL=""; ALLOWED_TARIFFS="Business|Электрик"
if [ -f "$CONF" ]; then . "$CONF"; HAVE_CONF=1; else HAVE_CONF=0; fi
mkdir -p "$TMP"
AB="agent-browser --session $SESSION"
cmd="${1:-}"

snap() { $AB snapshot -i 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g'; }
tariffs() { snap | grep -E 'radio ".*Цена' | sed -E 's/^ *- radio "([^"]*)" \[checked=([a-z]+), ref=(e[0-9]+)\].*/\3|\2|\1/' | sed 's/Нажмите, чтобы узнать о тарифе //; s/Высокий спрос //'; }
need_conf() { [ "$HAVE_CONF" = 1 ] || { echo "NO_CONFIG: нет $CONF (шаблон: config.example.env)"; exit 11; }; }
pt() { # имя места или lat,lon -> lat,lon
  case "$1" in
    *[0-9],*[0-9]) echo "$1"; return;;
  esac
  local v="PLACE_$1"; local val="${!v:-}"
  [ -n "$val" ] || { echo "ERR: точка '$1' не задана (PLACE_$1) и это не lat,lon" >&2; return 2; }
  case "$val" in 00.000000*) echo "ERR: PLACE_$1 - пример из шаблона, впиши свои координаты" >&2; return 13;; esac
  echo "$val"
}
state_ok() { # $1 файл; печатает причину при провале
  python3 -I - "$1" <<'PY'
import json,sys,os,stat
p=sys.argv[1]
if not os.path.isfile(p): print("нет файла"); sys.exit(1)
try: d=json.load(open(p))
except Exception as e: print("JSON не читается:",e); sys.exit(1)
ck=d.get("cookies") or []
ys=[c for c in ck if c.get("name")=="Session_id" and "yandex" in c.get("domain","")]
if not ys: print("нет Session_id для yandex"); sys.exit(1)
doms=sorted({c["domain"] for c in ys})
mode=stat.S_IMODE(os.stat(p).st_mode)
print("OK cookies=%d Session_id_domains=%s mode=%o"%(len(ck),",".join(doms),mode))
sys.exit(0 if mode==0o600 else 2)
PY
}
open_route() {
  need_conf
  local f t; f=$(pt "$1") || exit $?; t=$(pt "$2") || exit $?
  [ -f "$STATE" ] || { echo "NO_STATE: нет $STATE (вход: references/02-login-qr.md)"; exit 12; }
  $AB state load "$STATE" >/dev/null 2>&1; $AB set viewport 1440 900 >/dev/null 2>&1
  $AB open "https://$TAXI_HOST/?gfrom=$f&gto=$t&lang=$LANG_UI" >/dev/null 2>&1
  for i in $(seq 1 25); do sleep 1; [ -n "$(tariffs)" ] && break; done
  local s; s=$(snap)
  if echo "$s" | grep -qiE 'captcha|robot|Подтвердите, что вы не робот'; then echo "GEO_BLOCK: капча или блок по IP"; exit 9; fi
  if [ -n "$ACCOUNT_NAME" ]; then echo "$s" | grep -q "$ACCOUNT_NAME" || { echo "LOGIN_LOST: имя аккаунта не найдено, нужен QR"; exit 3; }
  else echo "$s" | grep -qE 'Авторизоваться для заказа|button "Войти"' && { echo "LOGIN_LOST: вход слетел, нужен QR"; exit 3; }; fi
  echo "$s" | grep -E 'textbox "(Откуда|Куда)' | sed -E 's/^ *- textbox "([^"]*)" \[ref=e[0-9]+\]: ?/\1: /'
  [ -n "$(tariffs)" ] || { echo "NO_TARIFFS: тарифы не загрузились"; exit 4; }
  echo "TARIFFS:"; tariffs | cut -d'|' -f3 | sed 's/^/  /'
}
pick() { # разрешённый тариф с минимальной подачей; при равенстве - раньше в ALLOWED_TARIFFS
  tariffs | awk -F'|' -v allowed="$ALLOWED_TARIFFS" '
    BEGIN{n=split(allowed,A,"|")}
    { if (match($3,/^[0-9]+ мин /)) { split($3,w," "); mins=w[1]; rest=$3; sub(/^[0-9]+ мин /,"",rest);
        for(i=1;i<=n;i++){ if (index(rest,A[i]" ")==1 || rest==A[i]) { print mins*100+i "|" $0; break } } } }' \
  | sort -t'|' -k1,1n | head -1 | cut -d'|' -f2-
}
card_selected() { snap | grep -q "button \"Способ оплаты $CARD_LABEL\""; }
ensure_card() {
  [ -n "$CARD_LABEL" ] || return 1
  for try in 1 2 3; do
    card_selected && return 0
    $AB eval "document.querySelector('button[class*=payment-method-button]').click()" >/dev/null 2>&1; sleep 2
    local ref; ref=$(snap | grep -F "radio \"$CARD_LABEL" | grep -oE 'ref=e[0-9]+' | head -1 | cut -d= -f2)
    [ -n "$ref" ] && $AB click "@$ref" >/dev/null 2>&1; sleep 2
  done
  card_selected
}
case "$cmd" in
preflight)
  rc=0
  command -v agent-browser >/dev/null && echo "OK agent-browser $(agent-browser --version 2>&1 | head -1)" || { echo "FAIL NO_BROWSER: npm i -g agent-browser && agent-browser install"; rc=10; }
  echo "OK ОС: $(uname -sm)"
  for b in curl python3; do command -v $b >/dev/null && echo "OK $b" || { echo "FAIL нет $b"; rc=10; }; done
  code=$(curl -s -o /dev/null -m 15 -w '%{http_code}' "https://$TAXI_HOST/?lang=ru" 2>/dev/null || true)
  case "$code" in 200|301|302|303) echo "OK сеть: https://$TAXI_HOST -> $code";; 403|429|451) echo "FAIL GEO_BLOCK: $code (IP режется; нужен IP страны или другой сервер)"; rc=9;; 000|"") echo "FAIL сеть: нет ответа (DNS/файрвол)"; rc=9;; *) echo "WARN сеть: код $code";; esac
  if [ "$HAVE_CONF" = 1 ]; then echo "OK конфиг $CONF"; else echo "FAIL NO_CONFIG $CONF"; rc=11; fi
  if [ -f "$STATE" ]; then r=$(state_ok "$STATE"); echo "state: $r"; else echo "WARN NO_STATE $STATE"; fi
  exit $rc;;
stage)
  # 1. браузер
  command -v agent-browser >/dev/null || { echo "STAGE=NO_BROWSER -> references/01-preflight.md"; exit 10; }
  # 2. конфиг
  [ "$HAVE_CONF" = 1 ] || { echo "STAGE=NO_CONFIG -> references/04-setup.md"; exit 11; }
  # 3. state
  r=$(state_ok "$STATE"); rc=$?
  [ $rc -ne 1 ] || { echo "STAGE=NO_LOGIN ($r) -> references/02-login-qr.md"; exit 12; }
  [ $rc -eq 0 ] || echo "WARN: права state не 600 -> chmod 600 '$STATE'"
  # 4. адреса и тарифы
  [ -n "$ALLOWED_TARIFFS" ] || { echo "STAGE=NOT_CONFIGURED (тарифы) -> references/04-setup.md"; exit 13; }
  places=$(set | grep -E '^PLACE_[A-Za-z0-9_]+=' | grep -vE "=('?)00\.000000" | wc -l)
  [ "$places" -ge 2 ] || { echo "STAGE=NOT_CONFIGURED (меньше двух мест) -> references/04-setup.md"; exit 13; }
  # 5. заказ уже идёт?
  if $AB get url >/dev/null 2>&1; then
    body=$($AB eval "document.body.innerText.slice(0,1500)" 2>/dev/null | tail -1)
    echo "$body" | grep -qiE 'Отменить заказ|Ищем машину|Водитель|Машина едет|Машина приехала|Поездка' && { echo "STAGE=ORDER_ACTIVE -> references/06-monitor.md"; exit 0; }
  fi
  # 6. вход и карта на живой странице
  p1=$(set | grep -E '^PLACE_[A-Za-z0-9_]+=' | grep -vE "=('?)00\.000000" | sed -n 1p | sed -E 's/^PLACE_([A-Za-z0-9_]+)=.*/\1/')
  p2=$(set | grep -E '^PLACE_[A-Za-z0-9_]+=' | grep -vE "=('?)00\.000000" | sed -n 2p | sed -E 's/^PLACE_([A-Za-z0-9_]+)=.*/\1/')
  out=$("$0" quote "$p1" "$p2" 2>&1); rc=$?
  case $rc in 3) echo "STAGE=LOGIN_LOST -> references/02-login-qr.md"; exit 3;; 9) echo "STAGE=GEO_BLOCK -> references/01-preflight.md"; exit 9;; 0) ;; *) echo "STAGE=ERROR($rc) $out -> references/07-errors.md"; exit $rc;; esac
  ensure_card || { echo "STAGE=NO_CARD -> references/03-card.md"; exit 7; }
  echo "STAGE=READY -> references/05-order.md"; exit 0;;
state-check) r=$(state_ok "${2:-$STATE}"); rc=$?; echo "$r"; exit $rc;;
state-save)
  need_conf
  t="$TMP/state-new.json"; rm -f "$t"
  ok=0
  for try in 1 2 3; do # демон agent-browser иногда отвечает "Resource temporarily unavailable" - повтор с паузой
    timeout 40 $AB state save "$t" >/dev/null 2>&1 && [ -s "$t" ] && { ok=1; break; }
    sleep 4
  done
  [ $ok = 1 ] || { echo "SAVE_FAIL: state save не сработал за 3 попытки (07-errors)"; exit 12; }
  chmod 600 "$t"
  r=$(state_ok "$t"); rc=$?; echo "новый: $r"
  [ $rc -ne 1 ] || { echo "ОТКАЗ: новый state плохой, старый не тронут"; rm -f "$t"; exit 12; }
  mkdir -p "$(dirname "$STATE")"; chmod 700 "$(dirname "$STATE")" 2>/dev/null
  [ -f "$STATE" ] && cp -p "$STATE" "${STATE%.json}.bak.json"
  cp "$t" "$STATE" && chmod 600 "$STATE" && rm -f "$t"
  echo "СОХРАНЕНО: $STATE (бэкап: ${STATE%.json}.bak.json)"; state_ok "$STATE";;
quote) open_route "${2:-}" "${3:-}";;
prepare)
  open_route "${2:-}" "${3:-}" || exit $?
  line=$(pick); [ -n "$line" ] || { echo "NO_ALLOWED: нет разрешённого тарифа - не заказывать"; exit 5; }
  name=$(echo "$line" | cut -d'|' -f3)
  $AB click "@${line%%|*}" >/dev/null 2>&1; sleep 1
  tariffs | grep "|true|" | grep -qF "$name" || { echo "TARIFF_FAIL"; exit 6; }
  echo "CHOSEN: $name"
  ensure_card || { echo "CARD_FAIL: карта '$CARD_LABEL' не выбрана - не заказывать"; exit 7; }
  echo "PAY: $CARD_LABEL"
  $AB screenshot "$TMP/prepare.png" >/dev/null 2>&1 && echo "SHOT: $TMP/prepare.png";;
confirm)
  [ "${2:-}" = "--yes" ] || { echo "ОТКАЗ: confirm только с --yes и только после слова владельца"; exit 2; }
  need_conf
  card_selected || { echo "CARD_FAIL: сначала prepare"; exit 7; }
  ref=$(snap | grep -E 'button "Заказать"' | grep -oE 'ref=e[0-9]+' | head -1 | cut -d= -f2)
  [ -n "$ref" ] || { echo "NO_ORDER_BUTTON"; exit 8; }
  $AB click "@$ref" >/dev/null 2>&1; echo "ORDERED"; sleep 20
  "$0" status;;
status)
  $AB eval "document.body.innerText.slice(0,1200)" 2>/dev/null | tail -1
  f="$TMP/status-$(date +%H%M%S).png"; $AB screenshot "$f" >/dev/null 2>&1 && echo "SHOT: $f";;
close) $AB close >/dev/null 2>&1; rm -rf "$TMP"; echo closed;;
*) sed -n 2,13p "$0";;
esac
