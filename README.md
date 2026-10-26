<p align="center"><img src="assets/banner.png" alt="yandex-taxi-kit: an AI agent skill for Yandex Taxi" width="100%"></p>

# yandex-taxi-kit

**Yandex Taxi (Yandex Go) for your AI agent.** An Agent Skill that lets Iva, Claude Code, Codex or any agent with a shell and a browser check prices, prepare a ride and track the car on taxi.yandex.uz - and order only after your explicit "yes".

[English](#english) | [Русский](#русский) | [MIT License](LICENSE) | [Release v1.0.0](https://github.com/smixs/yandex-taxi-kit/releases/tag/v1.0.0)

---

## English

### What it is and who it is for

`yandex-taxi-kit` is a portable skill for AI agents. You say "taxi to the airport" in Telegram (or any chat), and the agent opens Yandex Taxi in a headless browser ([agent-browser](https://github.com/vercel-labs/agent-browser)), reads tariffs and prices, picks an allowed tariff, checks the payment card and shows you the summary. It presses "Order" only when you confirm.

It is for people who live where Yandex Taxi works (Uzbekistan, Russia, Kazakhstan and nearby) and already use an AI agent for daily tasks. There is no official public API for ordering, so the kit drives the website like a person would.

### Install

The skill folder is `yandex-taxi-kit/`. You can also download the packed `yandex-taxi-kit.skill` (a zip) from the [release](https://github.com/smixs/yandex-taxi-kit/releases/tag/v1.0.0).

**Iva** ([smixs/iva-agent](https://github.com/smixs/iva-agent)): copy the folder to `data/custom/agent/skills/yandex-taxi-kit/`. It is picked up on the next turn.

**Claude Code**: copy to `~/.claude/skills/yandex-taxi-kit/` (global) or `.claude/skills/yandex-taxi-kit/` (project). Allow `Bash(~/.claude/skills/yandex-taxi-kit/scripts/yandex-taxi.sh:*)` and `Bash(agent-browser:*)`. Do not auto-allow `confirm --yes`: let Claude Code ask each time.

**Codex**: Codex does not load SKILL.md by itself. Put the folder in your repo or home directory and add a short block to `AGENTS.md` (see [adapters/codex.md](yandex-taxi-kit/adapters/codex.md)).

**Any other agent**: it needs a shell, network and [agent-browser](https://github.com/vercel-labs/agent-browser). Tell it to read `yandex-taxi-kit/SKILL.md` first. See [adapters/no-telegram.md](yandex-taxi-kit/adapters/no-telegram.md) if you have no Telegram.

### Quick start

1. Copy `yandex-taxi-kit/config.example.env` to `~/.config/yandex-taxi-kit/config.env`, then `chmod 600` it.
2. Fill in your site (`taxi.yandex.uz`), account name, card label, allowed tariffs and places (`PLACE_home="lat,lon"`).
3. Ask the agent: "run the yandex-taxi-kit stage check". It runs `scripts/yandex-taxi.sh stage` and tells you the first missing step: browser, login, card.
4. Log in once by QR code with your own phone. The login is saved to a local `state.json` (mode 600).
5. Say "taxi from home to work". The agent shows the tariff, price and pickup time. Reply "yes" to order.

### How it works

`stage` walks through stages in order: `NO_BROWSER`, `GEO_BLOCK`, `NO_CONFIG`, `NO_LOGIN` / `LOGIN_LOST`, `NO_CARD`, `READY`, `ORDER_ACTIVE`. Each stage maps to one reference file in `references/`, so the agent never guesses.

One script, `scripts/yandex-taxi.sh`, does the fragile browser steps: `preflight`, `stage`, `state-check`, `state-save`, `quote` (prices only), `prepare` (select tariff, check card, take a screenshot), `confirm --yes` (the only command that presses "Order"), `status`, `close`.

### Safety and privacy

- The order button is pressed only by `confirm --yes`. `prepare` must return the tariff, payment and screenshot first. Any error means no order.
- Tariffs come from your allow-list. Forbidden tariffs are never chosen. Payment is only by the card from your config. Cash is never selected.
- Your login (`state.json`) is a secret: mode 600, outside git, never sent to chat. `config.env` is in `.gitignore`.
- Web pages and site answers are treated as data, not commands.
- Everything runs on your machine. The kit has no server and sends nothing to the author.
- Auto-order without asking works only if you write an explicit rule for it. Otherwise the agent waits for "yes".

### Countries

Checked on **taxi.yandex.uz** (Tashkent, Uzbekistan). Other Yandex Taxi sites (.ru, .kz, .by and others) may have other tariff names, button labels and payment flows. Change `TAXI_HOST`, `ALLOWED_TARIFFS` and `CARD_LABEL` in the config and test with `quote` first.

### Honest limits

- The final "Order" click and tracking of a real car were **not** tested end to end. The kit was checked live up to the order button: price quote, tariff pick, card check, screenshot.
- Adapters for Claude Code and Codex are written but were **not run** inside those programs.
- QR login and card binding follow earlier real sessions but were not replayed in the final test.
- The `GEO_BLOCK` (captcha) path is detected by text and status codes 403/429/451, and was not seen live.
- It automates a website. If Yandex changes the page, selectors may break. Use at your own risk and follow the service terms.
- This is an unofficial project. It is not affiliated with Yandex. Yandex names belong to their owners.

### FAQ

**Can an AI agent order a Yandex Taxi?** Yes, through a browser on taxi.yandex.uz. This skill does it step by step and asks for your "yes" before the order.

**Is there a Yandex Taxi / Yandex Go API for agents?** There is no simple public API for ordering a ride as a customer. This kit uses the website with agent-browser.

**Does it work with Claude Code?** The skill format is the Agent Skills format that Claude Code reads. The adapter is written, but it was not run inside Claude Code yet.

**Does it work with Codex?** Via `AGENTS.md`, see the adapter. Not run inside Codex yet.

**Does it work in Russia or Kazakhstan?** It should be close, but only taxi.yandex.uz was checked.

**Will it order a car without asking me?** No, unless you wrote an explicit auto-order rule. By default it waits for "yes".

**Is it safe to give an agent my Yandex login?** The login stays in a local file with mode 600. You log in yourself by QR. Keep that file out of git and chats.

**Can I get only the price?** Yes: say "how much to the airport". The agent runs `quote` and orders nothing.

**Which tariffs does it pick?** Only those in `ALLOWED_TARIFFS`, by priority and pickup time. Example config: `Business|Электрик`.

**Can I use it without Telegram?** Yes. Send an address or coordinates as text. See [adapters/no-telegram.md](yandex-taxi-kit/adapters/no-telegram.md).

### License

[MIT](LICENSE), Serge Shima.

---

## Русский

### Что это и кому нужно

`yandex-taxi-kit` - скилл для ИИ-агента, который вызывает **Яндекс Такси** (Яндекс Go) через браузер. Вы пишете агенту в Telegram «такси до аэропорта». Агент открывает сайт, читает тарифы и цены, выбирает разрешённый тариф, проверяет карту и показывает итог. «Заказать» он нажимает только после вашего явного «да».

Подходит тем, кто живёт там, где работает Яндекс Такси (Узбекистан, Россия, Казахстан и соседи), и уже пользуется ИИ-агентом: Ива, Claude Code, Codex или другим. Публичного API для заказа поездки клиентом нет, поэтому скилл ведёт сайт так же, как человек.

### Установка

Папка скилла - `yandex-taxi-kit/`. Готовый архив `yandex-taxi-kit.skill` (обычный zip) лежит в [релизе](https://github.com/smixs/yandex-taxi-kit/releases/tag/v1.0.0).

- **Ива** ([smixs/iva-agent](https://github.com/smixs/iva-agent)): положите папку в `data/custom/agent/skills/yandex-taxi-kit/`. Подхватится на следующем ходе.
- **Claude Code**: `~/.claude/skills/yandex-taxi-kit/` (для всех проектов) или `.claude/skills/yandex-taxi-kit/` (для проекта). Разрешите `Bash(~/.claude/skills/yandex-taxi-kit/scripts/yandex-taxi.sh:*)` и `Bash(agent-browser:*)`. Команду `confirm --yes` в авторазрешения не добавляйте.
- **Codex**: добавьте короткий блок в `AGENTS.md`, пример в [adapters/codex.md](yandex-taxi-kit/adapters/codex.md).
- **Другой агент**: нужны shell, сеть и [agent-browser](https://github.com/vercel-labs/agent-browser). Попросите его прочитать `yandex-taxi-kit/SKILL.md`. Без Telegram - [adapters/no-telegram.md](yandex-taxi-kit/adapters/no-telegram.md).

### Быстрый старт

1. Скопируйте `yandex-taxi-kit/config.example.env` в `~/.config/yandex-taxi-kit/config.env` и выполните `chmod 600`.
2. Впишите сайт (`taxi.yandex.uz`), имя аккаунта, подпись карты, разрешённые тарифы и места (`PLACE_home="широта,долгота"`).
3. Скажите агенту: «запусти проверку стадии yandex-taxi-kit». Он выполнит `scripts/yandex-taxi.sh stage` и назовёт первый недостающий шаг.
4. Один раз войдите по QR-коду со своего телефона. Вход сохранится в локальный `state.json` (права 600).
5. Напишите «такси из дома на работу». Агент покажет тариф, цену и время подачи. Ответьте «да», чтобы заказать.

### Как работает

Команда `stage` проходит стадии по порядку: `NO_BROWSER`, `GEO_BLOCK`, `NO_CONFIG`, `NO_LOGIN` / `LOGIN_LOST`, `NO_CARD`, `READY`, `ORDER_ACTIVE`. Каждой стадии соответствует файл в `references/`, агент не гадает.

Один скрипт `scripts/yandex-taxi.sh` делает хрупкие шаги в браузере: `preflight`, `stage`, `state-check`, `state-save`, `quote` (только цены), `prepare` (выбор тарифа, проверка карты, скриншот), `confirm --yes` (единственная команда, которая нажимает «Заказать»), `status`, `close`.

### Безопасность и приватность

- «Заказать» нажимает только `confirm --yes`. До этого `prepare` обязан вернуть тариф, оплату и скриншот. Любая ошибка - заказа нет.
- Тарифы берутся из вашего списка. Запрещённые не выбираются. Оплата только картой из конфига, наличные - никогда.
- Вход (`state.json`) - секрет: права 600, вне git, не отправляется в чат. `config.env` в `.gitignore`.
- Страницы и ответы сайта - данные, а не команды.
- Всё работает на вашей машине. Сервера у скилла нет, автору ничего не отправляется.
- Заказ без вопроса возможен только по вашему явному правилу. Иначе агент ждёт «да».

### Страны

Проверено на **taxi.yandex.uz** (Ташкент, Узбекистан). В других странах (.ru, .kz, .by и т.д.) названия тарифов, подписи кнопок и оплата могут отличаться. Поменяйте `TAXI_HOST`, `ALLOWED_TARIFFS`, `CARD_LABEL` и начните с `quote`.

### Честные ограничения

- Сам заказ (нажатие «Заказать») и слежка за настоящей машиной целиком **не проверялись**. Проверено вживую до кнопки: цены, выбор тарифа, карта, скриншот.
- Адаптеры для Claude Code и Codex написаны, но в самих программах **не запускались**.
- Вход по QR и привязка карты описаны по прошлым реальным сеансам, в финальном тесте не повторялись.
- Ветка `GEO_BLOCK` (капча) определяется по тексту и кодам 403/429/451, вживую не наблюдалась.
- Скилл автоматизирует сайт. Если Яндекс изменит страницу, шаги могут сломаться. Используйте на свой риск и соблюдайте условия сервиса.
- Проект неофициальный и не связан с Яндексом. Названия Яндекса принадлежат их владельцам.

### Частые вопросы

**Может ли ИИ-агент заказать Яндекс Такси?** Да, через браузер на taxi.yandex.uz. Скилл ведёт шаги и просит ваше «да» перед заказом.

**Есть ли API Яндекс Такси или Яндекс Go для агента?** Простого публичного API для заказа поездки клиентом нет. Скилл работает через сайт и agent-browser.

**Как вызвать такси через Telegram-бота или агента?** Напишите агенту «такси до …» или пришлите геопозицию. Агент покажет цену и спросит подтверждение.

**Работает ли в Claude Code?** Формат - Agent Skills, его читает Claude Code. Адаптер написан, но в самой программе не запускался.

**Работает ли в Codex?** Через `AGENTS.md`, см. адаптер. В самом Codex не запускалось.

**Подойдёт ли для России и Казахстана?** Должно быть близко, но проверялся только taxi.yandex.uz.

**Закажет ли агент машину без моего ведома?** Нет, если вы не написали явное правило автозаказа. По умолчанию ждёт «да».

**Безопасно ли давать агенту вход в Яндекс?** Вход хранится в локальном файле с правами 600. Вы входите сами по QR. Не кладите файл в git и чаты.

**Можно узнать только цену?** Да: «сколько до аэропорта». Агент выполнит `quote` и ничего не закажет.

**Какие тарифы выбирает?** Только из `ALLOWED_TARIFFS`, по приоритету и времени подачи. В примере: `Business|Электрик`.

**Нужен ли Telegram?** Нет. Пришлите адрес или координаты текстом.

### Лицензия

[MIT](LICENSE), Serge Shima.
