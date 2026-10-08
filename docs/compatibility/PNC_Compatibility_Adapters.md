# Project Hoomans compatibility adapters

Hoomans bodies are `IsoZombie` carriers, so every mod-specific integration
must establish ownership before it changes zombie state. The shared boundary
is `PNC.Compatibility.ActorOwnership`.

## Integration classes

Pick exactly one class per provider and never claim a capability the provider
cannot honour.

| Class | Owns foreign actors? | Registration | Capabilities | Current |
|---|---|---|---|---|
| `foreign_actor` | Yes, on the `IsoZombie` class | `ActorOwnership.RegisterAdapter` with `detect` | whatever is really implemented (`targeting`, `relationships`, `damage`, `events`) | Bandits, Project A-Life |
| `policy_hook` | No | `PNC.Compatibility.API.RegisterAdapter`, no `detect` | `events` only | Necroa |
| `feature_integration` | No | none | none — publish a namespace | Companion Dogs |

`ActorOwnership.RegisterAdapter` is the only registration that also installs an
ownership predicate, so any provider whose bodies live on the `IsoZombie` class
must use it. A provider that only needs to keep Hoomans bodies out of its own
lanes is a `policy_hook` and must not claim `targeting`, `relationships`, or
`damage`.

## Provider module shape

Every provider lives in one folder and follows the same hub-and-spokes layout:

```
PNC/Core/Compatibility/Mods/<Provider>/PNC_<Provider>_Adapter.lua   -- entry hub
PNC/Core/Compatibility/Mods/<Provider>/PNC_<Provider>_<Role>.lua    -- role spokes
```

- The **hub** is thin: namespace bootstrap, ordered literal `require` lines,
  then registration. It returns the provider namespace table. Providers load
  before consumers.
- A **spoke** depends only on the provider's shared `Internal` table, which its
  `_Access` spoke owns. A spoke must never `require` a sibling; if two spokes
  need the same helper, that helper belongs in `Internal`.
- A guarded `X or require "…/sibling"` fallback is allowed only where the spoke
  must also stay loadable on its own, and the hub must still load that provider
  before the consumer.
- Every registering adapter declares `id`, `version`, `apiVersion`, and
  `capabilities`. Do not add spec fields nothing reads.
- A spoke that must run before shared composition (for example a PZ file-map
  patch) is loaded from `PNC/00_PNC_Init.lua` instead of the hub, and the hub
  documents why.

A `foreign_actor` adapter therefore looks like:

```lua
PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
local Bridge = PNC.Compatibility.Necroa or {}
Bridge.Internal = Bridge.Internal or {}
PNC.Compatibility.Necroa = Bridge

local Ownership = PNC.Compatibility.ActorOwnership
    or require "PNC/Core/Compatibility/PNC_ActorOwnership"

require "PNC/Core/Compatibility/Mods/Necroa/PNC_Necroa_Access"
require "PNC/Core/Compatibility/Mods/Necroa/PNC_Necroa_Targeting"

if not Ownership or type(Ownership.RegisterAdapter) ~= "function" then
    return Bridge
end

Ownership.RegisterAdapter({
    id = "Necroa",
    version = "Necroa3-B42.20",
    apiVersion = 1,
    detect = Bridge.Internal.IsNecroaBody,
    capabilities = { targeting = true, events = true },
    enumerateTargets = Bridge.Targeting.EnumerateTargets,
})

return Bridge
```

Require the hub from the layer composition root that owns it
(`PNC_SharedComposition.lua`, `PNC_ServerComposition.lua`,
`PNC_ClientComposition.lua`).

`tests/pnc_compatibility_shape_smoke.lua` enforces this shape: hub thinness,
literal requires, exactly one hub per provider, every spoke reachable from its
hub, no unrooted spokes, no unguarded sibling requires, and required
registration metadata.

## Shared compatibility contract

The reusable actor contract lives in `PNC/Core/Compatibility`:

- `PNC_Compatibility_DamageContext.lua` normalizes provider hit metadata
  before provider damage enters the Hoomans-owned pipeline.
- `PNC_Compatibility_API.lua` provides registration, stable target references,
  target enumeration, relationship checks, damage dispatch, and protected
  optional event callbacks.
- `PNC_Compatibility_IncomingDamage.lua` is the reusable inbound contract for
  foreign actors damaging a Hoomans body. It resolves the Hoomans record,
  enforces ownership and authority, and delegates to the Hoomans wound/health
  pipeline. Foreign mods must not call `IsoZombie:Hit` on a Hoomans body when
  this capability is available.
- `PNC_Compatibility_ActorRef.lua` keeps provider/id/kind separate from a
  transient `IsoZombie` carrier.
- `PNC_Compatibility_Targeting.lua` merges foreign targets into Hoomans NPC
  perception without putting foreign bodies into Hoomans' own NPC registry.

Adapters should implement only the capabilities they can prove. Unknown
ownership, missing brains, stale references, and unavailable callbacks fail
closed. A new `foreign_actor` integration should normally provide `targeting`,
`relationships`, and `damage`; add `events` only for native reactions that can
be safely handled by the foreign mod.

## Project A-Life interaction slice

Project A-Life support is isolated under:

`PNC/Core/Compatibility/Mods/ProjectALife/`

| File | Owns |
|---|---|
| `PNC_ProjectALife_Adapter.lua` | hub: namespace, spoke order, registration, inbound event routing |
| `PNC_ProjectALife_Access.lua` | body/record lookup, identity recovery, shared predicates |
| `PNC_ProjectALife_Policy.lua` | directed stance table, resolution, conflict escalation |
| `PNC_ProjectALife_Targeting.lua` | actor records to stable foreign refs, target enumeration |
| `PNC_ProjectALife_Combat.lua` | attack permission in both directions, damage delivery |
| `PNC_ProjectALife_DamageBridge.lua` | reroutes A-Life hits on managed bodies into `IncomingDamage` |
| `PNC_ProjectALife_ReverseBridge.lua` | stops A-Life classifying managed bodies as default enemies |

Two rules keep this provider honest:

1. **Engagement is owner-centric.** A managed actor engages a Project A-Life
   actor only when that actor has already hurt the managed actor (self defence)
   or when `ProjectALife.Relations.hostileToPlayer` says it is at war with the
   managed actor's owner. A faction stance for the pair is an additional
   configured signal; the default is `neutral` and therefore no engagement.
2. **A stance must survive re-resolution.** `AttackExecution.captureTargetRef`
   and `resolveActionTarget` rebuild a committed `foreign_npc` target without
   `factionId`, so the adapter recovers the A-Life faction from the live body
   (`ProjectALifeUID` plus `ActorRegistry`). Losing it made perception approve a
   target that damage time then rejected forever.

Conflict escalation writes only directed faction pairs. A hit with an unknown
faction on either side is recorded for diagnostics but never escalated to a
`*` wildcard, which would otherwise turn one stray hit into permanent warfare
against every faction.

## Bandits interaction slice

Bandits support is isolated under:

`PNC/Core/Compatibility/Mods/Bandits/`

`PNC_Bandits_IncomingBridge.lua` wraps Bandits' public hit entry point
at runtime without editing Workshop files, routes managed Hoomans bodies
through the canonical damage context, and submits bounded client requests
for multiplayer authority validation.
The adapter discovers Bandits through `BanditZombie` caches, revalidates
`BanditBrain` hostility at both selection and damage time, and delegates hits
to the Bandits body. The Bandits-side bridge is under:

`Bandits/42.20/media/lua/shared/Compatibility/ProjectHoomans/`

It adds Hoomans to Bandits' combined combat cache without counting them as
ordinary Bandits or zombies, routes melee/ranged hits through the Hoomans
ownership and inbound-damage checks, and keeps Bandits' native `Bandit.Say`
pipeline for dedicated captions.

The two flavor systems remain separate:

1. Hoomans social observers receive `compat.bandits.hooman_hurt` through the
   normal Hoomans social-flavor network and presentation path.
2. Bandits use `Bandit.SoundTab.HOOMANS_*` and `Bandit.Say`, with Bandits' own
   captions and cooldowns.

Combat flow is therefore:

`foreign target -> adapter relationship check -> owning damage contract -> optional adapter event -> owning mod's flavor pipeline`

No compatibility adapter should call another mod's UI or replace its global
combat loop.

## Necroa policy integration

The inspected Necroa version uses native `IsoZombie` carriers for its special
survivor and hazmat variants. It therefore does not register a foreign actor
provider or duplicate Hoomans targeting. Its compatibility module lives under:

`PNC/Core/Compatibility/Mods/Necroa/`

The policy exposes ownership, corpse identity, feature exclusion, infection
eligibility, and inbound damage routing. Necroa remains responsible for its
own zombie behavior; its patched handlers ask this policy before mutating a
body. Hoomans-owned explosions use `IncomingDamage`, and multiplayer requests
are validated and applied by the Hoomans server command boundary.

The current mask slice is split into small provider-owned modules:

- `PNC_Necroa_Mask.lua` recognizes Necroa-compatible masks and equips a
  mechanical `Base.Hat_SurgicalMask` on new Hoomans NPC records when Necroa is
  active. It uses Hoomans equipment/inventory APIs, so removing the item is a
  real state change rather than a visual-only flag.
- `PNC_Necroa_ExposureServer.lua` is the server tick boundary. An unmasked
  Hoomans body receives forced Knox infection through `PNC.NPCWounds`; no
  Necroa zombie body is infected and no vanilla `setInfected` call is made.
- `PNC_Necroa_ExposureServer_Social.lua` and
  `PNC_Necroa_ExposureServer_Observers.lua` emit Hoomans relationship events
  and send Hoomans SocialFlavor only when a nearby NPC observes mask removal.
- `PNC_Necroa_ZombieFlavor.lua` is client-side and uses Necroa's native
  `IsoZombie:addLineChatElement` path for the zombie eating/gibberish lines.
  It never registers those lines in Hoomans SocialFlavor.

This keeps the lore boundary explicit: Necroa supplies the airborne-world
rule and zombie captions, while Hoomans owns NPC equipment, infection state,
relationship memory, and Hoomans dialogue.

Only add a full Necroa ActorRef adapter if a future Necroa release introduces
actors that are not native `IsoZombie` objects.

When a foreign mod updates, recheck its actor constructor, caches, relationship
fields, hit function, and speech function before changing Hoomans core. If one
of those changes, patch only that adapter or the foreign-side compatibility
folder unless the generic contract itself is genuinely insufficient.

## Foreign-mod patch rule

The adapter only identifies ownership. The foreign mod must also skip Hoomans
bodies inside every private update/cache/spawn conversion path. The fallback
predicate must remain local to the foreign mod so load order does not matter:

```lua
local function IsHoomansBody(body)
    local modData = body and body.getModData
        and body:getModData() or nil
    if modData and (
        modData.PNC_Owner == "ProjectHoomans"
        or modData.PNC_NPC == true
        or modData.PNC_PersistedShell == true
        or (modData.PNC_UUID ~= nil
            and modData.PNC_BodyKind == "live")
    ) then
        return true
    end
    return body and body.getVariableBoolean and (
        body:getVariableBoolean("PNCLive") == true
        or body:getVariableBoolean("PNCActor") == true
    ) or false
end
```

Put `if IsHoomansBody(body) then return end` before the foreign mod mutates
targets, hands, teeth, `isUseless`, animation variables, brains, or caches.
Do not rely on callback ordering or a later repair pass.

The Necroa patch currently protects reanimation, infection threat, push/corpse
infection, tripping, zombie speech, explosive actor behavior, hazmat loadouts,
and mask/blood visuals. Recheck those handlers after every Necroa update.

## Installed Bandits patch

The current Bandits2 B42.20 patch is applied to Workshop ID `3268487204` in
both local copies discovered on this machine:

- `.steam/debian-installation/steamapps/workshop/content/108600/3268487204`
- `.steam/debian-installation/steamapps/common/ProjectZomboid/projectzomboid/steamapps/workshop/content/108600/3268487204`

The patched files are `client/BanditUpdate.lua`, `client/BanditZombie.lua`,
and `server/BanditServerZombie.lua`. Workshop updates can overwrite these
edits, so re-audit the Bandits version and reapply the guards after an update.
