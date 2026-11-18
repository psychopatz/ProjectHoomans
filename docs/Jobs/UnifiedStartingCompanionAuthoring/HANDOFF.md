---
handoff_schema: 2
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
updated_at: "2026-11-18T15:14:33.615790Z"
state: "USER_ACCEPTANCE"
parent_status: "IN_PROGRESS"
phase: "P5R8"
chunk: "P6 native tone, named save/library and per-world death retest"
retrieval_tier: "verify"
codebase_memory_indexed_commit: "a380736978309d72a20596e087a86fa866ecd016"
checkpoint_mode: "committed_handoff"
phase_commit: "self"
phase_commit_phase: "P5R8"
phase_commit_message: "phase(P5R8): repair skin editing and add named reusable NPC encounter saves"
phase_commit_vector: "project-hoomans=self;psychopatz-core=fba98ab4791bde95a12fb1fcb7fbeede88408d7a;dynamic-trading=0fcf35196452db0675788167df205aec09748caa"
phase_residual_vector: "project-hoomans=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;psychopatz-core=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f;dynamic-trading=a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
residual_worktree_fingerprint: "a709d4c2b505952658c06044726110ba4ccebe001b7c233ca939f42d1c555d4f"
---


# Session Handoff

P5R8 developer repair is verified. Skin selection no longer restores random
factory RGB or retains old RGB after canonical rebind; Core portraits use the
native tone index/neutral tint unless custom/inherited RGB is explicit. Native
outfit captures reconcile exclusivity and stale preview garments cannot poison
pending candidates. Read-only gender icons retain contrast and selected state.

Both hosts offer editable filenames defaulted to NPC name. Companion presets
remain sparse; optional exact independent encounter export uses the same NPC
file codec/storage as Unique NPC production. Authority discovery loads produced
files into the normal one-time pool. User chose death permanent within each
world, with templates reusable elsewhere. Reload/update never clears dead world
state. Encounter exports carry no player relationship grant.

MP clients cannot auto-register local files. Publication requires admin on the
UI and server mutation boundary; accepted requests persist a server copy. A
server also reads its own administrator-controlled local files. This phase owns
only the generic portrait tint/index adjustment and regression in Core; all
product library/permission policy remains in Hoomans.

`TEST_VERIFIED`: **62/62** focused Hoomans; **1055/1059** full, same four known
scene-route/context/population/translation failures. Core portrait smoke passes.
`STATIC_ONLY`: Hoomans 24 Lua syntax/17 production Kahlua, Core two syntax/one
Kahlua, six new EN/TL Character keys, JSON/parity/references/whitespace pass.
Graph coverage checked; stale/new source read directly. Installed Java/native
Lua supplied API contracts. No native rendering/input/audio/MP success is claimed.

Next: user-owned fresh-session matrix in PERSISTENCE_AND_SKIN_RETEST.md, then
previous voice/browser/SP/MP/co-op gates. No game launch/control, push or Workshop
publication. Preserve unrelated concurrent semantic/test work. Participant Core
commit must precede the exact owned primary commit/checkpoint.
