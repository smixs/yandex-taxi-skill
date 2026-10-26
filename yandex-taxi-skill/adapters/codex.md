# Adapter: Codex (AGENTS.md)

Codex не грузит SKILL.md сам. Положи папку в репозиторий/домашнюю папку и добавь в `AGENTS.md`:

```
## Яндекс Такси
Запросы «такси до …», «цена поездки», «где машина»: прочитай yandex-taxi-skill/SKILL.md и следуй ему.
Скрипт: yandex-taxi-skill/scripts/yandex-taxi.sh. Сначала `stage`.
Команду `confirm --yes` запускай только после явного «заказывай» от пользователя.
Конфиг: ~/.config/yandex-taxi-skill/config.env. Секреты не печатай.
```

Песочница Codex должна разрешать сеть и запуск `agent-browser`. Если сеть закрыта, набор не заработает.
