# Adapter: Codex (AGENTS.md)

Codex не грузит SKILL.md сам. Положи папку в репозиторий/домашнюю папку и добавь в `AGENTS.md`:

```
## Яндекс Такси
Запросы «такси до …», «цена поездки», «где машина»: прочитай yandex-taxi-kit/SKILL.md и следуй ему.
Скрипт: yandex-taxi-kit/scripts/yandex-taxi.sh. Сначала `stage`.
Команду `confirm --yes` запускай только после явного «заказывай» от пользователя.
Конфиг: ~/.config/yandex-taxi-kit/config.env. Секреты не печатай.
```

Песочница Codex должна разрешать сеть и запуск `agent-browser`. Если сеть закрыта, набор не заработает.
