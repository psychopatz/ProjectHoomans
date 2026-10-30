# Multiplayer Body Binding Migration

**Current status:** M10 works in native SP but dedicated MP still failed because restored shells stream only after players load their chunks. M11 late-stream restart reconciliation plus MP debug/replica binding repairs are developer-validated in `fc932e1d` and `5c10a95b`; renewed native MP acceptance is the remaining completion gate.

This job replaces Project Hoomans' fragile multiplayer assumption that a server-side managed IsoZombie remains the same identity-bearing object on clients, and hardens the physical carrier lifecycle so a managed live-human shell is proactively retired before Project Zomboid can virtualize it into native zombie-population state.

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
- ROADMAP.md — mandatory M0-M11 migration phases and gates.
- HARNESS_ACCEPTANCE.md — deterministic developer-side regression matrix.
- AGENT_RUNBOOK.md — execution procedure and standing constraints.
- PROGRESS.md — current phase, evidence and immediate Next Chunk.

Project A-Life is a read-only architecture reference, not a code dependency:

/home/psychopatz/.steam/debian-installation/steamapps/workshop/content/108600/3803984183/mods/ProjectALifeNPCs

Do not edit the Workshop mod and do not copy its implementation verbatim. Reproduce only independently justified architectural guarantees in Project Hoomans.

The historical M0-M8 developer evidence is recorded in [DEVELOPER_ACCEPTANCE.md](DEVELOPER_ACCEPTANCE.md), but native SP/MP testing contradicted the shell-lifecycle convergence invariant. M9 closes the newly identified native-virtualization gap developer-side; renewed native SP/MP testing remains mandatory.
