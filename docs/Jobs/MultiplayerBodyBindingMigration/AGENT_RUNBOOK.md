# Agent Runbook — Multiplayer Body Binding Migration

## Read order

Read root AGENTS.md, then:
1. this job README.md;
2. AUDIT.md;
3. ARCHITECTURE.md;
4. ROADMAP.md;
5. HARNESS_ACCEPTANCE.md;
6. PROGRESS.md last.

Use current code/tests/runtime evidence as source of truth over historical agent prose.

## Parent objective

Implement the complete M0-M12 Multiplayer Body Binding Migration.

The parent objective is the completion boundary. A phase/chunk passing does not finish the job.

After each accepted chunk:
1. update PROGRESS.md;
2. select the next mandatory documented chunk;
3. continue automatically.

Do not ask for another /goal merely because one phase passes.

## First principle

Do not assume a server-side IsoZombie and a multiplayer client IsoZombie are the same Java object or share authoritative PNC ModData. Also do not assume an IsoZombie created through vanilla population factories is a disposable carrier: installed 42.22 engine inspection proves `createRealZombieAlways()` registers it with `ZombiePopulationManager`.

For MP:

    durable NPC identity != vanilla zombie transport identity

The explicit relation is npcId + body incarnation/lease <-> onlineId.

## Single-player protection

M0 must restore/freeze SP before broad MP migration.

Do not make SP depend on:
- network online ID arrival;
- client pending bindings;
- MP roster timing;
- remote-zombie authority;
- client reconciliation.

MP fixes belong behind the MP binding/provider seam.

## Project A-Life reference policy

Read-only reference path:

/home/psychopatz/.steam/debian-installation/steamapps/workshop/content/108600/3803984183/mods/ProjectALifeNPCs

Useful files are listed in AUDIT.md.

You may compare architecture and independently reproduce guarantees.

Never:
- edit the Workshop mod;
- make Project Hoomans depend on it;
- copy implementation verbatim;
- assume its behavior is correct without verifying against installed PZ/runtime and Hoomans requirements.

## Java engine ground truth

Use local Zomboid development skills, especially:
- pz-java-harness;
- pz-kahlua-lint / pz-verify as appropriate;
- architecture-audit;
- pz-console-log when analyzing user runtime logs.

For engine-network claims, verify installed 42.22 runtime rather than relying on memory.

## Preserve existing authorities

Do not replace:
- Registry;
- Presence;
- BodyLifecycle;
- NetworkSnapshots/network budgets;
- ClientPresenceSync;
- health/wounds/death/reanimation authority;
- combat authority;
- movement/pathing authority;
- companion ownership;
- semantic/dialogue systems.

Keep the existing body-binding seam as the canonical MP identity layer. M9 changes only the physical-carrier lifecycle beneath it. Installed engine/native proof selected the supported equivalent path: managed live-human carriers keep vanilla real/network admission but must be proactively retired while attached, before native `n_addZombie` virtualization can run.

## Identity safety

Never reclaim/identify an NPC from:
- proximity alone;
- persistent outfit ID alone;
- appearance alone;
- username alone;
- one stale online ID alone.

Stale incarnation/generation must fail closed.

An ordinary zombie must never be deleted because it merely occupies an old NPC position.

## Persistence

Routine client binding cache is transient.

Persist only durable NPC/body lifecycle state already owned by Registry/BodyLifecycle. Do not persist client pending messages, observed replica tables or presentation caches.

## Performance

No per-frame full-zombie census.

Prefer:
- exact online-ID indexing;
- PZ zombie observation events;
- existing presence snapshots;
- bounded pending queues;
- TTL sweeps with explicit cadence/cap;
- existing server interest routing.

Do not solve the race with global scans.

## Validation cadence

After each coherent chunk:
- focused Lua smoke tests;
- relevant SP presence/body/restart tests;
- relevant MP replica/network/husk tests;
- death/reanimation tests when touched;
- installed-PZ Kahlua verification for changed runtime Lua;
- git diff --check;
- update PROGRESS.md;
- continue automatically.

Before final M12:
- full isolated Lua suite;
- focused M0-M12 matrix;
- static performance/persistence audit;
- changed-file Kahlua verification;
- clean diff/status except intended committed work.

Do not launch native Project Zomboid unless explicitly assigned.

## Native contradiction rule

Native SP/MP evidence outranks synthetic acceptance. The 2026-10-30 native test reproduced persistent old NPC husks in both SP and MP after M0-M8. Therefore:
- M0-M8 remain useful historical implementation evidence, not final completion;
- reopen the smallest owning lifecycle layer rather than weakening identity safeguards;
- do not add another position/outfit/gender-based husk heuristic;
- do not mark developer completion again until M9 proves managed live-human shells are retired before native `n_addZombie` virtualization during their live-human lifetime;
- preserve genuine Knox reanimation as a transition into a real vanilla zombie lifecycle.

## Git/runtime

Existing main only.

Check branch/HEAD/status before edits and commits. Preserve unrelated user/agent changes. Never reset/rebase/stash/discard uncertain work.

Do not publish/republish Workshop content without explicit authorization.

## Stop conditions

Stop only for:
- complete M0-M12 developer acceptance and user-owned native MP restart/presentation handoff;
- genuine unsafe concurrent-work conflict;
- required engine/tool capability unavailable with no accepted fallback;
- architecture/scope conflict requiring user choice;
- final user-owned native acceptance after all developer-implementable work is complete.

A failed intermediate design is not a reason to stop: record evidence, revise the smallest owning phase, and continue.
