---
handoff_schema: 2
checkpoint_mode: "dirty_snapshot"
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
state: "DIRTY_RESUMABLE"
parent_status: "IN_PROGRESS"
phase: "G8"
chunk: "G8A — compact authoring schema + formal compiler boundary"
retrieval_tier: "auditor"
---

# Session Handoff

## Resume truth

Close G7R before extracting the portable backend/toolchain.

Verified future-direction evidence:
- canonical IR is already actor-neutral;
- beats/behaviors are largely declarative;
- camp already demonstrates typed capability separation;
- profanity still contains recreatable handwritten recognition/policy logic;
- fuzzy matching belongs in standard runtime semantics.

Compactness audit:
- 571 semantic source files, ~1.4 MB;
- every file repeats schema/kind/owner;
- 558 repeat namespace;
- 371/372 participant declarations are identical.

G8A should therefore introduce compact authoring source that expands into the explicit current IR, not weaken the IR.

## Exact next action

Complete G7R1, then G7R2–G7R3. After the clean committed checkpoint, begin G8A.

## Safety

Preserve unrelated concurrent work. Do not reset/stash/discard, broad-stage, create a branch, or publish.
