# Developer acceptance — Multiplayer Body Binding Migration

Developer implementation accepted on existing `main`, 2026-10-30. Native SP/MP acceptance remains user-owned and unexecuted. Planning baseline: `e3614241`.

## Implemented ownership

Registry owns durable NPC identity; Presence owns live/abstract decisions; BodyLifecycle owns physical shells, leases, corpse conversion and reanimation. `PNC_MultiplayerBodyBinding` is the sole MP binding seam, with shared/server projection, client reconciler and one ClientPresenceSync adapter.

The physical incarnation is `runtime.bodyLease`. MP stamping issues a fresh lease for a new/recycled/restored shell, with weak process-local receipts preserving repeated stamping of the current shell. Core provider ownership cannot overwrite the MP physical lease. SP retains local constructor/stamping and provider semantics without network reconciliation.

Server descriptors carry protocol, server session, publication revision, npcId, incarnation and onlineId. Publication revision orders messages and renews bounded proof; it is not another physical generation. Detailed/presence/combat snapshots use existing interest routing and payload guards. Exact removal uses the existing RemoveBody command within interest sets. Client ModData is stamped only after reconciliation and cleared on retirement, interest loss and reset.

## Gate evidence

All test names below are under `tests/` and end in `_smoke.lua`.

| Gate | Implemented behavior and inspected evidence | Developer acceptance |
|---|---|---|
| M0 / SP baseline | Factory restoration to pre-5dbbadc4 behavior; throwing early-preclaim hooks in `pnc_body_factory_zombie_none`; `pnc_body_lifecycle`, `pnc_restart_rehydration`, `pnc_restored_body_identity`, release/restart suites; distinct-client-object fixture `pnc_mp_body_replication_boundary` | Pass; native SP restart still required |
| M1 / incarnation | `pnc_mp_body_incarnation`: stable current shell, fresh replacement/restored/recycled receipts, constant-generator collision suffix, earlier-shell revisits, Core provider projection, failed/verified release. `pnc_mp_body_binding_death` and existing corpse/reanimation tests prove invalidation | Pass |
| M2 / server | `pnc_mp_body_binding_server`: valid live Registry shell, idempotent incarnation, invalid IDs, identity conflicts, replacement and repeated predecessor publication; `pnc_network_scale`: interest routing; snapshots retain existing budgets | Pass |
| M3 / client ordering | `pnc_mp_body_binding_client`: both arrival orders, duplicate idempotence, stale/reordered/session conflicts, ID reuse, fresh reaffirmation, TTL, retirement watermark, exact unbind ordering. `pnc_mp_body_binding_bounds`: sustained 10,000-input capacity/expiry | Pass |
| M4 / presentation | `pnc_client_body_cleanup`: actual accepted snapshot ingestion -> reconciler -> public body resolver; no census, pre-bind rejection, stale snapshot rejection, exact removal and reset. `pnc_record_debug`: pure-client managed classification requires binding. `pnc_mp_snapshot_budget`: canonical resolver preserves presentation cadence | Pass |
| M5 / streaming and cleanup | `pnc_mp_body_audit_streaming`, `pnc_live_body_lost`, release retry, husk, persisted-shell, restart suites. Attached canonical server shells survive stream-scoped census absence. Fresh leases replace shells; exact client retirement cannot delete another incarnation. No ordinary position/outfit/ownership-only deletion or adoption | Pass, with historical anonymous-save limitation below |
| M6 / clients and gameplay | `pnc_mp_body_binding_multiclient`: A/B/C, mixed arrival order, late interest, isolated reconnect, replacement and all NPC roles using one protocol. `pnc_mp_replica_transport`, `pnc_mp_replica_visual_ownership`, follow/combat regressions preserve existing movement authorities. `pnc_player_damage`: real MP valid lease admission and rejection of missing/stale lease/online identity | Pass for developer fixtures; native movement/combat remains required |
| M7 / death | `pnc_corpse_clothing` clears source lease inside engine-conversion fixture and verifies captured retirement; existing-corpse branch also retires source. `pnc_mp_body_binding_death`: infected/noninfected death, late join, reset, stale live proof; `pnc_infected_reanimation`, `pnc_whole_body_infection`, corpse identity/inventory/clothing suites preserve domain authorities | Pass for developer fixtures |
| M8 / cleanup | Early preclaim removed; roster online-ID identity index deprecated to empty compatibility hook; startup actor attribution limited to UUID or exact population identity; anonymous position/gender/companion exceptions closed; exact incarnation hit admission; final full/compiler/static checks below | Pass |

## Harness acceptance matrix

| HARNESS_ACCEPTANCE category | Evidence |
|---|---|
| 1. SP materialize, release, rematerialize, restart and local snapshots | M0 factory/lifecycle/restart/restored suites plus M1 SP unchanged assertions; existing local snapshot regressions included in full suite |
| 2. Stable/new/stale/dead/reload incarnation | M1 receipt/provider fixture, M3 stale-proof fixture, M7 death fixture; restored MP objects issue fresh process-local receipts |
| 3. Server bind, invalid IDs, replacement, interest/reconnect and exact removal | Server fixture, real network-scale transport tests and three-client fixture |
| 4. Message-first, replica-first, duplicate, stale, reuse, conflict and TTL | Client ordering and bounds fixtures |
| 5. Admission, cache stamping, current presentation and disposable replicas | Actual runtime cleanup/resolution fixture and Core managed-admission regression |
| 6. Independent clients and stale replacement | Three-client fixture; local reset never mutates server or another client |
| 7. Census absence, loss, abstraction, restart, late streams and ordinary protection | MP body-audit streaming plus live-body-lost, lifecycle, husk, persisted-shell and restart suites |
| 8. Roles | One protocol repeated for companion, neutral, raider and faction actors; no role branches in binding modules |
| 9. Combat and movement | Actual MP player-hit admission; existing native path/replica/follow tests; stale movement receives releasePending on unbind |
| 10. Death/infection/reanimation | Existing domain suites plus protocol death and conversion capture fixtures |
| 11. Performance/persistence | Bounds fixture caps actors and weak observations at 512 each, drains TTL at 10 seconds, checks seam for world scans/new ModData roots. MP refresh sweeps at 250ms; no engine census. Actual binding descriptor measured by existing payload estimator under 2048 bytes. Diagnostics are fixed counters/last reason, not logs or persisted tables |
| 12. External reference independence | Read-only A-Life concept comparison; no edited Workshop files and no runtime/test import dependency; source guard in bounds fixture |

## Final executed validation

- `python3 tests/run_tests.py`: **969/969**, final run **6.81s**.
- `python3 tests/run_tests.py body presence husk restart replica network player_damage movement combat infection corpse reanimation follow`: **220/220**.
- Installed Project Zomboid Kahlua LuaCompiler: **25/25** runtime Lua files changed since `e3614241`; no Lua execution or native game launch.
- `pz-verify --kahlua --severity ERROR --no-snippets`: all 25 changed runtime files, **zero errors**.
- `git diff --check`: clean. Final commit/worktree confirmation is recorded in the handoff.
- Installed Java baseline fingerprint was refreshed/verified through the PZ Java harness: 42.22, Steam build 26221929, JAR SHA256 `90c54b84ebc160ae053cbefe30c7713826ca4fdb4934fde53c9ebde0ff9892f3`. Direct current Java inspection verified local replica creation keyed by online ID and OnDisconnect event availability.

Graph coverage metadata is older than this migration and reports changed/untracked paths. Current source, Git diffs and isolated execution are the acceptance evidence; no claim of exhaustive graph coverage is made.

## Retained legacy lanes

- Exact population identity may restore or clean a corresponding shell.
- Explicit UUID identity remains durable actor evidence, with existing canonical/ambiguity checks.
- A positively learned PNC-only carrier may be cleaned as a disposable PNC orphan; it cannot assign an actor from its outfit or position.
- Arbitrary outfit plus position, zero-ID saved positions, matching gender and companion ownership cannot establish identity. Those recovery/deletion exceptions were removed.
- Truly anonymous historical shells cannot safely be distinguished from ordinary zombies. They are preserved rather than guessed at. This is an explicit safety limit for old saves, not proof of current-shell duplication.

## User-owned native acceptance

Do not infer zero visual precursor from synthetic tests. Run the existing ROADMAP native checklist: SP restart; fresh MP materialization; two players together; independent range entry/exit; chunk unload/reload; reconnect; server restart; abstraction/rematerialization; companion/neutral/hostile behavior; combat/movement; infected/noninfected death and reanimation.

Developer work has not launched native Project Zomboid or published Workshop content. Any native contradiction reopens the relevant gate; this report does not supersede runtime evidence.
