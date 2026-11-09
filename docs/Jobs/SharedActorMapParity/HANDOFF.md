---
handoff_schema: 1
target_repo: "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
branch: "main"
head: "d1da19d15426956852ddf4e0d9517f028797b541"
worktree_fingerprint: "8f65c9dd30b6c619c6e1a303bd3b6bb13fbc46cf61edc089a9c075dd6abbbd73"
state: "DIRTY_RESUMABLE"
parent_status: "DEVELOPER_VERIFIED_NATIVE_ACCEPTANCE_PENDING"
phase: "provider-parity contract and map diagnostics"
retrieval_tier: "verify"
updated_at: "2026-11-09T10:45:00Z"
---

## Checkpoint

The agreed architecture is one Core actor/travel/map system with two provider
profiles. DTHoomans materializes the canonical actor only when nearby and
eligible for live Hoomans simulation; DTAbstract never materializes. Presence
transitions must not change actor ID, group ID, journey ID, route, settlement,
or arrival history.

## Verified source state

- Core owns the actor-map renderer and provider-neutral group-journey seam.
- Hoomans abstract traversal reaches Core travel through its traversal bridge.
- DTHoomans is the Hoomans physical provider and routes commercial movement
  through Hoomans mobile-group services.
- DTAbstract directly uses Core abstract travel and must remain Hoomans-free.
- Yellow Hoomans squares are abstract-group diagnostics; cyan/purple diamonds
  are discovery signals, not proof of physical actors or settlement sites.

## Implemented in the latest slice

- Core owns `PsychopatzMapMarkerDiagnostics`, a bounded provider registry with
  normalized `actor`, `abstract_group`, `discovery_signal`, and
  `settlement_site` rows.
- Core actor diagnostics normalize `materialized`/`abstract` from provider
  lease state, retaining trader/body/group/community/journey metadata.
- Hoomans and DTAbstract register read-only diagnostic adapters; they do not
  add another actor renderer.
- Map Debug close/open is stale-instance-safe, and the authorized Debug menu
  exposes an ON/OFF marker inspector.

## Known gaps

- The complete Hoomans physical controller and DTHoomans materialization
  handoff have not yet been proven against the Core journey lifecycle.
- Native restart, nearby materialization, remote dematerialization, and dense
  map performance remain user-owned acceptance.

## Latest audit evidence

- Architecture scan: Project Hoomans health **80.2**, coverage **76.9**,
  confidence **62.5**. Broad Director/Communities cycle findings are outside
  this bounded map vertical slice.
- Focused harnesses: Hoomans **7/7**, Dynamic Trading **9/9**, Core **5/5**.
- Latest implementation focus: Core Debug/diagnostics/actor **4/4**, Hoomans
  map **5/5**, and DTAbstract map/host **4/4**. DynamicTrading full suite is
  **84/84**. Whole-Hoomans remains affected by the two recorded boundary
  failures and one unrelated dirty-tree translation expectation.
- Direct source verification confirms the DTHoomans live-body position path,
  dematerialization rebase, Hoomans Core traversal bridge, DTAbstract Core
  abstract movement, and Core actor-map deduplication.
- Static-only limitation: native materialization/performance and restart
  persistence have not been observed in Project Zomboid.

## Next action

Use the marker inspector to validate the DTHoomans chain in a live nearby and
remote case, then change the physical travel controller only after the Core
journey identity/rebase/arrival gates are covered.

## Evidence labels

`CODE_VERIFIED`: source ownership and adapter wiring.

`RECORDED_NOT_RERUN`: harness results listed in `PROGRESS.md`.

`STATIC_ONLY`: native materialization and performance behavior.

No native game launch, save mutation, Workshop publication, or profiler-setting
change was performed by this implementation slice.

## Conversation landing checkpoint

The shared conversation mechanism now has a Core-owned landing builder at
`PsychopatzCore/Conversation/PsychopatzActorConversationLanding.lua`. It is
provider-neutral and consumes only Core semantic pack APIs plus injected
domain callbacks. DTCommon's trader conversation uses it for the single
landing node and filters/handles Dynamic Trading actions; the same path is
reached after both DTHoomans and DTAbstract access decisions.

Verification: DT conversation **9/9**, DT trader suite **19/19**, full DT
suite **86/86**, and Core landing smoke **PASS**. The old root-node
array-order assertions were replaced with semantic-ID assertions. A bounded
DTCommon pending-open queue now retries after Core publishes the actor
projection, so DTHoomans and DTAbstract do not permanently fail on a snapshot
race. The next implementation chunk is to make the semantic harness CodeBuilder
package-neutral for Core, Project Hoomans, and DTCommon, then bind generated
DTCommon pack/landing data without introducing a second loader.
