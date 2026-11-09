# Restart husk safety audit and repair

Date: 2026-11-06. Scope: shared Project Hoomans body lifecycle, including companions and other NPC variants in singleplayer and server-authoritative multiplayer.

## Finding and evidence

An NPC record and its IsoZombie shell have different lifetimes. PZ can restore the shell through population/chunk loading without its Lua ownership markers; the NPC record can separately materialize a replacement. The anonymous shell then needs positive identification and prompt combat suppression before verified removal.

The existing system already has startup reconciliation, a persisted husk ledger, learned PNCShellCarrier outfit IDs, an OnZombieCreate handler, a bounded pending removal queue, and a periodic census fallback. This repair strengthens those paths rather than replacing NPC persistence.

Confirmed defects in the pre-fix code:

1. `PNC_BodyLifecycle_HuskLedger_Identity.lua` compares exact learned outfit IDs. `PersistentOutfits.setFallenHat` changes bit 32768 in that same ID. A learned carrier therefore becomes unrecognized after that flag changes. Ledger matching also compares the unnormalized IDs. This can bypass both startup strong identity and anonymous husk reclamation.
2. `ReplicationBodies.lua` limits learned carrier IDs to 256. The installed engine's `pickOutfitMale` and `pickOutfitFemale` each select among 500 variants. The persistent set can fill during repeated creation/restarts and silently stop learning subsequent shells. Their loss of ModData then also loses the carrier fallback. This is a capacity defect, not evidence that the current save has reached the limit.
3. `queueHuskReap` returns when its queue is full before clearing combat state. A positively identified extra husk can retain its target and zombie AI until another sweep admits it.
4. The reaper only observes creation and periodic census scans. Save-loaded bodies can miss the creation callback, or acquire an outfit identity after that callback. Such bodies wait for the census; there was no reaper update hook to suppress them sooner.

Current log (`/home/psychopatz/Zomboid/console.txt`, modified 2026-11-06 15:43 +08:00) contains startup cleanup `passes=3 removed=0`, a reaper pump with `ledgerEntries=3 orphansEnabled=6`, and a new PNCShellCarrier spawn with ID 6553607. It does not capture the identity of the reported attacker or prove which defect caused that encounter. Do not describe this as a live reproduction.

Graph exploration used the indexed Hoomans project, inbound carrier-identity call tracing, and per-file coverage checks. Relevant Hoomans files had no recorded coverage gaps before changes. The Java harness verified the installed baseline was current; its graph metadata was older, so the relevant `PersistentOutfits.java` methods were read directly. Conclusions about engine encoding come from that current source, not the older graph metadata. This is a bounded lifecycle audit, not a whole-project certification.

## Repair plan and implemented behavior

- [x] Normalize only the mutable fallen-hat bit for carrier recognition and exact ledger outfit comparison. Preserve sex, outfit index and random variant; never broaden recognition to neighboring outfits or seeds.
- [x] Recognize old persisted carrier keys that already contain the fallen-hat bit. Keep the existing persisted layout and policy migration.
- [x] Raise the bounded carrier capacity to 2048: enough for 500 variants for each sex and old hat-bit keys. The legacy general outfit namespace remains separate and is not ownership proof.
- [x] Clear combat before returning for a full or already-queued removal queue. Repeated observations can reapply suppression if the engine resets AI.
- [x] Add an authority-only OnZombieUpdate carrier check. Skip the local spawn window, active/marked NPC bodies, foreign actors, reanimated players and dead bodies through existing guards. Queue known anonymous carriers using the same deferred reaper.
- [x] Retain deferred post-create removal, identity revalidation and verified detach before ledger consumption. Clients do not own removal. No NPC records are deleted by this repair.
- [x] Add focused behavioral regressions and run the complete Lua suite plus Kahlua verification.
- [ ] User-owned native SP and MP restart acceptance below. Repository policy assigns native game validation to the user unless explicitly requested.

The update check uses the existing bounded ledger and queue; the queue never grows past its configured limit. Existing historical identifiers remain available across restart. The change introduces no new Java API calls or save layout.

## Regression evidence

`tests/pnc_shell_carrier_smoke.lua`: male/female signed IDs, hat-bit changes, old persisted keys, preservation of other variants/outfits, all 1000 carrier variants, and ledger reload.

`tests/pnc_husk_reaper_smoke.lua`: update hook registration, missing creation event, changed-hat ledger association, immediate target/AI suppression, repeated pending suppression, queue overflow and retry, eventual detach, MP client exclusion, active NPC/foreign ownership protection, and ordinary zombie preservation. Existing tests continue to cover late restore, population identity, startup, and end-to-end husk lifecycle behavior.

Validation: full Lua suite passed 1007/1007; focused husk suite passed 5/5; carrier test passed 1/1. PZ verifier scanned all 44 lifecycle Lua files with zero Kahlua errors. Follow-up focused checks were run after final small test/identity cleanup.

## Native acceptance matrix

Use a copied save. Repeat each scenario in SP and a hosted/dedicated MP server with two clients, including a late joiner:

1. Spawn/recruit a companion and representative non-companion/trader NPCs. Save and exit; restart at least three times. Confirm one controllable live body per NPC and no former shell attacking players.
2. Repeat after hats fall, after walking NPCs across chunk boundaries, and after leaving their original area unloaded until after startup completes.
3. Return to the old area after a replacement NPC has materialized. Confirm old anonymous carriers are suppressed and removed; the current NPC remains functional.
4. Restore more husks than the pending queue capacity. Confirm overflow shells cannot retain zombie combat behavior and are eventually removed.
5. Include ordinary zombies, reanimated players and another mod's actors. Confirm they are untouched. Confirm removal reaches both MP clients and a late joiner without duplicates.
6. Capture the existing `PNC husk identified`, `PNC husk reaped`, removal-failure/drop diagnostics and NPC identity records if any failure remains. Record the attacker's outfit/population ID and ownership markers rather than inferring ownership from clothing alone.

## Limits and recovery

Old anonymous shells with no retained population identity, no PNC ownership markers, and an outfit ID never learned as a carrier cannot safely be distinguished from ordinary zombies. This patch intentionally does not delete zombies based on naked appearance, proximity, NPC variant, or zombie population settings. Previously unlearned carriers can become recognizable when that exact carrier variant is learned later; this is not a guarantee of retroactive cleanup. Additional evidence is required for targeted recovery of unidentified old shells.

Native restart timing and MP packet propagation remain unverified by Lua mocks. No Workshop publication, save editing, or game launch was performed. Existing unrelated worktree changes were preserved.

## Follow-up: LIVE companion/map stall (2026-11-06)

The user reported severe map lag and companions stopping when LIVE. The new log shows repeated `persisted_shell_repaired` messages for Loyd Still, Vaughn Martinez, Cesar Leggett and Damon Stacey on consecutive frames (including 502–514), with changing outfit IDs. This is evidence of repeated identity/cleanup work, not proof that every removed body is the real companion.

The read-only pz-profiler-analysis interface confirmed capture applied to runtime `1793977578805-874225477`, singleplayer. Its bounded performance snapshot reported roughly 0.9 Server.Update calls/second, a 1781 ms historical peak, and approximately 1039 ms frame CPU / 1043 ms GPU time. These are pre-fix measurements; inclusive timers overlap and the report does not attribute the entire stall to Lua cleanup. NPC-detail capture was disabled and was not changed.

A second concrete defect was found in local presentation:

- `PNC_ClientPresenceBodies_Registry.lua` accepted cached objects when their UUID/lease was missing. PZ's current `IsoZombie.resetForReuse` wipes ModData and `VirtualZombieManager` reuses the object. A cache can therefore point to an ordinary zombie before the next census refresh.
- `PNC_ClientPresenceVisuals_BodyPresentation.lua` stamps UUID/lease from the selected snapshot. Feeding it a recycled pointer can incorrectly make that object an NPC shell and trigger repeated startup cleanup.
- `PNC_ClientPresenceTick_Apply.lua` used an unchecked `and/or` fallback to raw indexes even when the canonical resolver explicitly rejected a body. This defeated identity validation and could admit the same stale pointer again.

Implemented correction: local presentation now requires a living, attached body with matching explicit NPC identity and, when expected, a matching lease. Corpse-marked bodies are rejected. When the authority registry is available its current body must also match. Canonical rejection is final; the compatibility path used only when no resolver exists calls the same validating registry. MP continues using MultiplayerBodyBinding admission. No change was made to the user's in-progress map hover-owner edits.

Regression `pnc_local_body_reuse_smoke.lua` covers valid LIVE bodies, detachment, object reuse with erased markers, missing/mismatched leases, other NPCs, dead/corpse bodies, superseded authority bodies, and suppression of both presentation and duplicate cleanup after resolver rejection. Four existing SP/presentation fixtures now supply persistent NPC markers instead of anonymous empty body tables. Final Lua suite: **1008/1008 passed**; client PresenceSync Kahlua scan: 52 files, zero errors; diff whitespace check passed.

Java baseline freshness was refreshed and confirmed. The Java graph remains older; recycling assertions were checked directly against the current source. Hoomans coverage checks reported no recorded gaps; changed files were inspected directly. No live Lua injection or gameplay control was performed.

Restart PZ to load the changed cached modules/callbacks, then repeat follow with the map open and closed, including the ABSTRACT-to-LIVE transition. Verify that the repeated repair messages stop, the companion follows, and frame timing recovers. The stale-pointer path is regression-tested; a post-restart native performance/follow measurement is still required before declaring the reported in-game symptoms resolved.
