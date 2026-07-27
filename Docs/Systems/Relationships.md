# Relationships

## Foundation

`PNC_Relationships` is the single shared boundary for faction-enemy checks and
authoritative faction transitions. Perception asks this service whether two NPC
records are enemies instead of embedding its own faction matrix.

The initial matrix is:

| Observer | Companion | Neutral | Hostile |
|---|---:|---:|---:|
| Companion | peaceful | peaceful | enemy |
| Neutral | peaceful | peaceful | enemy |
| Hostile | enemy | enemy | peaceful |

Neutral NPCs do not initiate combat with players or ordinary zombies. They do
recognize hostile NPCs as enemies, allowing them to defend themselves and other
survivors against looters.

## Player Provocation

An accepted, server-authoritative player weapon hit changes a neutral NPC to
the hostile faction. The transition:

- applies the standard hostile attack flags
- clears stale recruitment/owner state
- assigns `hostile_hunt`
- clears the previous target and attack action
- schedules immediate target reassessment
- dirties faction and hostility persistence before the combat snapshot is sent

Companions therefore recognize and attack the newly hostile NPC using the same
matrix. Clients never author this transition.

Future reputation, faction diplomacy, and individual grudges should extend
`PNC_Relationships`; perception and damage routing should continue to consume
the service rather than maintaining parallel rules.
