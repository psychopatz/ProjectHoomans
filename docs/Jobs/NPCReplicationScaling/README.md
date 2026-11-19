# NPC Replication Scaling

Project Hoomans needs responsive roster browsing and nearby NPC presentation with many players and hundreds of NPCs. This job measures replication cost first, then reduces work through demand-driven hydration, event-driven presentation invalidation, compatibility-class caching, and **verified deterministic appearance reconstruction**. The canonical runtime `identitySeed` remains immutable; the codec does not replace it or rewrite authored `generationSeed` values.

- [Roadmap](ROADMAP.md) defines phases, comparisons, and acceptance gates.
- [Architecture](ARCHITECTURE.md) defines seed provenance, transport ownership, mod-asset compatibility, and recovery.
- [Runbook](AGENT_RUNBOOK.md) defines workload, exact-round-trip, and failure-injection validation.
- [P1 baseline](P1_BASELINE.md) records the pre-change measurements and consumer audit.
- [P2 hydration](P2_HYDRATION.md), [P3 representation selection](P3_REPRESENTATIONS.md), and [P4 convergence](P4_CONVERGENCE.md) record outcomes and final acceptance evidence.
- [Progress](PROGRESS.md) records verified work and exactly one starting Next Chunk.
- [Handoff](HANDOFF.md) records the resumable workspace checkpoint.

The P1-P4 replication objective is developer-complete. Broader runtime CPU/persistence/hydration work discovered during native play is owned by the [Lightweight NPC Runtime job](../LightweightNPCRuntime/README.md); that follow-up must preserve this job's accepted protocol and must not reopen it as a parallel replication system.

The [starting companion job](../UnifiedStartingCompanionAuthoring/ROADMAP.md) owns authoring and spawn fidelity. The [population job](../UnifiedNPCPopulationExpansionArchitecture/ARCHITECTURE.md) owns NPC population generation and activation. This replication job **consumes their server-resolved NPCs**; it does not replace preset schemas, authority, saved appearance, or inventory replication.
