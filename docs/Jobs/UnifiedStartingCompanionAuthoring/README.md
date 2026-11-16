# Unified Starting Companion Authoring

This job owns the character-creation companion customization system for
Project Hoomans.

Native user testing exposed a missing entry-point journey after the original
P5 verification: the companion composer could be effectively unreachable in
the real creation flow. P5R has now repaired and developer-verified that
final-screen integration; native P6 acceptance remains user-owned.

The goal is not to build a second NPC creator. The existing debug/Unique NPC
creator, character-creation companions, presets, and future NPC authoring
surfaces must converge on one reusable NPC blueprint/composition pipeline.
Starting-companion gameplay supplies relationship/player binding policy on top
of that generic pipeline.

Read in this order:

1. [ROADMAP.md](ROADMAP.md) — parent objective, audit conclusion, phases, and gates.
2. [ARCHITECTURE.md](ARCHITECTURE.md) — stable blueprint, binding, authority, and persistence contracts.
3. [AGENT_RUNBOOK.md](AGENT_RUNBOOK.md) — implementation and verification procedure.
4. [PROGRESS.md](PROGRESS.md) — verified current truth and exactly one Next Chunk.
5. [HANDOFF.md](HANDOFF.md) — current resumable checkpoint.

The existing starter companion service remains the canonical gameplay spawn and
ownership path. The existing debug creator becomes another consumer of the
same authoring model rather than a parallel implementation. Unique NPC and
starting companions also share one canonical NPC authoring field registry.
Current Project Hoomans-owned Unique NPC code/data is cut over to that schema;
legacy authoring aliases/loaders are not retained as a parallel compatibility
system. Compact network forms are codecs over the canonical registry, not a
separate variable system. Normal UI and debug diagnostics share
the resolver field-source trace so inherited, derived, generated, explicit,
and server-controlled values remain explainable.
