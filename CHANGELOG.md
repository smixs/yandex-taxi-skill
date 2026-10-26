# Changelog

## 1.1.0 - 2026-10-26

- Renamed the project from `yandex-taxi-kit` to `yandex-taxi-skill` ("Yandex Taxi Skill"). The old GitHub address redirects. Skill name, folder and archive are now `yandex-taxi-skill`.
- New banner and a separate 1280x640 social preview.
- Config path is now `~/.config/yandex-taxi-skill/`. If you used the old folder `~/.config/yandex-taxi-kit/`, move it.

## 1.0.0 - 2026-10-26

First public release.

- Stage detection: `yandex-taxi.sh stage` finds the first missing step (browser, config, login, card) and points to the right reference.
- One shell script: `preflight`, `stage`, `state-check`, `state-save`, `quote`, `prepare`, `confirm --yes`, `status`, `close`.
- Safety: the order button is pressed only by `confirm --yes`. Tariffs come from an allow-list. Payment only by the saved card.
- `state-save` retries 3 times and never overwrites a working login file on failure.
- Adapters: Iva, Claude Code / Claude Desktop, Codex (AGENTS.md), no-Telegram.
- Checked live on taxi.yandex.uz up to the order button (quote, tariff pick, card check). The order click and live car tracking were not tested.
