# Roadmap — Project Hoomans Portable Actor Lifecycle & GC Adoption

Participant work under Core L0-L9.

## H0 — Death/reference audit

Map Health.Kill, retireDeadRecord, RemoveRecord, DeathMarkers, CorpseAwareness, bonds, romance, faction, quest/memorial and every actor ref that can survive death.

## H1 — Core lifecycle bridge

After Core lifecycle contracts are accepted, bridge authoritative Hoomans death to Core Retire while preserving consequence ordering and preventing double retirement.

## H2 — Hoomans GC roots

Register only justified strong roots such as active corpse/reanimation identity, durable bond/family/romance, and real quest/memorial/faction refs.

No broad all-dead-colonists-forever root.

## H3 — Social/history migration

Adapt Hoomans relationship/semantic consumers to Core's per-actor memory bank and historical edges. Remove per-edge memory assumptions after caller-zero.

## H4 — Death/semantic/interaction integration

Prove named deceased, weak historical, forgotten/label-only, and stale lifecycle-revision behavior.

## H5 — Scale/final participant acceptance

Retire large NPC sets, run corpse/reanimation cleanup, multiple GC generations, save/reload, semantic/conduct/relationship regressions and combined DT representation tests.

H5 alone does not complete the parent.
