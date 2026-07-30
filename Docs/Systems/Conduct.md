# Behavioral Conduct

## Purpose

Conduct is the server-verified record of what one specific player character or
NPC has consistently done. It is actor-owned and distinct from personality,
which describes stable tendencies, and from a directed relationship, which
describes one NPC's opinion of a target. Conduct is not universally known
reputation. Future witnesses, gossip, or factions may consume selected
evidence, but Phase 4 propagates nothing.

Player conduct belongs to the character UUID, never the username. Dead
characters retain their history and a new survivor starts neutral. NPC conduct
lives at `record.social.conduct`, survives presence changes, and is never
generated from personality or `identitySeed`.

## Schema

Both owners use conduct schema V1:

```lua
{
    schemaVersion = 1,
    revision = 0,
    scores = { reliability = 0, generosity = 0, compassion = 0,
        courage = 0, restraint = 0, honesty = 0, groupLoyalty = 0 },
    baseline = { ...same dimensions... },
    evidence = {},
    recentEvidenceIDs = {},
    lastEvaluatedAt = 0,
}
```

Every dimension is signed and clamped to -100 through 100. Generosity,
restraint, and honesty remain neutral when no authoritative event provides
evidence; fields are not filled merely for symmetry.

Evidence stores deterministic ID, source social-event ID/type, actor and
subject entity keys, world-age timestamps, dimension effects, strength,
decay, permanence, visibility, sharing metadata, and map-style tags. Valid
visibility values are `private`, `direct`, `witnessed`, and `public`.
Visibility is metadata only and creates no witnesses or propagation.

## Derivation, Decay, and Limits

Scores are always derived:

```text
score = clamp(baseline + sum(effect * effectiveStrength), -100, 100)
effectiveStrength = max(0, strength - decayPerDay * elapsedDays)
```

Permanent evidence does not decay. Recalculation is explicit; there is no
per-frame update. Each owner retains at most 64 active entries. Invalid and
expired temporary evidence is removed first, followed by the weakest
temporary evidence. Ties use effective strength, creation time, then evidence
ID. Permanent evidence is preserved. Consolidation into historical labels is
a future extension.

## Event Mappings

Only accepted events create evidence:

| Event | Objective actor effects | Decay/day | Sharing |
|---|---|---:|---|
| `treated_wound` | compassion +2, generosity +1 | 0.02 | no |
| `saved_from_incapacitation` | compassion +8, courage +5, group loyalty +4, reliability +3 | 0.0025 | yes |
| `protected_from_attacker` | courage +6, group loyalty +3, reliability +2 | 0.0075 | yes |
| `survived_combat_together` | reliability +2, courage +2, group loyalty +1 for each participant | 0.015 | no |
| `abandoned_in_combat` | reliability -8, courage -6, group loyalty -8, compassion -3 for the abandoner | 0.003 | yes |

All currently use `direct` visibility. Relationship personality modifiers do
not alter these objective effects. Duplicate, cooldown-blocked, saturated,
rejected, or canceled events create no conduct evidence. Shared combat uses
one deterministic evidence ID per participant, even though the same social
event can create two directed relationship memories.

## Authority, Deduplication, and Revisions

`PNC.Conduct` exposes copied reads and authority-only mutation:

- `GetForPlayerCharacter`, `GetForNPC`, `GetForEntity`
- `GetScore`, `GetScores`
- `AddEvidence`, `RemoveEvidence`, `Recalculate`, `PruneEvidence`
- `ApplySocialEvent`
- `NormalizePlayerConduct`, `NormalizeNPCConduct`

The social-event pipeline preflights every conduct participant before
relationship mutation. After relationship commits succeed, the already
validated conduct records commit synchronously. Evidence IDs derive from the
social event, actor key, and role; no random ID is generated.

Player evidence advances conduct, character-record, and registry revisions.
NPC evidence advances conduct and social revisions and marks the NPC record
dirty. The registry's dirty-batch convention prevents a second
`recordRevision` increment when the same accepted event already changed that
NPC's relationship. Conduct never changes `presenceRevision`, and a
conduct-only mutation never advances a relationship revision. Reads and
unchanged recalculations advance nothing.

## Persistence and Debugging

Phase 4 advances NPC persistence to V13, NPC social data to V3, and the player
registry to V3. Migration adds neutral records to existing living/dead
characters and NPCs, generates no evidence, and does not infer history from
approval or old memories.

The admin/debug-only Relationship Inspector displays observer and target
conduct, scores, revisions, evidence effects, current strength, decay,
visibility, source event, subject, timestamps, and tags. Its five named event
buttons use the real authoritative pipeline; there are no direct score-edit
commands. `PNC.ConductDebug.Format(entityKey, worldAgeHours)` provides a
read-only text formatter.

## Non-Goals

Phase 4 does not implement universal reputation, faction/community knowledge,
witnesses, gossip, rumors, factions, diplomacy, romance, dialogue, promises,
theft, order refusal, desertion, resource sharing, or hostility changes.
