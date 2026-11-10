# Roadmap — Unified NPC Population and Expansion Architecture

**Status:** DOCUMENTATION BASELINE — implementation has not started for this
goal.

**Primary repository:** ProjectHoomans (`main`)

**Participant repositories:** PsychopatzCore (`main`), DynamicTrading (`main`)

## Objective

Establish one canonical NPC population pipeline that can serve Project
Hoomans, Dynamic Trading, and future domain expansions such as a Gang mod.
Activating an expansion should register and enable that expansion's NPC
source; it must not create a second generation, identity, persistence, or
materialization pipeline.

The target direction is:

```text
domain expansion intent/policy
        -> PsychopatzCore canonical generation
        -> Project Hoomans materialization (when enabled)
        -> abstract/live provider projection
```

Dynamic Trading and a future Gang mod are domain expansions. Project Hoomans
remains the NPC framework and physical materialization owner. PsychopatzCore
is the provider-neutral authority for canonical actors, groups, IDs,
provenance, and durable population state.

## Audit conclusion

The repositories are not starting from zero. Core already exposes the
canonical `SurvivorWorld.Generation.BuildGroupPlan` and bootstrap commit
seams. Hoomans already has the Core adapter and
`PNC.MobileGroupDirector.MaterializeCoreGroup` boundary. Dynamic Trading
already supplies trader presets and can select an abstract or Hoomans-backed
representation.

The remaining split is at the ownership boundaries:

1. Dynamic Trading still owns a trader-specific generation façade and
   trader-specific population cadence instead of registering a generic source
   with Core.
2. Hoomans still has hardcoded faction/archetype policy for mobile groups and
   a large generation/materialization path instead of accepting extensible
   Core group plans through a stable materializer contract.
3. Map/hover projections can expose a marker before its canonical actor or
   provider lease is hydrated. The resulting `UNKNOWN` value is not a valid
   presence mode; it is an invalid or incomplete projection that must be
   rejected, repaired, or hidden.
4. The repeated names seen on a new save therefore cannot be treated as proof
   of a valid live NPC. The source, provenance, canonical actor, PNC record,
   and provider lease must be traced as one chain before any stale seed or
   duplicate writer is removed.

This is a static/code audit conclusion. Fresh-save, restart, and nearby-body
behavior remain native Project Zomboid acceptance gates.

## Ownership contract

| Concern | PsychopatzCore | Project Hoomans | Dynamic Trading / future expansions |
| --- | --- | --- | --- |
| Canonical actor/group IDs | Owns and persists | Reads | Supplies domain request; never invents a competing canonical ID |
| Group/faction generation contract | Owns plan schema, source registry, commit and provenance | Consumes plans | Registers source, profiles, member specs, and domain intent |
| Population activation/caps | Owns generic orchestration and validation | Exposes materialization capability | Supplies source-specific policy values |
| PNC records and NPC bodies | No engine-specific body ownership | Owns physical materialization and PNC lifecycle | Requests materialization through Hoomans |
| Abstract/live projection | Owns canonical state vocabulary and identity | Owns abstract/body projection mechanics | Chooses capability/profile; does not duplicate actor state |
| Domain behavior | Provider-neutral contracts only | NPC/faction/materialization policy | Trader, gang, territory, commercial, or other domain policy |
| Map/debug inspection | Shared Core gate/identity contract | Map/NPC UI adapter | Provides domain labels and diagnostics only |

The single-writer rule is mandatory: an expansion may request a canonical
group, but only Core may commit the actor/group identity and only Hoomans may
create the physical NPC representation.

## Phases and gates

### P0 — Documentation and evidence baseline (current)

Record the ownership contract, current seams, observed failure modes, and the
implementation order in this job directory. Do not edit production code in
this phase.

**Gate:** roadmap, architecture contract, runbook, progress ledger, and
handoff agree on one pipeline and explicitly preserve Hoomans as the
materializer.

### P1 — Core generic generation-source contract

Add a provider-neutral Core registration and orchestration seam. A source
descriptor should identify the expansion, generation kind, activation state,
caps/cooldowns, and serializable request/profile data. Core should validate
the request, allocate stable IDs, commit through the existing SurvivorWorld
bootstrap, record provenance, and return one canonical result.

Source-specific policy values remain supplied by the expansion; Core owns the
generic scheduling/validation contract and the no-duplicate/no-collision
rules. Core must not import Hoomans or Dynamic Trading.

**Gate:** a fake source and the existing trader source can use the same Core
contract; repeated requests are idempotent or explicitly rejected; all actor
and group IDs are Core-owned; Core tests pass without either adopter loaded.

### P2 — Hoomans materializer and extensible NPC policy

Turn the existing Core-group materialization seam into the stable Hoomans
adapter contract. Accept Core `memberSpecs` and group metadata, create/update
PNC records exactly once, and project each actor as `abstract` or `live`
through one normalized presence vocabulary.

Replace hardcoded “known mobile archetype” gates with registered faction,
role, actor, and movement policies. Keep PNC records, body creation, nearby
spawn/despawn, and NPC monitor/map integration in Hoomans. Do not move body
creation into Core or Dynamic Trading.

**Gate:** an arbitrary registered expansion profile can materialize through
Hoomans; no unknown presence mode can reach map hover or monitor; missing or
unhydrated canonical actors are repaired/hidden rather than rendered as
`UNKNOWN`.

### P3 — Dynamic Trading adapter migration

Make Dynamic Trading a source/profile provider on the Core contract. Keep
trader presets, commercial lifecycle, caravan behavior, and trader-specific
cadence values in Dynamic Trading as domain policy. Remove or reduce the
generic generation responsibility from the DT façade to a compatibility
adapter, and make `DTAbstract` and `DTHoomans` consume the same canonical
actor/group result.

**Gate:** enabling Dynamic Trading enables only its registered trader source;
DTAbstract and DTHoomans switch representation without a second actor,
group, PNC record, or body identity; disabling the mod does not erase Core
state.

### P4 — Expansion contract proof for a future Gang mod

Prove the extension boundary with a Core/Hoomans contract fixture or a small
test-only gang source. The proof should supply gang faction/profile/member
data and domain behavior while reusing Core IDs and Hoomans materialization.
Do not create a production Gang mod as part of this goal.

**Gate:** the hypothetical source requires no edits to Core's canonical
identity schema and no direct writes to PNC/body state; only registration,
profiles, and gang policy are new.

### P5 — Diagnostics, migration, and native acceptance

Add or finish the gated map-debug override and bounded audit output at the
shared Core/Hoomans boundary. Trace source → plan → canonical group → actor →
PNC record → provider lease → map/monitor projection. Add save/restart repair
for stale markers and incomplete records only after the source of the
observed new-save names is identified.

**Gate:** fresh-save and restart tests prove that map hover, NPC monitor,
physical presence, abstract/live switching, and debug release all reference
the same canonical actor. `UNKNOWN` is absent from valid output and is
diagnosed as a rejected projection if encountered.

## Non-goals

- Do not make Project Hoomans responsible for trader, gang, or other domain
  intent.
- Do not create a Core implementation that imports Dynamic Trading or Hoomans.
- Do not create a second NPC generation path for each expansion.
- Do not force physical NPC materialization when Hoomans is disabled.
- Do not silently delete existing save data or stale markers before a bounded,
  versioned migration is proven.
- Do not launch native Project Zomboid or publish Workshop content as part of
  the developer-side implementation phases unless separately authorized.

## Dependencies and implementation order

The order is deliberately Core first, Hoomans second, then Dynamic Trading:

```text
P0 docs
  -> P1 Core source contract
  -> P2 Hoomans materializer/policy contract
  -> P3 Dynamic Trading adapter
  -> P4 expansion proof
  -> P5 live acceptance and cleanup
```

No adopter-specific generation rewrite should begin before the P1 contract is
accepted. The existing authority migration and semantic-harness jobs remain
historical/supporting records; this job is the parent roadmap for the NPC
population/expansion boundary.
