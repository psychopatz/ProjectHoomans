# Remaining private-boundary review

P7J's lexical supplement found 101 candidate source lines in 15 private namespaces
beyond the previously guarded roots. `P7J_PRIVATE_SCAN_PROOF.json` records exact
paths, provisional owners and limitations. Definition ownership is inferred from
fully qualified initialization sites; candidate counts are not accepted defects.
Compound aliases and alias-only namespace initialization require source fallback.
The event-memory calendar leak discovered separately has been migrated to the
public CurrentWorldDay query, with its existing function and remote age checks.

Review each group with current MCP caller/dependency/test evidence before changing
it. Keep direct owner calls, explicit authority and bounded engine behavior. A
large table of public aliases is inappropriate when the actual defect is a domain
implementation living in the transport folder. Instrumentation may need an owner
hook; it does not justify exposing every internal function. No new debt baseline.

| Candidate private namespace | Inferred owner | Candidate files | State |
| --- | --- | ---: | --- |
| `PNC.ClientPresenceSync.Internal` | Presence | 2 | Pending graph/source review |
| `PNC.PathService.Internal` | Pathing | 10 | Pending graph/source review |
| `PNC.HomeDutyService.Internal` | Production | 2 | Pending graph/source review |
| `PNC.Network.Internal` | Networking | 9 | Pending graph/source review |
| `PNC.BaseValidationService.Internal` | Settlement | 1 | Pending graph/source review |
| `PNC.ColonyStorageService.Internal` | Colony | 2 | Pending graph/source review |
| `PNC.Conversation.Authority.Internal` | Conversation | 10 | Resolved in P7K: 12 LLM social-reaction service/policy modules moved to Conversation; Networking retains guarded require forwarders and command routing. |
| `PNC.FacilityService.Internal` | Settlement | 1 | Pending graph/source review |
| `PNC.Treatment.Internal` | Health | 1 | Pending graph/source review |
| `PNC.AnimationScenes.Internal` | Presentation | 3 | Pending graph/source review |
| `PNC.Combat.Internal` | Combat | 2 | Pending graph/source review |
| `PNC.LiveBodyControl.Internal` | Pathing | 1 | Pending graph/source review |
| `PNC.BehaviorCompanion.Internal` | Behavior | 2 | Pending graph/source review |
| `PNC.Server.Internal` | Composition | 1 | Pending graph/source review |
| `PNC.EnginePathPlanner.Internal` | Pathing | 1 | Pending graph/source review |

Next: review the remaining 14 candidate private namespaces in `P7J_PRIVATE_SCAN_PROOF.json`
with MCP caller/dependency/source evidence, migrate genuine cross-domain private coupling
to owner-controlled public contracts, and classify intra-domain/composition/false-positive
cases. Preserve leases, fixed effect policy, receipts and SP/MP command admission.
Paused wording authoring stays paused.

The Identity/Semantics/Social/World group remains open until its remaining public
read/adapter relations are justified and real private coupling is eliminated.
