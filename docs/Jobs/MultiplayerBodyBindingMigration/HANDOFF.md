---
handoff_schema: 1
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
head: "9572b548f19b6229a7c5e7887047baa9cc783993"
worktree_fingerprint: "2df2e4506ef67cb2e23e85b75ad91699f068d4c488acd8a0fc7b482b736a318a"
codebase_memory_indexed_commit: "9572b548f19b6229a7c5e7887047baa9cc783993"
state: "USER_ACCEPTANCE"
parent_status: "DEVELOPER_ACCEPTED"
phase: "M12 developer repairs complete"
chunk: "hosted/dedicated MP human-presentation acceptance"
retrieval_tier: "verify"
---

# Session Handoff

## What became true

- M12 human-presentation authority and restart-proof durability repairs are recorded implemented and developer-validated.
- Current progress records 978/978 full, 189/189 focused, 7/7 installed-PZ compile, static Kahlua clean.

## Remaining

- Renewed native hosted/dedicated multiplayer acceptance is mandatory.
- Bound NPCs must remain human-looking after initial spawn and after native zombie replication/restart behavior.

## Resume

1. Verify checkpoint, then read `PROGRESS.md` and its remaining mandatory action.
2. Run hosted/dedicated MP acceptance with the existing save/restart matrix.
3. If it fails, capture exact identity/lease/presentation evidence and use Codebase Memory Verify tier before reopening M12 ownership.

## Evidence

- `TEST_VERIFIED` recorded: 978/978 full; 189/189 focused; 7/7 installed-PZ compile.
- `UNVERIFIED`: renewed native hosted/dedicated MP acceptance.

## Expensive discoveries worth preserving

- Live detach must persist `wasLive=true`; corpse detach must not inherit live restart admission. Weak anonymous historical hints remain rejected.

## Blockers / open decisions

No developer blocker.

## Acceptance

Hosted/dedicated MP NPCs retain correct human skin/hair/outfit and restart binding behavior without zombie-looking regression; failures reopen only the implicated M12 boundary.

> Replace this file on the next handoff. Do not append a chronological diary.
