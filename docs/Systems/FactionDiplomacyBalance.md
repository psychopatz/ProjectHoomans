# Faction Diplomacy Balance Reference

## Sources

Structural schema and valid-value constants remain in
`PNC_FactionConstants.lua`. Tunable diplomacy and runtime limits live in
`PNC_FactionBalance.lua`; incident effects remain immutable definitions in
`PNC_FactionIncidentDefinitions.lua`; archetype policy defaults remain in
`PNC_FactionArchetypes.lua`. Services consume these definitions and do not
own balance literals.

Internal overrides may be supplied in `PNC.Config.Factions` using the exact
balance key. Numeric overrides are finite and clamped. No sandbox UI was
added in this phase.

## Current defaults

| Group | Values |
|---|---|
| Aggregation | 0.01 world-age hours (36 seconds), severe damage 25, repeated count 2 |
| Histories | 64 incidents, 128 recent IDs, 512 telemetry entries |
| Reconciliation | 16 members per pump, 64 queued faction pairs |
| Truce/peace | 24-hour default truce; +15 standing, +10 trust, grievance ×0.50 |
| Daily decay | standing 0.05, trust 0.025, fear 0.10, grievance 0.01; peace grievance ×2 |
| Friendly entry | standing ≥30, trust ≥10, grievance ≤20 |
| Friendly hysteresis | remains while standing ≥20 and grievance ≤30 |
| Wary entry | standing ≤-15, trust ≤-25, fear ≥50, or grievance ≥30 |
| Wary exit | standing >-5, trust >-15, fear <40, grievance <20 |
| Hostile entry | standing ≤-45 or grievance ≥65 |
| Hostile hysteresis | remains while standing ≤-30 or grievance ≥50 |
| Escalation weights | retaliation ×35, aggression ×15 |
| Looter peace | stronger ratio >1.15 avoids; otherwise threatens |
| Hostile looter attack | aggression ≥0.70 and target strength ≤0.75 observer strength |

Incident values:

| Incident | Standing | Trust | Fear | Grievance | Severity |
|---|---:|---:|---:|---:|---:|
| Minor attack | -8 | -10 | 2 | 10 | 0.25 |
| Severe attack | -18 | -20 | 5 | 25 | 0.65 |
| Member killed | -35 | -30 | 10 | 45 | 1.00 |
| Member rescued | 10 | 8 | 0 | -4 | 0.45 |
| Member protected | 5 | 4 | 0 | -2 | 0.25 |
| Fought together | 2 | 3 | 0 | 0 | 0.15 |
| Abandoned | -8 | -12 | 0 | 10 | 0.40 |
| Personal grievance report | -5 | -5 | 0 | 8 | 0.20 |

Archetype policy defaults:

| Archetype | Aggression | Retaliation | Caution | Hospitality | Opportunism | Outsider policy | War / peace |
|---|---:|---:|---:|---:|---:|---|---|
| Settler | 0.30 | 0.55 | 0.55 | 0.50 | 0.30 | neutral | 70 / 25 |
| Looter | 0.75 | 0.70 | 0.35 | 0.10 | 0.85 | predatory | 58 / 20 |
| Trader | 0.20 | 0.40 | 0.65 | 0.60 | 0.75 | commercial | 76 / 30 |
| Refugee | 0.15 | 0.35 | 0.80 | 0.45 | 0.25 | cautious | 80 / 28 |

Treaty consequences:

- War is symmetric and authorizes attack/pursuit only against the exact
  opposing faction.
- Peace clears war, alliance, and truce, then applies the peace metric shift.
- Truce clears war/alliance and blocks ordinary faction aggression until its
  world-age expiry.
- Alliance clears war/truce and resolves cooperation.
- Breaking an alliance applies its configured incident effects but does not
  declare war.
- Treaty changes enqueue runtime-only member reconciliation. The first bounded
  batch is processed immediately and remaining work is pumped by server tick.
  Zombie targets are preserved.

## Tuning log

| Scenario | Expected result | Observed result | Value adjusted | Old | New | Reason |
|---|---|---|---|---:|---:|---|
| _not yet live-tested_ | | | | | | |
