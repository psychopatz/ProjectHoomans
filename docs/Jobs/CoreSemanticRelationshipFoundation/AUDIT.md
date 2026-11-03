# Audit — Core Semantic & Relationship Foundation

## Final independent audit result

**Verdict:** READY FOR USER LIVE TEST.

The final independent audit rechecked the production paths that had invalidated earlier closeouts and found the developer-owned P0-P20 objective complete.

### Final repository truth

At the final audit:

- `psychopatzCore`: `main @ c62262c`, ahead 11, clean.
- `DynamicTrading`: `main @ 89cfe191`, ahead 13, clean.
- `ProjectHoomans`: `main @ 29be4cfb`, ahead 26, clean.

The former Dynamic Trading `DTHoomans_Conversation.lua` working-tree edit is historical: it was incorporated into commit `be9e8e10` and is no longer an outstanding local modification.

### Independently verified final behavior

- Unknown `PNC_CharacterUUID` mirror -> Core resolves first -> forged identity remains `not_issued`; Hoomans subsequently adopts Core's legitimate generated identity rather than the forged mirror.
- DT/Hoomans shared-social writes preserve foreign extensions/memories and remain idempotent.
- production `ActorConversationService` isolates DT/Hoomans grammar by effective capabilities.
- required standalone Dynamic Trading semantic families parse and produce bounded factual behavior.
- route/news WorldKnowledge facts return evidence-backed responses.
- real resident-excursion handlers populate canonical travel state and human-facing settlement presentation.
- FAILED excursion behavior is correct before departure, after departure with `completedAt = 0`, while visiting, while returning, and across retry.
- reconstructed persistence deep-copies the persisted storage representation into a fresh backing table; the reloaded trader is a distinct Lua object with canonical travel state preserved.
- WorldKnowledge `Save/Load` restores fact/evidence data after reconstruction.

### Final validation

- Core focused identity/social/conversation/semantic checks: PASS.
- Dynamic Trading full suite: `43/43` PASS.
- Project Hoomans full suite: `982/987`.
- changed P20 Lua syntax: PASS under `luac5.3 -p`.
- `git diff --check`: PASS in all three repositories.

The five Hoomans failures are the same classified baseline failures:

- `pnc_companion_commands_smoke.lua`
- `pnc_semantic_harness_worker_modules_smoke.lua`
- `pnc_semantic_horde_command_ack_smoke.lua`
- `pnc_semantic_horde_tactical_prompt_smoke.lua`
- `pnc_semantic_local_route_smoke.lua`

No developer implementation phase remains. Native SP/MP acceptance is user-owned.

## Durable audit conclusions

The completed audits established these enduring conclusions:

1. **Core authority:** PsychopatzCore owns canonical actor/player social identity, generic shared relationship state, and reusable semantic/conversation mechanisms.
2. **Identity trust:** mirrored adopter fields are hints, not authority. Identity issuance/adoption must be backed by canonical Core state or an explicitly validated adopter authority.
3. **Relationship integrity:** adopters mutate the latest Core relationship through bounded merge/event contracts and may not overwrite another adopter's extension.
4. **Semantic isolation:** pack ownership and effective conversation capabilities prevent installed-but-ineligible adopter grammar/actions from leaking.
5. **Factual dialogue:** current location/route/news claims come from canonical DT/Core state; missing evidence yields bounded uncertainty.
6. **Presentation:** stable machine IDs remain persistence keys while player-facing dialogue uses bounded human-readable presentation resolvers.
7. **Travel ownership:** actual gameplay travel/excursion lifecycle owns origin/destination/current transitions; Lua timestamp state is interpreted numerically.
8. **Persistence evidence:** headless reload acceptance reconstructs fresh runtime objects from persisted representations rather than relying on same-object continuity.

Detailed authority contracts live in `ARCHITECTURE.md`; execution discipline lives in `AGENT_RUNBOOK.md`. Git history retains the full reopen-by-reopen forensic record.

## Condensed audit history

| Audit stage | Main defect found | Resolution |
| --- | --- | --- |
| Post-P7 | player-key fork, destructive social mirror, broken pack schema/lifecycle, synthetic hot-plug acceptance | repaired across P8-P12 |
| P13-P15 audit | real Hoomans identity handoff fork, production parser capability leak, incomplete/fabricated DT whereabouts | repaired across P13-P15 |
| P16-P17 audit | forgeable identity provenance and test-injected factual grounding | replaced by authoritative issuance and canonical DT factual state |
| P18-P19 audit | mirror-to-authority bootstrap, missing live destination/origin wiring, raw machine-ID presentation, reload evidence gap | repaired across P18-P19 |
| P20 audit | FAILED-after-departure Lua truthiness bug and same-object persistence proof | repaired by numeric lifecycle logic and reconstructed persistence |

Earlier detailed audit narratives are intentionally removed from the active job docs to reduce future agent context; they remain recoverable from Git history.

## Native user-owned handoff

The next evidence should come from real Project Zomboid SP/MP sessions, especially:

- DT-only and combined saves;
- add/remove/re-add flows;
- real restart persistence;
- excursion failure/recovery;
- settlement/location naming;
- multiplayer lifecycle and UI/dialogue quality.

Do not reinterpret missing native evidence as developer failure unless a native test reproduces a concrete defect.
