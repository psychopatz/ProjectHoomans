# Health

## V1
- `PNC_Health` owns authoritative HP, incapacitation, wound-healing recovery, and engine-health buffering
- live NPCs keep engine health as a disposable buffer while custom HP remains the source of truth
- reaching `0` HP enters `incapacitated` instead of immediate death
- incapacitated NPCs keep a live body and show a pulsing overhead bar; there is no separate instant-revive state
- bandaged wounds restore HP gradually and the NPC returns to normal locomotion when authoritative HP reaches `INCAPACITATED_RECOVERY_HP` (5 by default)
- incapacitated bodies continuously enforce crawler, on-floor, and fall-on-front state on both the authority and remote clients; generic locomotion cannot overwrite the downed pose

## Body-Part Treatment

- `PNC_NPCWounds` owns authoritative wounds, body-part health, bleeding, bandage state, and Knox infection state.
- NPC bandaging queues a vanilla `Bandage` timed action on the treating client, including `EventBandage`, the first-aid sound, and the item progress indicator.
- Live NPC self-treatment uses the same `FirstAidApplyBandage` sound. Its treatment snapshot lets each remote client play that sound once, while a per-body transient key prevents duplicate playback on the authority client.
- Every successful authoritative bandage publishes a short-lived completion
  revision. Interested clients play the framework-owned
  `PNC_BandageComplete` 3D cue once from the treated NPC and deduplicate it by
  revision, timestamp, and body part. The audio is a vendored, renamed copy of
  Dynamic Trading's healing-completion cue, so Dynamic Trading is not a
  runtime dependency.
- No state changes when the action is queued. On completion, the host/server revalidates player range, NPC/wound state, debug permission, and the selected item before applying the bandage and consuming it.
- Player-to-NPC treatment uses the mid-height interaction pose (`Loot` /
  `LootPosition=Mid`) instead of the self-bandage animation. Range is checked
  before queueing, throughout the timed action, immediately before completion,
  and again by the authority.
- Treatment height follows the vanilla `LootPosition` action variable:
  incapacitated/on-floor patients and leg/groin/foot wounds use `Low`,
  head/neck wounds use `High`, and remaining standing-patient wounds use
  `Mid`.
- Cancelling, walking, running, losing the item, or leaving range prevents completion.
- Every wound stores its applied item type/name, healer First Aid level, gradual heal rate, dirty-bandage deadline, initial damage, and healed-point total. Better First Aid and better materials heal faster; dirty bandages pause healing until replaced.
- Authorized Health/debug menus show the remaining world-hour dirty timer, healed/initial/remaining points, and current heal rate. `Make Bandage Almost Dirty` moves the authoritative deadline to 0.02 world hours in the future so the normal transition can be tested without bypassing it.
- The old bulk revive command is a compatibility alias for bandaging every treatable wound. It consumes one accepted material per wound and never grants HP or changes incapacitation directly.

## NPC Self-Treatment

- `PNC_Behavior_Treatment` runs before combat/jobs whenever an NPC has an open wound or dirty bandage.
- A live NPC with a nearby enemy retreats first. It starts treatment only after the area is clear and immediately cancels the action, without consuming an item, if a threat closes inside the interruption radius.
- Live self-treatment uses the injured body part to choose `BandageHead`, left/right arm, upper/lower body, or left/right leg animation nodes.
- Recruited/player-owned companions consume accepted bandage or rag items from their canonical PNC inventory. Neutral and hostile NPCs have a virtual unlimited supply of ordinary ripped sheets.
- NPC First Aid is identity-seeded and progresses through the normal skill system; doctors receive an archetype bias. Skill level shortens the application action and improves gradual healing.
- Abstract NPCs use the same wound and inventory mutations on a coarse cadence without live pathing or animation. Recent combat postpones abstract treatment.
- Treatment phase, body part, and material are replicated in snapshots. Nameplates show active treatment/retreat status and the clean or dirty material currently on a wound.

## Bite Infection Lifecycle

- `NPCZombieBiteChance` still decides whether a successful zombie wound is a bite; combat resolution is unchanged.
- `NPCZombieInfectionChance` is a separate `0-100` roll performed only when a bite wound is created. `0` disables infection while preserving the bite and its damage.
- infection timing uses world age hours and progresses through `incubating`, `queasy`, `nauseous`, `fever`, and `terminal`
- fever temperature and later-stage health loss are derived from infection progress, making updates deterministic across save/load, multiplayer reconnects, and abstract presence
- fatal infection bypasses ordinary incapacitation and creates a vanilla corpse; after `NPCReanimationSeconds` (three real seconds by default), only the host/server calls the vanilla corpse-reanimation routine, which preserves the NPC's appearance and carried/worn items while producing one ordinary, vulnerable zombie
- ordinary and infected deaths retire the full NPC record immediately; only a compact name/location/token death marker remains until the engine corpse disappears or reanimates
- `PNC.API.ClearKnoxInfection(npcId, source)` is the authority-only cure integration seam. It removes the infection lifecycle but deliberately preserves the bite and all physical wound damage for normal treatment.
- debug menus can force an infected bite, jump to fever/terminal, trigger infection death, or clear Knox infection; the Health screen and snapshot dump expose infection status, progress, stage, fever, and temperature to authorized debug users

## Persistence

- schema v8 stores the most common value shared by all standard body parts as
  `partBase` and saves only exceptional parts; standard 100-point part maxima
  use a number instead of a nested table
- aggregate health percentages, wound counts, and bleeding rate are rebuilt
  from parts/wounds on load
- recent-damage display time, revive protection, and other process-clock
  values are runtime-only and do not dirty the record when they expire
- an incapacitated NPC receives a fresh short damage grace period after load;
  stale process-clock timestamps are never applied across a restart

## Client Visuals
- live NPCs render overhead nameplates with their name and HP bar; exact HP numbers are intentionally hidden from both the nameplate and Health panel
- incapacitated NPCs use a pulsing red bar variant
- Nameplate debug overlay can be toggled from the NPC monitor or Project Hoomans settings; the PsychopatzCore debug hub remains the separate global diagnostics switch
- each debug overlay component (presence, AI, job, order, target, combat,
  stamina, block reason, infection, and animation) can be enabled separately
  in Project Hoomans' in-game settings
- infected NPCs receive a separate red debug line with infection stage, fever,
  and temperature; healthy NPCs do not get an infection line

## Corpse Appearance
- before corpse conversion, visual-only outfit entries are materialized as real inventory items and assigned to worn body locations
- the canonical inventory always includes `Base.IDcard`, named `ID Card: <NPC name>` and tagged with the NPC UUID/name for future quest validation
- live clothing visuals are copied to those items so texture and tint survive conversion
- the authoritative corpse finalizes worn slots before its complete item state is transmitted to multiplayer clients

## Next Expansion

- floating damage numbers and richer faction/relation coloring

## Runtime Boundaries

- `PNC.Health` owns managed-NPC HP, incapacitation, death, revive recovery,
  and the disposable vanilla-health buffer. The NPC record remains the source
  of truth.
- `PNC.NPCWounds` owns body-part health, wound lifecycle, bleeding, gradual
  healing, and Knox infection. Its infection progression and lifecycle actions
  are separate modules, loaded through the original infection require path. It
  updates through `Health.Update` and writes changes to the authoritative
  record.
- Zombie wound application keeps the legacy randomized route and the
  defense-resolved route separate. Both use one authority check, target check,
  damage application, rollback, record-dirty, and social-event boundary.
- `PNC.PlayerDamage` is the player-hit boundary. Its stable entry point is
  `PNC/Core/Health/PNC_PlayerDamage.lua`; runtime access, policy, application,
  client event capture, report validation, the report contract, bounded
  session rate limiting, and diagnostics live in the adjacent `PlayerDamage/`
  spokes.
- `PNC.Treatment` owns wound treatment and accepted medical-item consumption.
  `PNC.MedicalCareService` owns the separate queued medical-care lifecycle.
- Health UI, nameplates, and network snapshots project health state. The
  character API also exposes explicit mutation operations; those delegate to
  authoritative health services and broadcast only accepted changes.

### Player Hit Report Contract

`PNC.PlayerDamage.Report` creates and normalizes a scalar-only v1 report:

```lua
{
    schemaVersion = 1,
    id = "managed-npc-id",
    attackerOnlineID = 12,
    bodyOnlineID = 77,
    bodyInstanceID = "991",
    bodyLease = "lease-token",
    weaponFullType = "Base.Axe",
    damage = 1.5,
}
```

The client values identify the request and describe the observed hit. The
server binds the attacker to the actual command sender, resolves the live NPC
body, checks its identity and lease, resolves the currently held weapon,
rechecks range and floor, and scales damage before calling
`PNC.PlayerDamage.Apply`. Reports without `schemaVersion` remain accepted for
older clients; unsupported versions and malformed scalar fields fail with an
explicit reason. The public `PNC.PlayerDamage` table and original `require`
path stay stable.

`PNC.Core.IsAuthority()` gates both report admission and damage application.
Remote clients only observe a hit and send the compact report. Singleplayer
applies locally; the server owns multiplayer mutation. The report cooldown
state is session-only: its FIFO holds at most 2,048 attacker/target entries,
with at most 64 active entries per player. Normal admission prunes a fixed
budget; pressure cleanup is bounded by the queue capacity. The tracker stores
only scalar IDs and timestamps, never engine objects.

Per-record debug output is disabled unless `record.runtime.debug == true`.
Messages have bounded scalar fields and use signatures such as:

```text
health.player_hit event=client_request npc=<id> player=<id> status=sent reason=report_sent weapon=<type> damage=<n>
health.player_hit event=server_admission npc=<id> player=<id> status=applied reason=damaged weapon=<type> damage=<n>
```

The event, status, and reason identify the request route, authority outcome,
and final application result without retaining or logging Java objects.

### Wound and Infection Diagnostics

The NPC Monitor's per-record **Record Debug** toggle also enables opt-in wound,
zombie attack, infection, and treatment diagnostics. Example signatures are:

```text
health.zombie_attack route=resolved npc=<id> attacker=<id> status=applied reason=wounded part=<part> wound=<type> damage=<n>
health.infection event=stage_transition npc=<id> status=updated reason=stage_changed stage=<stage> progress=<n> fever=<n>
health.treatment event=complete route=npc_assist npc=<id> actor=<id> target=<id> status=applied reason=bandaged part=<part> item=<type>
```

Messages are disabled unless that NPC's record debug flag is enabled. Fields
are limited to scalar values, control characters are stripped, and each field
is capped at 64 characters. Treatment diagnostics distinguish the accepted
bandage mutation from the end of item consumption and transaction completion.
Rejected authority requests include `status=rejected reason=not_authority`.

## Health Architecture and Migration Plan

### Current architecture and module ownership

The shared `PNC_Health` entry point composes live state, incapacitation, death,
damage, and update modules. `PNC_NPCWounds` composes body-part definitions,
clothing, mutation, infection, zombie attack, healing updates, and snapshots.
`PNC_PlayerDamage` separates engine access, policy, authoritative application,
the versioned report contract, bounded rate limiting, client event capture,
server admission, and diagnostics. `PNC_Treatment` keeps its stable namespace
and now composes medical policy, item access and rollback, authoritative wound
actions, and snapshot projection. The server medical-care service,
persistence/network snapshots, and client UI remain separate owners because
they have different authority or lifecycle boundaries.

`PNC_NPCWounds` keeps the stable namespace and composition file. Infection stage
and fever progression live separately from infect/clear/fatal lifecycle
actions. Zombie attack application has a common authority/rollback adapter;
the legacy randomized route and defense-resolved route retain their individual
decision and result contracts.

### Module boundaries and follow-up

Keep the stable health and wound entry points. Continue splitting by ownership
only when a module combines independent work:

1. Completed the infection progression/lifecycle split and the legacy/resolved
   zombie attack split while keeping `PNC.NPCWounds` and both original require
   paths unchanged.
2. Keep snapshot builders and UI projection read-only. Keep explicit API
   mutation operations as authority-gated delegates to the existing health
   and wound services.
3. Keep bounded diagnostics at the player-hit, zombie-attack, infection, and
   treatment boundaries behind the existing per-record debug seam, with no
   always-on trace history.

Do not move `PNC_MedicalCareService`, the Health UI, or persistence into the
shared domain modules. They are runtime adapters and consumers with independent
lifecycles.

### State, authority, and compatibility

- `record.health` and its body/wound/infection data are authoritative NPC state.
  Snapshot payloads and the native `IsoZombie` health value are projections or
  runtime adapters.
- Client hit reports contain stable scalar identifiers. The server revalidates
  each identifier and gameplay precondition before applying effects.
- Treatment item consumption, wound mutation, revive, infection death, and
  ordinary NPC death remain authority-owned.
- Infection lifecycle/progression and both zombie attack entry points require
  `PNC.Core.IsAuthority()` to return true. Missing authority support fails
  closed before infection or damage state changes.
- Keep `PNC.Health`, `PNC.NPCWounds`, `PNC.PlayerDamage`, public function names,
  return reasons, and the existing composition `require` paths stable during
  module moves. Load providers before consumers and event adapters last.
- Do not change translations, persistence schema, damage tuning, or gameplay
  wording as part of a structural split unless a separately tested behavior
  change requires it.

### Migration and verification order

1. Completed the player-hit split: preserve the entry point, formalize the
   scalar report contract, bound cooldown state, and test validation and
   authority outcomes.
2. Completed the treatment split: preserve public functions and successful
   returns, separate policy, inventory, actions, and snapshot projection, and
   make direct wound application reject non-authority explicitly.
3. Completed the infection progression/lifecycle and zombie attack route split,
   with tests for server/client authority, both successful attack routes, and
   rollback after rejected health damage.
4. Run the focused Health tests, full test suite, `pz_verify --kahlua`, and
   stale-require/diff checks after the split.
5. Compare all failures with the captured baseline; keep unrelated staged
   inventory/constants failures separate.
6. Still required: manually exercise singleplayer and multiplayer
   hit/treatment/death flows and inspect the bounded per-record diagnostic
   events. This in-game verification was not run during the refactor.

### Performance, risks, and rollback

- Keep update work bounded by the current record/body data; do not add world
  scans or whole-map cleanup to a per-hit or per-tick path.
- Keep request tracking fixed-capacity and diagnostics disabled by default.
- The main structural risk is an incorrect `require` order or a missed consumer
  of a public namespace. Focused composition tests and the full suite are the
  rollback gate.
- For the player-hit slice, restore the prior `PNC_PlayerDamage.lua` entry and
  remove its new `PlayerDamage/` spokes as one unit. No composition file or
  network command name changes are needed.
- For the treatment slice, restore the prior `PNC_Treatment.lua` entry and
  remove its `PNC_Treatment/` spokes as one unit. The authority guard on
  `Treatment.ApplyBandage` is covered by the treatment policy smoke test.
- For the infection and zombie attack slices, restore the original two wound
  modules and remove their progression/lifecycle and common/route spokes as a
  unit. Their stable require paths remain unchanged, and focused tests cover
  authority rejection and rollback.

### Acceptance Criteria

- Public health, wound, treatment, and player-damage entry points retain their
  contracts unless a separately identified behavior change is accepted by a
  focused test.
- Client-originated gameplay changes are admitted and committed only by the
  authority; stale, malformed, duplicate, and out-of-range hit reports fail
  safely with explicit reasons.
- History, report payloads, and diagnostic strings remain bounded and contain
  no live Java objects.
- Focused Health tests pass, Kahlua validation passes, and the full suite has no
  failures beyond the recorded baseline.
- Manual multiplayer checks confirm server-owned damage, body-buffer restore,
  wound replication, and readable opt-in diagnostic events.
