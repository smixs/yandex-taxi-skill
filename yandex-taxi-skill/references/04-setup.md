# 04. Настройка: места, тарифы, карта, имя

1. `mkdir -p ~/.config/yandex-taxi-skill && cp config.example.env ~/.config/yandex-taxi-skill/config.env && chmod 600` на этот файл. Или `export TAXI_CONFIG=путь`.
2. Впиши:
   - `TAXI_HOST` - сайт страны.
   - `STATE` - где лежит вход.
   - `ACCOUNT_NAME` - имя, как оно видно на сайте после входа.
   - `CARD_LABEL` - подпись карты в окне оплаты, символ в символ.
   - `PLACE_<имя>="lat,lon"` - минимум два места (дом, работа, аэропорт и т.д.). Имя потом пишешь в команде: `quote home work`.
   - `ALLOWED_TARIFFS` - через `|`; при равной подаче выигрывает тот, кто раньше в списке.
3. Незнакомый адрес в координаты: геокодер Nominatim:
   `curl -s -A kit "https://nominatim.openstreetmap.org/search?street=<номер>+<улица>&city=<город>&country=<страна>&format=json&limit=3"`.
   Несколько вариантов или ни одного - спроси владельца.
4. Названия тарифов бери с живой страницы (`quote` печатает список). Они на языке интерфейса.
5. Проверка: `scripts/yandex-taxi.sh stage`. Пока в `PLACE_*` стоят нули из шаблона, скрипт скажет NOT_CONFIGURED.

Личные данные (адреса, код двери, имя, карта) живут только в этом config.env. Не копируй его в набор.
