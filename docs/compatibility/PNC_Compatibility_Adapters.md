# Project Hoomans compatibility adapters

Hoomans bodies are `IsoZombie` carriers, so every mod-specific integration
must establish ownership before it changes zombie state. The shared boundary
is `PNC.Compatibility.ActorOwnership`.

## Adapter contract

Add one file under:

`Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Compatibility/Mods/`

Register the foreign ownership predicate from that file:

```lua
PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}

local Ownership = PNC.Compatibility.ActorOwnership

return Ownership.RegisterAdapter({
    id = "Necroa",
    version = "Necroa-B42.20",
    detect = function(body)
        if Ownership.IsHoomansOwned(body) then return false end
        local modData = body and body.getModData
            and body:getModData() or nil
        return modData and modData.NecroaActor == true or false
    end,
    updateFiles = {
        "client/NecroaUpdate.lua",
    },
})
```

Require the adapter from `PNC_SharedComposition.lua`.

The reusable actor contract lives in `PNC/Core/Compatibility`:

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
closed. A new integration should normally provide `targeting`,
`relationships`, and `damage`; add `events` only for native reactions that can
be safely handled by the foreign mod.

## Bandits interaction slice

Bandits support is isolated under:

`PNC/Core/Compatibility/Mods/Bandits/`

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
