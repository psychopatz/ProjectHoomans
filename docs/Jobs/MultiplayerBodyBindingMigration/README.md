# Multiplayer Body Binding Migration

This job replaces Project Hoomans' fragile multiplayer assumption that a server-side managed IsoZombie remains the same identity-bearing object on clients.

The permanent NPC identity remains the PNC registry record. Multiplayer physical bodies are vanilla-networked zombie replicas and therefore require an explicit PNC reconciliation protocol:

    PNC NPC record
      npcId + body incarnation
              |
              v
    server IsoZombie shell
      vanilla onlineId
              |
              +---- PZ ZombiePacket ----> client-created IsoZombie replica
              |
              +---- PNC binding --------> npcId + incarnation + onlineId
                                               |
                                               v
                                      client binds/stamps replica
                                               |
                                               v
                                      human NPC presentation

Single-player must remain on its proven local-object path and must not inherit MP-only reconciliation behavior.

## Documents

- AUDIT.md — verified starting evidence and why the current methodology fails in MP.
- ARCHITECTURE.md — target authority, identity, protocol and lifecycle contracts.
- ROADMAP.md — mandatory M0-M8 migration phases and gates.
- HARNESS_ACCEPTANCE.md — deterministic developer-side regression matrix.
- AGENT_RUNBOOK.md — execution procedure and standing constraints.
- PROGRESS.md — current phase, evidence and immediate Next Chunk.

Project A-Life is a read-only architecture reference, not a code dependency:

/home/psychopatz/.steam/debian-installation/steamapps/workshop/content/108600/3803984183/mods/ProjectALifeNPCs

Do not edit the Workshop mod and do not copy its implementation verbatim. Reproduce only independently justified architectural guarantees in Project Hoomans.
