local T = require "tests/support/test"

T.addPackagePaths()
T.load("tests/pnc_npc_foundation_parity_baseline_smoke.lua")

-- Provide minimal ISUI stubs so PsychopatzPortraitPanel_DescriptorSupport
-- can be loaded directly to verify content-addressed cache keys.
ISUI3DModel = ISUI3DModel or {
    derive = function(_, name)
        return { __name = name }
    end,
}
package.preload["ISUI/ISUI3DModel"] = function() return ISUI3DModel end

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local ActorPresentation = require
    "PsychopatzCore/Actors/PsychopatzActorPresentation"
local DescriptorSupport = require
    "PsychopatzCore/UI/Components/PsychopatzPortraitPanel_DescriptorSupport"
local SurvivorWorldClient = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldClient"

local registry = Actors.NewRegistry()
local dirtyReasons = {}
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Actors = Actors
PsychopatzCore.Actors.DefaultRegistry = registry
PsychopatzCore.SurvivorWorldClient = SurvivorWorldClient
PsychopatzCore.ActorProjectionSync = {
    MarkDirty = function(reason)
        dirtyReasons[#dirtyReasons + 1] = tostring(reason or "")
        return true
    end,
}

PNC = PNC or {}
PNC.Core = PNC.Core or {}
PNC.Core.IsAuthority = function() return true end
PNC.Core.IsClientOnly = function() return false end
PNC.Core.Now = function() return 5000 end
PNC.Registry = {
    Data = {},
    MarkDirty = function() end,
    Get = function(id) return PNC.Registry.Data[tostring(id)] end,
    GetLiveZombie = function() return nil end,
}
PNC.Network = {
    ClientState = {
        snapshots = {},
        npcPresentations = {},
    },
}
PNC.Persistence = PNC.Persistence or {}

T.load("ProjectHoomans", "shared",
    "PNC/Core/Identity/PNC_Identity_Portrait.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Core/Persistence/PNC_Persistence_CoreProvider.lua")

PNC.Identity.GetCharacterSummary = function(rec)
    return {
        identitySeed = rec.identitySeed or 1,
        isFemale = rec.isFemale == true,
    }
end
PNC.Identity.NormalizeSeed = function(seed) return tonumber(seed) or 1 end
PNC.Identity.HashText = function(text)
    local h = 17
    for i = 1, #text do
        h = (h * 31 + string.byte(text, i)) % 2147483647
    end
    return h
end
PNC.Identity.RollAppearance = function(rec)
    return rec.appearance or {}
end

local CoreProvider = PNC.Persistence.CoreProvider
local ClientPortraitSpec = T.load(
    "ProjectHoomans", "client", "PNC/UI/PNC_ClientPortraitSpec.lua"
)

-- 1. Adopted female NPC preserves gender and appearance in Core (never flipped
--    to male or replaced with a random Core face).
local record = {
    id = "npc:myrna:1",
    name = "Myrna Patz",
    displayName = "Myrna Patz",
    identitySeed = 918273,
    isFemale = true,
    identity = {
        displayName = "Myrna Patz",
        isFemale = true,
        survivor = {
            forename = "Myrna",
            surname = "Patz",
            skinTexture = "FemaleBody02",
            hairModel = "Long2",
            hairColor = { r = 0.45, g = 0.22, b = 0.12, a = 1 },
        },
    },
    appearance = {
        skinTexture = "FemaleBody02",
        skinColor = { r = 1, g = 1, b = 1, a = 1 },
        hairModel = "Long2",
        hairColor = { r = 0.45, g = 0.22, b = 0.12, a = 1 },
        outfitItems = { "Base.Shirt_FormalWhite" },
    },
    equipment = {
        worn = {
            Torso1 = "Base.Jacket_Varsity",
            Hat = "Base.Hat_BeanieHat",
        },
        wornVisuals = {
            Torso1 = {
                fullType = "Base.Jacket_Varsity",
                tint = { r = 0.8, g = 0.1, b = 0.1, a = 1 },
            },
        },
        attached = {},
    },
    x = 100,
    y = 200,
    z = 0,
    runtime = {},
}
PNC.Registry.Data[record.id] = record

local adopted, adoptErr = CoreProvider.EnsureActor(record, PsychopatzCore)
T.truthy(adopted, adoptErr)
local canonical = registry:Get(record.id)
T.equal(canonical.identity.gender, "female",
    "Core adoption preserves isFemale=true as female gender")
T.equal(canonical.appearance.resolved.hairModel, "Long2",
    "Core adoption preserves Hoomans hairModel")
T.equal(canonical.appearance.resolved.skinTexture, "FemaleBody02",
    "Core adoption preserves Hoomans skinTexture")

-- 2. Map hover and conversation both use PNC.ClientPortraitSpec and produce
--    identical specs and identical Descriptor cache keys, even if Core's
--    entry.portrait is stale or missing wornVisuals.
local staleCoreEntry = {
    actorID = record.id,
    revision = canonical.revision,
    portrait = ActorPresentation.BuildPortrait(canonical),
}
staleCoreEntry.portrait.face.hairModel = "StaleWrongHair"
staleCoreEntry.portrait.equipment = { worn = { Torso1 = "Base.Tshirt_Default" } }

local hoverSpec = ClientPortraitSpec.Build(staleCoreEntry, {
    faceOnly = true,
    includeCurrentClothing = true,
    clothingMode = "current",
    coreFallback = SurvivorWorldClient.GetPortraitSpec,
})
local convoSpec = ClientPortraitSpec.Build({ id = record.id, record = record }, {
    id = record.id,
    record = record,
    faceOnly = true,
    includeCurrentClothing = true,
    clothingMode = "current",
})

T.truthy(hoverSpec and convoSpec, "both surfaces built portrait specs")
T.equal(hoverSpec.isFemale, true, "hover portrait preserves female gender")
T.equal(hoverSpec.appearance.hairModel, "Long2",
    "hover portrait uses live Hoomans hair instead of stale Core projection")
T.equal(hoverSpec.equipment.worn.Torso1, "Base.Jacket_Varsity",
    "hover portrait uses live Hoomans worn clothing")
T.equal(hoverSpec.equipment.wornVisuals.Torso1.tint.r, 0.8,
    "hover portrait preserves wornVisuals item tint")

local hoverKey = DescriptorSupport.Key(hoverSpec)
local convoKey = DescriptorSupport.Key(convoSpec)
T.equal(hoverKey, convoKey,
    "hover and conversation share the exact same SurvivorDesc cache key")

-- 3. Changing NPC looks or worn item tint invalidates the key AND syncs
--    updated appearance/identity back to Core.
record.appearance.hairModel = "Bob"
record.identity.survivor.hairModel = "Bob"
record.equipment.worn.Torso1 = "Base.HoodieDOWN_WhiteTINT"
record.equipment.wornVisuals.Torso1 = {
    fullType = "Base.HoodieDOWN_WhiteTINT",
    tint = { r = 0.1, g = 0.2, b = 0.9, a = 1 },
}

local updatedHoverSpec = ClientPortraitSpec.Build(staleCoreEntry, {
    faceOnly = true,
    includeCurrentClothing = true,
    clothingMode = "current",
    coreFallback = SurvivorWorldClient.GetPortraitSpec,
})
local updatedConvoSpec = ClientPortraitSpec.Build({ id = record.id, record = record }, {
    id = record.id,
    record = record,
    faceOnly = true,
    includeCurrentClothing = true,
    clothingMode = "current",
})
local updatedHoverKey = DescriptorSupport.Key(updatedHoverSpec)
local updatedConvoKey = DescriptorSupport.Key(updatedConvoSpec)
T.truthy(updatedHoverKey ~= hoverKey,
    "changing hair/clothes/tint produces a new Descriptor cache key")
T.equal(updatedHoverKey, updatedConvoKey,
    "updated hover and conversation still share one Descriptor cache key")
T.equal(updatedHoverSpec.appearance.hairModel, "Bob",
    "hover portrait immediately reflects updated hairModel")
T.equal(updatedHoverSpec.equipment.worn.Torso1, "Base.HoodieDOWN_WhiteTINT",
    "hover portrait immediately reflects updated clothing")

local syncOk, syncRes = CoreProvider.SyncPromotedCoreActorToCore(
    record, PsychopatzCore
)
T.truthy(syncOk, tostring(syncRes))
local syncedCanonical = registry:Get(record.id)
T.equal(syncedCanonical.appearance.resolved.hairModel, "Bob",
    "SyncPromotedCoreActorToCore syncs updated appearance into Core")
T.equal(syncedCanonical.identity.survivor.hairModel, "Bob",
    "SyncPromotedCoreActorToCore syncs updated survivor identity into Core")
T.equal(dirtyReasons[#dirtyReasons], "core_actor_presentation_sync",
    "appearance/identity sync marks ActorProjectionSync dirty")

-- 4. Pure Core actor without a Hoomans record still falls back cleanly to
--    SurvivorWorldClient.GetPortraitSpec with matching id/identitySeed/revision.
local pureActor, pureErr = registry:Ensure({
    actorId = "core:abstract:1",
    ownerMod = "PsychopatzCore",
    identitySeed = 555,
    isFemale = true,
    displayName = "Core Wanderer",
    archetypeID = "core.survivor",
    world = { location = { position = { x = 10, y = 20, z = 0 } } },
})
T.truthy(pureActor, pureErr)
local pureEntry = {
    actorID = "core:abstract:1",
    revision = pureActor.revision,
    portrait = ActorPresentation.BuildPortrait(pureActor),
}
local pureSpec = ClientPortraitSpec.Build(pureEntry, {
    coreFallback = SurvivorWorldClient.GetPortraitSpec,
})
T.truthy(pureSpec, "pure Core actor falls back to SurvivorWorldClient spec")
T.equal(pureSpec.id, "core:abstract:1", "Core fallback populates spec.id")
T.equal(pureSpec.identitySeed, 555, "Core fallback preserves identitySeed")
T.equal(pureSpec.isFemale, true, "Core fallback preserves female gender")
T.equal(pureSpec.revision, pureActor.revision,
    "Core fallback preserves actor revision for hover change tracking")

T.finish("pnc_portrait_surface_parity_and_cache_smoke")
