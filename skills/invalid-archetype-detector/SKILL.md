---
name: invalid-archetype-detector
description: Lists Dynamic Trading archetypes with validation findings by reusing the existing archetype editor pipeline. Use when asked to find invalid archetypes, unknown tags, unknown Lua variables, or broken allocation rows.
---

# Invalid Archetype Detector

This skill reproduces the same invalid-archetype findings shown by the Dynamic Trading Manager's Invalid Archetype Detector without inventing a second parser.

## When to use this skill

- When the user asks which archetypes are invalid.
- When the user asks for archetypes with unknown tags, unknown item IDs, missing fields, or invalid allocation rows.
- When you need the same findings the manager UI shows in the Invalid Archetype Detector panel.

## How to use it

### 1. Use the existing source of truth

Always reuse the backend archetype editor pipeline in `DynamicTradingManager/backend/Simulation/archetype_editor.py`.

- `load_archetype_editor_data()` builds the full editor payload.
- `_validate_archetype_block()` produces the validation findings for each archetype.
- The manager API exposes the same payload at `/api/archetypes/editor` through `DynamicTradingManager/backend/main.py`.

Do not build a separate regex scanner unless the existing pipeline is broken.

### 2. Preferred extraction path

If you only need a report, call the backend function directly from the workspace:

```bash
cd DynamicTradingManager/backend
python3 - <<'PY'
from Simulation.archetype_editor import load_archetype_editor_data

data = load_archetype_editor_data()
rows = [row for row in data["archetypes"] if row["validation"]["issue_count"] > 0]

print(f"invalid_archetype_count={len(rows)}")
for row in rows:
    validation = row["validation"]
    print(f"\n{row['archetype_id']} | {row['name']} | errors={validation['error_count']} warnings={validation['warning_count']}")
    for issue in validation["issues"]:
        field = issue.get("field") or "-"
        value = issue.get("value") or "-"
        print(f"  [{issue['level']}] {issue['code']} | field={field} | value={value} | {issue['message']}")
PY
```

If the backend server is already running, you can query the same data from `/api/archetypes/editor` instead.

### 3. What counts as an invalid archetype

Treat an archetype as invalid whenever `row["validation"]["issue_count"] > 0`.

Common issue types already produced by `_validate_archetype_block()` include:

- `unknown_field`
- `missing_field`
- `unknown_tag`
- `unknown_allocation_field`
- `allocation_missing_source`
- `allocation_conflict`
- `allocation_missing_count`
- `allocation_invalid_count`
- `allocation_empty_tags`
- `unknown_item`

Preserve the backend severity split between `error` and `warning` when reporting findings.

### 4. Report format

Unless the user asks for a different format, return:

1. Total invalid archetype count.
2. One line per archetype with ID, display name, error count, and warning count.
3. The issue messages under each archetype.

If the user only wants a compact list, return just the archetype IDs and names.

### 5. Correction workflow

- For `unknown_tag` findings, prefer checking the generated `available_tags` catalog from the same payload before suggesting replacements.
- For `unknown_item`, verify against the parsed item catalog included in the editor payload.
- Do not manually edit generated registries just to work around bad validation output; fix the underlying archetype definition or parser logic.