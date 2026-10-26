# Adapter: Claude Code и Claude Desktop

Claude Code:
- Положи папку в `~/.claude/skills/yandex-taxi-skill/` (глобально) или `.claude/skills/yandex-taxi-skill/` (проект). SKILL.md грузится по описанию.
- Нужен bash-доступ: все шаги идут через `scripts/yandex-taxi.sh`. В разрешениях (`permissions.allow`) добавь `Bash(~/.claude/skills/yandex-taxi-skill/scripts/yandex-taxi.sh:*)` и `Bash(agent-browser:*)`.
- Команду `confirm --yes` лучше НЕ добавлять в авторазрешённые: пусть Claude Code каждый раз просит подтверждение. Это встроенный второй ключ.

Claude Desktop:
- Skills: загрузи папку архивом `.skill`/zip в Settings → Capabilities → Skills (нужен включённый code execution), или
- MCP: подключи сервер с доступом к командной строке (например filesystem+shell MCP) и положи набор в его рабочую папку. Без bash-доступа набор не работает: браузер агента это внешняя программа.
- Геопозиция: попроси текстом адрес или «lat, lon».
