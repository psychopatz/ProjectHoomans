#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import sys
from collections import Counter
from pathlib import Path


WORKSPACE_ROOT = Path(__file__).resolve().parents[4]
WORKSHOP_ROOT = WORKSPACE_ROOT.parent
PROFILE_PATH = WORKSPACE_ROOT / "Contents/mods/DynamicTradingCommon/42.16/media/lua/shared/DT/Common/Logging/DT_LogProfile.lua"
DEFAULT_CONFIG_PATH = Path.home() / "Zomboid/Lua/DynamicTrading_Config.txt"
LUA_ROOTS = [
    WORKSPACE_ROOT / "Contents/mods/DynamicTradingCommon",
    WORKSPACE_ROOT / "Contents/mods/DynamicTradingV1",
    WORKSPACE_ROOT / "Contents/mods/DynamicTradingV2",
    WORKSHOP_ROOT / "DynamicColonies/Contents/mods/DynamicColonies",
    WORKSHOP_ROOT / "DynamicObjectives/Contents/mods/DynamicObjectives",
    WORKSHOP_ROOT / "CurrencyExpanded/Contents/mods/CurrencyExpanded",
    WORKSHOP_ROOT / "MarketSense/Contents/mods/MarketSense",
]
LOCAL_OVERRIDE_START = "        -- __DT_LOG_LOCAL_OVERRIDES_START__"
LOCAL_OVERRIDE_END = "        -- __DT_LOG_LOCAL_OVERRIDES_END__"
VALID_LEVELS = ("off", "info", "debug", "trace")
LEGACY_CONFIG_KEYS = {"debugLogs"}
VALID_PRESETS = (
    "quiet",
    "npc-dev",
    "trade-dev",
    "radio-dev",
    "colonies-dev",
    "objectives-dev",
    "currency-dev",
    "marketsense-dev",
    "all-debug",
)

LOG_CALL_RE = re.compile(
    r"DynamicTrading\.(?:Log|LogWarn|LogError|LogDebug|LogTrace)\(\s*\"([^\"]+)\"\s*,\s*\"([^\"]+)\"",
    re.MULTILINE,
)
LOG_LEVEL_CALL_RE = re.compile(
    r"DynamicTrading\.LogLevel\(\s*\"[^\"]+\"\s*,\s*\"([^\"]+)\"\s*,\s*\"([^\"]+)\"",
    re.MULTILINE,
)
ACTIVE_PRESET_RE = re.compile(r'ActivePreset = "([^"]+)"')
OVERRIDE_LINE_RE = re.compile(r'\["([^"]+)"\] = "([^"]+)"')
PRESET_NAME_RE = re.compile(r'^\s*(?:\["([^"]+)"\]|([A-Za-z0-9_]+))\s*=\s*\{', re.MULTILINE)
DT_LOG_RE = re.compile(r"^\[([^/\]]+)/([^/\]]+)/([^\]]+)\]\[([a-z]+)\]\s*(.*)$")
PZ_LOG_PREFIX_RE = re.compile(r"^(?:LOG|ERROR)\s*:\s*[A-Za-z]+\s+f:\d+>\s*")
RAW_PRINT_RE = re.compile(r"(?<![A-Za-z0-9_])print\(")
DO_LOG_RE = re.compile(r'DO\.Log\(\s*"([^"]+)"\s*,\s*"([^"]+)"', re.MULTILINE)
DO_LEVEL_RE = re.compile(r'DO\.LogLevel\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*,\s*"([^"]+)"', re.MULTILINE)
CE_LOG_RE = re.compile(r'CurrencyExpanded\.(?:Log|LogWarn|LogError|LogDebug|LogTrace)\(\s*"([^"]+)"\s*,\s*"([^"]+)"', re.MULTILINE)
CE_LEVEL_RE = re.compile(r'CurrencyExpanded\.LogLevel\(\s*"[^"]+"\s*,\s*"([^"]+)"\s*,\s*"([^"]+)"', re.MULTILINE)
MS_SHARED_LOG_RE = re.compile(r'Shared\.log\(\s*"([^"]+)"', re.MULTILINE)
MS_SAFE_LOG_RE = re.compile(r'safeLog\(\s*"([^"]+)', re.MULTILINE)


def read_profile_text() -> str:
    return PROFILE_PATH.read_text(encoding="utf-8")


def parse_profile(text: str) -> tuple[str, dict[str, str], list[str]]:
    active_match = ACTIVE_PRESET_RE.search(text)
    active_preset = active_match.group(1) if active_match else "quiet"

    start_index = text.find(LOCAL_OVERRIDE_START)
    end_index = text.find(LOCAL_OVERRIDE_END)
    if start_index == -1 or end_index == -1 or end_index < start_index:
        raise RuntimeError("Local override markers not found in DT_LogProfile.lua")

    override_block = text[start_index + len(LOCAL_OVERRIDE_START):end_index]
    overrides = dict(OVERRIDE_LINE_RE.findall(override_block))

    presets: list[str] = []
    for match in PRESET_NAME_RE.finditer(text):
        name = match.group(1) or match.group(2)
        if name in {"Presets", "Overrides", "LocalOverrides", "KnownSubsystems"}:
            continue
        presets.append(name)
    return active_preset, overrides, sorted(set(presets))


def write_profile(active_preset: str, overrides: dict[str, str]) -> None:
    text = read_profile_text()
    text, count = ACTIVE_PRESET_RE.subn(f'ActivePreset = "{active_preset}"', text, count=1)
    if count != 1:
        raise RuntimeError("Failed to update ActivePreset in DT_LogProfile.lua")

    start_index = text.find(LOCAL_OVERRIDE_START)
    end_index = text.find(LOCAL_OVERRIDE_END)
    if start_index == -1 or end_index == -1 or end_index < start_index:
        raise RuntimeError("Local override markers not found in DT_LogProfile.lua")

    lines = [LOCAL_OVERRIDE_START]
    for subsystem, level in sorted(overrides.items()):
        lines.append(f'        ["{subsystem}"] = "{level}",')
    lines.append(LOCAL_OVERRIDE_END)
    replacement = "\n".join(lines)
    text = text[:start_index] + replacement + text[end_index + len(LOCAL_OVERRIDE_END):]
    PROFILE_PATH.write_text(text, encoding="utf-8")


def normalize_log_level(level: str | None) -> str | None:
    if level is None:
        return None
    normalized = level.strip().lower()
    if normalized in VALID_LEVELS:
        return normalized
    return None


def normalize_subsystem_key(subsystem: str | None) -> str | None:
    if subsystem is None:
        return None
    normalized = subsystem.strip()
    return normalized or None


def parse_log_overrides(raw_value: str | None) -> dict[str, str]:
    overrides: dict[str, str] = {}
    raw = (raw_value or "").strip()
    if not raw:
        return overrides

    for entry in raw.split("|"):
        if ":" not in entry:
            continue
        subsystem, level = entry.split(":", 1)
        normalized_key = normalize_subsystem_key(subsystem)
        normalized_level = normalize_log_level(level)
        if normalized_key and normalized_level:
            overrides[normalized_key] = normalized_level
    return overrides


def serialize_log_overrides(overrides: dict[str, str]) -> str:
    parts: list[str] = []
    for subsystem in sorted(overrides):
        level = normalize_log_level(overrides[subsystem])
        normalized_key = normalize_subsystem_key(subsystem)
        if normalized_key and level:
            parts.append(f"{normalized_key}:{level}")
    return "|".join(parts)


def probe_config_paths() -> list[Path]:
    return [
        DEFAULT_CONFIG_PATH,
        WORKSPACE_ROOT / "DynamicTrading_Config.txt",
    ]


def resolve_config_path(explicit: str | None = None) -> Path:
    if explicit:
        return Path(explicit).expanduser()

    for candidate in probe_config_paths():
        if candidate.exists():
            return candidate
    return DEFAULT_CONFIG_PATH


def read_config_lines(config_path: Path) -> list[str]:
    if not config_path.exists():
        return []
    return config_path.read_text(encoding="utf-8", errors="ignore").splitlines()


def read_config_values(config_path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for line in read_config_lines(config_path):
        if "=" not in line or line.startswith("window_"):
            continue
        key, value = line.split("=", 1)
        values[key] = value
    return values


def write_config_values(config_path: Path, updates: dict[str, str]) -> None:
    lines = read_config_lines(config_path)
    remaining = dict(updates)
    output_lines: list[str] = []

    for line in lines:
        if "=" not in line:
            output_lines.append(line)
            continue

        key, _value = line.split("=", 1)
        if key in LEGACY_CONFIG_KEYS:
            continue
        if key in remaining and not key.startswith("window_"):
            output_lines.append(f"{key}={remaining.pop(key)}")
        else:
            output_lines.append(line)

    for key, value in remaining.items():
        output_lines.append(f"{key}={value}")

    config_path.parent.mkdir(parents=True, exist_ok=True)
    config_path.write_text("\r\n".join(output_lines) + ("\r\n" if output_lines else ""), encoding="utf-8")


def read_runtime_config(config_path: Path) -> tuple[str, dict[str, str]]:
    values = read_config_values(config_path)
    preset = values.get("logPreset", "").strip()
    overrides = parse_log_overrides(values.get("logOverrides", ""))
    return preset, overrides


def write_runtime_config(config_path: Path, preset: str, overrides: dict[str, str]) -> None:
    values = {
        "logPreset": preset.strip(),
        "logOverrides": serialize_log_overrides(overrides),
    }
    write_config_values(config_path, values)


def iter_lua_files() -> list[Path]:
    files: list[Path] = []
    for root in LUA_ROOTS:
        if root.exists():
            files.extend(sorted(root.rglob("*.lua")))
    return files


def format_path(path: Path) -> str:
    for root in (WORKSHOP_ROOT, WORKSPACE_ROOT):
        try:
            return path.relative_to(root).as_posix()
        except ValueError:
            continue
    return path.as_posix()


def discover_subsystems() -> Counter[str]:
    counts: Counter[str] = Counter()
    for file_path in iter_lua_files():
        if file_path == PROFILE_PATH:
            continue
        text = file_path.read_text(encoding="utf-8", errors="ignore")
        for version, system in LOG_CALL_RE.findall(text):
            counts[f"{version}/{system}"] += 1
        for version, system in LOG_LEVEL_CALL_RE.findall(text):
            counts[f"{version}/{system}"] += 1
        for category, topic in DO_LOG_RE.findall(text):
            counts[f"DTObjectives/{category}"] += 1
        for _level, category, _topic in DO_LEVEL_RE.findall(text):
            counts[f"DTObjectives/{category}"] += 1
        for module, category in CE_LOG_RE.findall(text):
            counts[f"{module}/{category}"] += 1
        for module, category in CE_LEVEL_RE.findall(text):
            counts[f"{module}/{category}"] += 1
        if "MarketSense/ItemsRegistry" in format_path(file_path) or file_path.name.startswith("MS_ItemsRegistry_"):
            for _level in MS_SHARED_LOG_RE.findall(text):
                counts["MarketSense/Registry"] += 1
        if file_path.name == "MS_Debug.lua":
            for _message in MS_SAFE_LOG_RE.findall(text):
                counts["MarketSense/DebugTools"] += 1
    return counts


def discover_raw_print_hotspots() -> Counter[str]:
    hotspots: Counter[str] = Counter()
    for file_path in iter_lua_files():
        relative = format_path(file_path)
        for line in file_path.read_text(encoding="utf-8", errors="ignore").splitlines():
            stripped = line.strip()
            if stripped.startswith("--"):
                continue
            if RAW_PRINT_RE.search(stripped) and "DT_Logger.lua" not in relative:
                hotspots[relative] += 1
    return hotspots


def normalize_console_message(message: str) -> str:
    normalized = re.sub(r"\b[0-9a-fA-F]{8,}\b", "<id>", message)
    normalized = re.sub(r"\b\d+(?:\.\d+)?\b", "<n>", normalized)
    normalized = re.sub(r"\s+", " ", normalized).strip()
    return normalized


def parse_console_line(line: str) -> tuple[str, str, str, str, str] | None:
    stripped = line.rstrip("\n")
    stripped = PZ_LOG_PREFIX_RE.sub("", stripped)
    match = DT_LOG_RE.match(stripped)
    if match:
        version, system, specific, level, message = match.groups()
        return version, system, specific, level, message

    legacy_patterns = (
        (r"^\[DT TradePerf\]\[([^\]]+)\]\s*(.*)$", ("DTCommons", "TradePerf", "{0}", "trace")),
        (r"^\[DynamicTrading\.Text\]\s*Missing translation key:\s*(.*)$", ("DTCommons", "Text", "Missing", "warn")),
        (r"^\[DynamicObjectives\.Text\]\s*Missing translation key:\s*(.*)$", ("DTObjectives", "Text", "Missing", "warn")),
        (r"^\[CurrencyExpanded\.Text\]\s*Missing translation key:\s*(.*)$", ("CECommons", "Text", "Missing", "warn")),
        (r"^\[DynamicColonies\.Text\]\s*Missing translation key:\s*(.*)$", ("DynamicColonies", "Text", "Missing", "warn")),
        (r"^\[DynamicTradingV2\]\s*Ignoring unsupported attachment slot:\s*(.*)$", ("DTV2", "NPC", "EquipmentVisuals", "warn")),
        (r"^\[DynamicTrading\]\s*Dynamic Colonies network unavailable:\s*(.*)$", ("DTCommons", "Init", "Network", "warn")),
        (r"^\[MarketSense\]\s*ERROR:\s*(.*)$", ("MarketSense", "Init", "RegistryHook", "error")),
        (r"^\[MarketSense\]\s*Loaded\s*(.*)$", ("MarketSense", "Init", "RegistryHook", "info")),
        (r"^DT_TracerSystem:\s*(.*)$", ("DTCommons", "TracerSystem", "Init", "trace")),
        (r"^DT_LightSystem:\s*(.*)$", ("DTCommons", "LightSystem", "Init", "trace")),
        (r"^\[DTV2 Companion UI\]\s*(.*)$", ("DTV2", "NPC", "CompanionUI", "debug")),
        (r"^\[DTV2 Loot Debug\]\s*(.*)$", ("DTV2", "NPC", "LootDebug", "debug")),
        (r"^\[DTNPC Protect\]\s*(.*)$", ("DTV2", "NPC", "Protect", "debug")),
    )

    for pattern, values in legacy_patterns:
        legacy_match = re.match(pattern, stripped)
        if not legacy_match:
            continue

        groups = legacy_match.groups()
        version, system, specific, level = values
        if "{0}" in specific:
            specific = specific.format(groups[0] if groups else "")
            message = groups[1] if len(groups) > 1 else ""
        else:
            message = groups[0] if groups else ""
        return version, system, specific, level, message

    return None


def probe_console_paths() -> list[Path]:
    home = Path.home()
    return [
        WORKSPACE_ROOT / "console.txt",
        home / "Zomboid/console.txt",
        home / "Zomboid/Logs/console.txt",
        home / "Zomboid/console/console.txt",
    ]


def resolve_console_path(explicit: str | None) -> Path:
    if explicit:
        path = Path(explicit).expanduser()
        if not path.exists():
            raise FileNotFoundError(f"console file not found: {path}")
        return path

    for candidate in probe_console_paths():
        if candidate.exists():
            return candidate
    raise FileNotFoundError("console.txt not found automatically; pass --console-path")


def command_list_subsystems(_: argparse.Namespace) -> int:
    active_preset, overrides, presets = parse_profile(read_profile_text())
    config_path = resolve_config_path()
    runtime_preset, runtime_overrides = read_runtime_config(config_path)
    subsystem_counts = discover_subsystems()
    hotspots = discover_raw_print_hotspots()

    print(f"Profile: {format_path(PROFILE_PATH)}")
    print(f"Shared preset: {active_preset}")
    print(f"Known presets: {', '.join(presets)}")
    print(f"Runtime config: {config_path}")
    print(f"UI preset: {runtime_preset or '(follow shared)'}")
    if runtime_overrides:
        print("UI overrides:")
        for subsystem, level in sorted(runtime_overrides.items()):
            print(f"  {subsystem} = {level}")
    else:
        print("UI overrides: none")

    if overrides:
        print("Shared local overrides:")
        for subsystem, level in sorted(overrides.items()):
            print(f"  {subsystem} = {level}")
    else:
        print("Shared local overrides: none")

    print("")
    print("Discovered subsystems:")
    for subsystem, count in subsystem_counts.most_common():
        print(f"  {subsystem:<24} {count}")

    print("")
    print("Raw print hotspots:")
    if hotspots:
        for path, count in hotspots.most_common():
            print(f"  {path:<90} {count}")
    else:
        print("  none")
    return 0


def command_set_level(args: argparse.Namespace) -> int:
    level = args.level.lower()
    if level not in VALID_LEVELS:
        raise SystemExit(f"invalid level: {args.level}")

    config_path = resolve_config_path(args.config_path)
    preset, overrides = read_runtime_config(config_path)
    overrides[args.subsystem] = level
    write_runtime_config(config_path, preset, overrides)
    print(f"Set {args.subsystem} = {level} in {config_path}")
    return 0


def command_preset(args: argparse.Namespace) -> int:
    preset = args.name.lower()
    if preset not in VALID_PRESETS:
        raise SystemExit(f"invalid preset: {args.name}")

    config_path = resolve_config_path(args.config_path)
    _current_preset, _overrides = read_runtime_config(config_path)
    write_runtime_config(config_path, preset, {})
    print(f"Applied UI preset {preset} and cleared UI overrides in {config_path}")
    return 0


def command_trace_console(args: argparse.Namespace) -> int:
    console_path = resolve_console_path(args.console_path)
    raw_lines = console_path.read_text(encoding="utf-8", errors="ignore").splitlines()
    selected_lines = raw_lines[-args.lines:] if args.lines > 0 else raw_lines

    grouped: dict[tuple[str, str, str], dict[str, object]] = {}
    warn_error_lines: list[str] = []
    total_matches = 0

    for line in selected_lines:
        parsed = parse_console_line(line)
        if not parsed:
            continue

        version, system, specific, level, message = parsed
        subsystem = f"{version}/{system}"
        total_matches += 1

        if level in {"warn", "error"}:
            warn_error_lines.append(line)

        normalized = normalize_console_message(message)
        key = (subsystem, level, normalized)
        if key not in grouped:
            grouped[key] = {
                "count": 0,
                "specific": specific,
                "last_message": message,
            }
        grouped[key]["count"] = int(grouped[key]["count"]) + 1
        grouped[key]["specific"] = specific
        grouped[key]["last_message"] = message

    print(f"Console: {console_path}")
    print(f"Scanned lines: {len(selected_lines)}")
    print(f"DynamicTrading matches: {total_matches}")
    print("")
    print("Grouped summary:")
    sorted_groups = sorted(
        grouped.items(),
        key=lambda item: (-int(item[1]["count"]), item[0][0], item[0][1], item[0][2]),
    )
    if not sorted_groups:
        print("  no DynamicTrading log lines found")
    else:
        for (subsystem, level, _normalized), data in sorted_groups[: args.max_groups]:
            print(f"  [{subsystem}][{level}] x{data['count']} :: {data['last_message']}")

    print("")
    print("Warn/Error lines:")
    if warn_error_lines:
        for line in warn_error_lines[-args.max_warn_error:]:
            print(f"  {line}")
    else:
        print("  none")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Control DynamicTrading logging options and summarize console output.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    list_parser = subparsers.add_parser("list-subsystems", help="List discovered logger subsystems and raw print hotspots.")
    list_parser.set_defaults(func=command_list_subsystems)

    preset_parser = subparsers.add_parser("preset", help="Apply a runtime UI preset and clear runtime overrides.")
    preset_parser.add_argument("name", choices=VALID_PRESETS)
    preset_parser.add_argument("--config-path", help="Explicit path to DynamicTrading_Config.txt")
    preset_parser.set_defaults(func=command_preset)

    set_level_parser = subparsers.add_parser("set-level", help="Set a runtime subsystem override.")
    set_level_parser.add_argument("--subsystem", required=True, help="Subsystem key like DTV2/NPC")
    set_level_parser.add_argument("--level", required=True, choices=VALID_LEVELS)
    set_level_parser.add_argument("--config-path", help="Explicit path to DynamicTrading_Config.txt")
    set_level_parser.set_defaults(func=command_set_level)

    trace_parser = subparsers.add_parser("trace-console", help="Summarize DynamicTrading lines from console.txt.")
    trace_parser.add_argument("--console-path", help="Explicit path to console.txt")
    trace_parser.add_argument("--lines", type=int, default=2000, help="Number of trailing lines to inspect")
    trace_parser.add_argument("--max-groups", type=int, default=40, help="Maximum grouped summaries to print")
    trace_parser.add_argument("--max-warn-error", type=int, default=40, help="Maximum warn/error lines to print")
    trace_parser.set_defaults(func=command_trace_console)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return int(args.func(args))


if __name__ == "__main__":
    sys.exit(main())
