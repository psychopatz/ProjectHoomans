---
name: dt-logging-control
description: Use when working on project zomboid logging noise, subsystem log toggles, or `console.txt` analysis. Applies runtime logging presets and overrides through the same options config used by the in-game Logs tab, lists discovered subsystems, and summarizes DynamicTrading console output into token-efficient reports while preserving warn/error lines.
---

# DynamicTrading Logging Control

Use this skill when you need to change log visibility or inspect noisy console output across the DynamicTrading mod stack: `DynamicTrading`, `DynamicColonies`, `DynamicObjectives`, `CurrencyExpanded`, and `MarketSense`.

## Workflow

1. Use `scripts/log_control.py list-subsystems` to see known `version/system` keys and any raw print hotspots.
2. Use `scripts/log_control.py preset <quiet|npc-dev|trade-dev|radio-dev|colonies-dev|objectives-dev|currency-dev|marketsense-dev|all-debug>` to switch the runtime UI preset.
3. Use `scripts/log_control.py set-level --subsystem <key> --level <off|info|debug|trace>` for targeted runtime overrides.
4. Use `scripts/log_control.py trace-console --lines <n>` to summarize `console.txt`.

## Notes

- Runtime toggles are written to `~/Zomboid/Lua/DynamicTrading_Config.txt` by default, which is the same config the in-game `Logs` tab edits.
- Preset definitions still come from `Contents/mods/DynamicTradingCommon/42.16/media/lua/shared/DT/Common/Logging/DT_LogProfile.lua`.
- The script scans sibling workshop repos as well, so `list-subsystems` covers the whole active mod stack, not just `DynamicTrading`.
- `preset` resets runtime overrides so the selected UI preset is applied cleanly.
- `warn` and `error` are always emitted by the runtime logger even when the profile is quiet.
- The legacy `debugLogs` / `DynamicTrading.Debug` path has been removed; non-warn/error output now comes only from presets and subsystem overrides.

## Commands

```bash
python3 .agent/skills/dt-logging-control/scripts/log_control.py list-subsystems
python3 .agent/skills/dt-logging-control/scripts/log_control.py preset quiet
python3 .agent/skills/dt-logging-control/scripts/log_control.py preset colonies-dev
python3 .agent/skills/dt-logging-control/scripts/log_control.py set-level --subsystem DTV2/NPC --level debug
python3 .agent/skills/dt-logging-control/scripts/log_control.py trace-console --lines 2000
```
