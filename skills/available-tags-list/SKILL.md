---
name: available-tags-list
description: Lists every available archetype-editor tag and its coverage metadata by reusing the existing backend tag catalog. Use when asked to enumerate tags, inspect uncovered tags, or understand archetype tag coverage.
---

# Available Tags List

This skill lists the full tag catalog already generated for the Dynamic Trading archetype editor, including coverage counts and uncovered tags.

## When to use this skill

- When the user asks for all available tags.
- When the user asks which tags exist but are not reachable by any archetype.
- When you need tag coverage counts, sample items, or archetype coverage for a tag.
- When you need the same tag catalog the archetype editor uses for autocomplete and the tag tree.

## How to use it

### 1. Reuse the archetype editor data pipeline

Use the existing backend logic in `DynamicTradingManager/backend/Simulation/archetype_editor.py`.

- `load_archetype_editor_data()` returns `available_tags`, `uncovered_tags`, and `item_catalog`.
- `_collect_all_tags()` builds the tag universe from parsed item tags and archetype allocation tags.
- Parent tag families are intentionally included, so a leaf tag like `Food.Canned.Vegetable` also contributes `Food` and `Food.Canned`.

Do not hand-maintain a separate tag list.

### 2. Preferred extraction path

For a full tag listing, query the backend function directly:

```bash
cd DynamicTradingManager/backend
python3 - <<'PY'
from Simulation.archetype_editor import load_archetype_editor_data

data = load_archetype_editor_data()

print(f"tag_count={len(data['available_tags'])}")
for row in data["available_tags"]:
    print(
        f"{row['tag']} | items={row['item_count']} | covered_items={row['covered_item_count']} | covered_by={row['covered_by_count']}"
    )
PY
```

If the user specifically wants only the missing coverage set, use `data["uncovered_tags"]` instead.

### 3. Important fields in the tag catalog

Each `available_tags` row already contains:

- `tag`
- `item_count`
- `covered_item_count`
- `covered_by_count`
- `covered_by`
- `sample_items`

Use these fields instead of recomputing coverage yourself unless you are debugging the backend implementation.

### 4. Reporting rules

Unless the user asks for a custom format, return:

1. Total available tag count.
2. One line per tag with item count and coverage counts.
3. If relevant, a separate uncovered section from `uncovered_tags`.

If the user wants a shorter answer, prefer one of these subsets:

- All tag names only.
- Only uncovered tags.
- Only tags matching a root such as `Food`, `Weapon`, or `Resource`.

### 5. Match the current manager behavior

- The left-side tag tree and autocomplete are built from `available_tags`.
- The `Tags Not Currently Accessible` panel uses `uncovered_tags`, which is only the uncovered subset, not the full catalog.
- The archetype summary chips use `meta.tag_count` and `meta.uncovered_tag_count` from the same payload.

When the user asks for "all available tags", always start from `available_tags`, not from the uncovered-only panel.