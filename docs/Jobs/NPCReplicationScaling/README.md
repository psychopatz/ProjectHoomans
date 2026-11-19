# NPC Replication Scaling

Project Hoomans needs responsive roster browsing and nearby NPC presentation with many players and hundreds of NPCs. This job measures replication cost first, then reduces work through demand-driven hydration, event-driven presentation invalidation, compatibility-class caching, and **verified deterministic appearance reconstruction**. The canonical runtime `identitySeed` remains immutable; the codec does not replace it or rewrite authored `generationSeed` values.

- [Roadmap](ROADMAP.md) defines phases, comparisons, and acceptance gates.
- [Architecture](ARCHITECTURE.md) defines seed provenance, transport ownership, mod-asset compatibility, and recovery.
- [Runbook](AGENT_RUNBOOK.md) defines workload, exact-round-trip, and failure-injection validation.
- [P1 baseline](P1_BASELINE.md) records the pre-change measurements and consumer audit.
- [Progress](PROGRESS.md) records verified work and exactly one starting Next Chunk.
- [Handoff](HANDOFF.md) records the resumable workspace checkpoint.

The [starting companion job](../UnifiedStartingCompanionAuthoring/ROADMAP.md) owns authoring and spawn fidelity. The [population job](../UnifiedNPCPopulationExpansionArchitecture/ARCHITECTURE.md) owns NPC population generation and activation. This replication job **consumes their server-resolved NPCs**; it does not replace preset schemas, authority, saved appearance, or inventory replication.
