---
handoff_schema: 2
checkpoint_mode: "committed_handoff"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
phase: "Explicit Conversation authoring records"
chunk: "migration and writer-boundary verification complete"
retrieval_tier: "COMPLETE"
parent_status: "COMPLETE"
phase_commit: "self"
phase_commit_phase: "Explicit Conversation authoring records"
phase_commit_message: "refactor: adopt canonical conversation content keys"
phase_commit_vector: "project-hoomans=self;psychopatz-core=12590d64;dynamic-trading=c8a013b7"
phase_residual_vector: "project-hoomans=5e9b37edbc784733cce00b52a38ee9b9c5d770b2;psychopatz-core=12590d64fb3814573f75e111e895575fdb8b9d8d;dynamic-trading=c8a013b7c215ef4573fb9e5a44fe842872ce3f04"
updated_at: "2026-11-12T00:00:00+08:00"
state: "CLEAN_CHECKPOINT"
---



# Unified Semantic Catalog Handoff

## Current state

Core now owns explicit stable Conversation phrase records and the canonical
one-file-per-locale authoring catalogs. The content compiler is schema v3 and
the generated PNC/DT artifacts use canonical `conversation.content.*` keys.
The writer boundary updates EN/TL catalogs without reintroducing locale maps
into source shards.

PNC runtime consumers use `PNC_ConversationTextCatalog` and generated
`common/media/translation/<LANG>/Conversation/Bundles/` paths. The old PNC
conversation tree and both DT source trees are removed from the working
trees. No non-document source references remain for `media/conversation`,
`ConversationTextLoader`, or `TextLoader`.

## Verification

- Core semantic-harness unittest suite: 90/90 in the current checkout.
- PNC content, translation, authority, pragmatic-edit, and flow suites pass.
- PNC Lua conversation, local-route, and identity smoke tests pass.
- DT core, shared-parity, DTHoomans bridge, and DTAbstract bridge smokes: 5/5.
- Harness `--ping --no-gui` passes for `pnc`, `pnc-with-dthoomans`, and
  `dtabstract`.
- `pz-verify` reports no i18n, Kahlua, or bloat errors in the changed runtime.
- Source audit: 6,912 explicit phrase records, zero inline locale fields,
  7,524 EN entries, and 7,524 TL entries.
- One observatory matrix suite is not green because Tkinter aborts during
  cross-thread teardown (`Tcl_AsyncDelete`); no migration assertion failed.

## Completion

- Core explicit-record commit: `12590d64`.
- Dynamic Trading registry refresh: `c8a013b7`.
- Project Hoomans canonical-key commit: `5e9b37ed`.
- Earlier migration and bundle-cleanup commits remain in the history above.

## Safety

Do not restore deleted conversation trees or add migration shims. The residual
dirty files are unrelated pre-existing audit/report work and remain unstaged.
Do not launch Project Zomboid or publish Workshop content unless the user
explicitly assigns that live validation.
