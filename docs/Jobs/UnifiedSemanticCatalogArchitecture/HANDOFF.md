---
handoff_schema: 2
checkpoint_mode: "working_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase: "P4 — runtime migration and legacy removal"
chunk: "P4 commit and P5 composition-matrix acceptance"
retrieval_tier: "verify"
parent_status: "IN_PROGRESS"
---

# Unified Semantic Catalog Handoff

## Current state

Core now contains the legacy bundle migration boundary and the normalized
46-bundle manifest. The Core EN/TL catalogs contain the migrated PNC and DT
legacy wording. A real build generated 88 PNC and 4 DT legacy runtime JSON
files with exact locale parity.

PNC runtime consumers use `PNC_ConversationTextCatalog` and generated
`common/media/translation/<LANG>/Conversation/Legacy/` paths. The old PNC
conversation tree and both DT legacy source trees are removed from the
working trees. No non-document source references remain for
`media/conversation`, `ConversationTextLoader`, or `TextLoader`.

## Verification

- Core semantic-harness unittest suite: 92/92.
- PNC focused conversation smoke suite: 4/4.
- DT core, shared-parity, DTHoomans bridge, and DTAbstract bridge smokes: 4/4.
- `pz-verify`: 3,316 Lua files scanned; zero i18n, Kahlua, and bloat findings.
- JSON parity: 88 PNC source locale files and 4 DT source locale files.

## Next chunk

1. Commit exact phase-owned files in dependency order: Core, Dynamic Trading,
   then Project Hoomans; preserve unrelated dirty work.
2. Run the harness composition matrix against real repository-backed inputs:
   Core dependency closure, PNC-only, PNC + Dynamic Trading, DTAbstract,
   DTHoomans, and an optional expansion pack.
3. Verify the GUI startup path and the active-mod/save resolution path before
   accepting P5 and closing the goal.

## Safety

Do not restore the deleted conversation trees or add compatibility shims.
Do not stage the pre-existing architecture reports, unrelated audit scripts,
or unrelated test changes. Do not launch Project Zomboid or publish Workshop
content unless the user explicitly assigns that live validation.
