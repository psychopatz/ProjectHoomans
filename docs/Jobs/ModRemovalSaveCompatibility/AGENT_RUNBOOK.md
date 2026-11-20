# Agent Runbook — Mod Removal & Save Compatibility

## Startup and ownership

1. Inspect the current workspace; read ProjectHoomans root AGENTS.md, then job PROGRESS.md and HANDOFF.md; read only needed ROADMAP/AUDIT sections.
2. Confirm branch main, HEAD, upstream, all worktrees and every staged/dirty/untracked path. Do not override unrelated agent edits.
3. Inspect participant repos and their root instructions only when evidence implicates them. Primary repository is the documentation owner, not the only possible implementation owner.
4. Run every workspace write/test operation under the actual owner identity (psychopatz on the referenced Linux machine), NOT root. Explicitly check ownership before and after; do not create root-owned files. Never change mod file ownership as a workaround.
5. Use Codebase Memory if available for targeted function/caller discovery, then verify exact current source; never treat indexing or old GitHub snapshots as live source truth.

## Safe reference-save handling

- Reference is ~/Zomboid/Saves/Apocalypse/2026-11-20_07-12-33. The other two same-day Apocalypse saves are not substitutes.
- Read original files only. If using SQLite, use explicit read-only mode and avoid journal creation or PRAGMA operations that alter the database. Do not edit, vacuum, patch or delete original players.db, player BLOBs, mods.txt, global_mod_data.bin, media or any save files.
- Before any experimental load, create a complete verified disposable copy outside the save folder and document its checksum/baseline and exact purpose. Ensure experimental gameplay never accidentally writes to original.
- No backup in Git, no raw user save data in docs, no personally identifying character records or opaque player BLOBs in commits.
- Never infer player Strength, capacity or debug flags from arbitrary binary offsets. Prefer supported PZ API introspection against a controlled copy or exact upstream serializer semantics.
- Inspect a save with empty mod list both as a data snapshot and a runtime condition; the former does not prove the latter. Do not assume PNC-related global data is corrupt.

## Investigation checklist

- Observe reported numerator/denominator, real encumbrance threshold, Strength, relevant traits, equipment, moodles and debug/god/unlimited-carry flags.
- Resolve active player record among localPlayers ids 1 and 2 and confirm no accidental record switch or invalid load order.
- Search and trace direct setters, indirect engine hooks, item script overrides, player ModData and global ModData, serialize/hydrate order and any optional core/trading adapters.
- Compare with matched-attribute vanilla controls and PNC-enabled controls; vary one factor at a time and record sample lineage.
- Report competing hypotheses and discriminating tests; don't translate correlation or a raw string into a causal explanation.

## Implementation and validation

- Prefer a small owner-correct fix and reusable existing lifecycle/harness tests. No blanket player-stat resets, no parallel inventory authority, no compatibility shim accumulation.
- If external repair is warranted, require explicit opt-in and a reversible snapshot; show exact proposed fields and validation rules before executing on copies.
- Native PZ gameplay is user-owned unless expressly requested; do not launch or modify running game simply to claim a passing gate.
- Verify tests with exact commands, versions and PASS/FAIL outcomes; preserve baseline failures as distinct evidence. Keep important MP authority and no-extra-tick constraints.

## Git and phase closure

- Docs and production changes must remain in their proven owner repositories and correct runtime/package directories; never invent a new root-level media/common/translation tree.
- On accepted phase gate, update progress/handoff and commit only exact phase-owned paths locally. Preserve unrelated index and worktree changes.
- No new branches, pushes, PRs, Workshop publication, forced Git operations, or broad staging without authorization.
- Stop only at full developer-side completion, a genuine external/authorization blocker, or the final user-owned native acceptance gate.
