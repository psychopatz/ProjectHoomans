local VISUALS =
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"
    .. "Visuals/PNC_Visuals.lua"
local LUA_ROOT =
    "Contents/mods/ProjectHoomans/42.20/media/lua/client/"
local CLIENT_VISUALS = LUA_ROOT
    .. "PNC/PresenceSync/PresenceVisuals/"
    .. "PNC_ClientPresenceVisuals.lua"

package.path = LUA_ROOT .. "?.lua;" .. package.path

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual")
            .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local visualEntries = { { fullType = "Base.ServerOwnedShirt" } }
ItemVisual = {
    new = function()
        return {
            setItemType = function(self, value)
                self.fullType = value
            end,
            setClothingItemName = function() end,
            setDecal = function(self, value)
                self.decal = value
            end,
        }
    end,
}
PNC = {
    VisualProfiles = {},
}
dofile(VISUALS)

local replicaBody = {
    getItemVisuals = function()
        return {
            clear = function()
                visualEntries = {}
            end,
            add = function(_, itemVisual)
                visualEntries[#visualEntries + 1] = itemVisual
            end,
            size = function()
                return #visualEntries
            end,
        }
    end,
    getHumanVisual = function() return nil end,
    setFemaleEtc = function() end,
    setNoTeeth = function() end,
    getWornItems = function()
        error("replica appearance touched worn items")
    end,
    getAttachedItems = function()
        error("replica appearance touched attached items")
    end,
    dressInNamedOutfit = function()
        error("replica appearance dressed a real outfit")
    end,
}
assertEqual(
    PNC.Visuals.ApplyReplicaAppearance(
        replicaBody,
        {
            outfit = "Survivalist",
            outfitItems = {
                "Base.Shirt_FormalWhite",
                "Base.Trousers",
            },
        },
        false
    ),
    true,
    "safe replica appearance"
)
assertEqual(#visualEntries, 1,
    "replica appearance replaced server-owned clothing")
assertEqual(visualEntries[1].fullType, "Base.ServerOwnedShirt",
    "replica appearance changed server-owned clothing")
assertEqual(
    PNC.Visuals.HasClothingVisuals(replicaBody),
    true,
    "replica clothing visual detection"
)
assertEqual(PNC.Visuals.AddClothingVisual(
    replicaBody,
    "Base.Tshirt_IndieStoneDECAL",
    { decal = "SpiffoLogo" }
), true, "decal clothing visual creation")
assertEqual(visualEntries[2].decal, "SpiffoLogo",
    "clothing visual discarded its printed decal")

local now = 1000
local calls = {
    authoritativeAppearance = 0,
    authoritativeEquipment = 0,
    liveSetup = 0,
    replicaAppearance = 0,
    replicaEquipment = 0,
    replicaHands = 0,
    replicaIntegrityChecks = 0,
}
PNC = {
    Const = {
        BODY_SHELL_VERSION = 1,
        BODY_TAG_VERSION = 1,
        PRESENCE_ABSTRACT = "abstract",
        PRESENCE_LIVE = "live",
    },
    Core = {
        Now = function() return now end,
    },
    ClientPresenceSync = {
        Internal = {
            LogClientMotionDebug = function() end,
        },
    },
    LiveBodyControl = {
        MaintainHumanizedBody = function() end,
    },
    Animation = {
        ApplyLiveSetup = function()
            calls.liveSetup = calls.liveSetup + 1
        end,
    },
    Visuals = {
        ApplyResolvedAppearance = function()
            calls.authoritativeAppearance =
                calls.authoritativeAppearance + 1
        end,
        ApplyReplicaAppearance = function()
            calls.replicaAppearance =
                calls.replicaAppearance + 1
        end,
        MaintainHumanAppearance = function() end,
    },
    Equipment = {
        Apply = function()
            calls.authoritativeEquipment =
                calls.authoritativeEquipment + 1
        end,
        ApplyReplicaVisuals = function()
            calls.replicaEquipment =
                calls.replicaEquipment + 1
        end,
        ApplyReplicaHands = function()
            calls.replicaHands = calls.replicaHands + 1
        end,
        EnsureReplicaVisuals = function()
            calls.replicaIntegrityChecks =
                calls.replicaIntegrityChecks + 1
            return true
        end,
    },
}
dofile(CLIENT_VISUALS)

local function makeBody()
    local modData = {}
    return {
        getModData = function() return modData end,
        isDead = function() return false end,
        setVariable = function() end,
    }
end

local snapshot = {
    id = "replica_visual_owner",
    alive = true,
    attackMode = false,
    healthState = "normal",
    presenceRevision = 1,
    presenceState = "live",
    appearance = {
        outfitItems = { "Base.Shirt_FormalWhite" },
    },
    equipmentSummary = {
        primaryFullType = "Base.Axe",
        worn = { Shirt = "Base.Shirt_FormalWhite" },
        attached = {},
    },
    visualState = {
        anim = "Idle",
        moving = false,
    },
}
local remoteBody = makeBody()
PNC.ClientPresenceSync.Internal.ApplySnapshotToBody(
    snapshot,
    remoteBody,
    true
)
assertEqual(calls.replicaAppearance, 1,
    "remote replica appearance lane")
assertEqual(calls.replicaEquipment, 1,
    "remote replica equipment lane")
assertEqual(calls.authoritativeAppearance, 0,
    "remote replica used authoritative appearance")
assertEqual(calls.authoritativeEquipment, 0,
    "remote replica used authoritative equipment")
assertEqual(calls.liveSetup, 0,
    "remote replica used packet-owning live setup")

assertEqual(
    PNC.ClientPresenceSync.Internal.EnsureReplicaClothingSnapshot(
        snapshot,
        remoteBody
    ),
    true,
    "replica clothing integrity check"
)
assertEqual(calls.replicaIntegrityChecks, 1,
    "replica integrity check did not reach equipment")

snapshot.equipmentSummary.primaryFullType = "Base.Hammer"
PNC.ClientPresenceSync.Internal.ApplySnapshotToBody(
    snapshot,
    remoteBody,
    true
)
assertEqual(calls.replicaHands, 1,
    "remote hands update did not stay visual-only")

now = 2100
PNC.ClientPresenceSync.Internal.ApplySnapshotToBody(
    snapshot,
    remoteBody,
    true
)
assertEqual(calls.replicaAppearance, 1,
    "unchanged snapshot rebuilt replica appearance")
assertEqual(calls.replicaEquipment, 1,
    "unchanged snapshot rebuilt server-owned equipment")

local localBody = makeBody()
PNC.ClientPresenceSync.Internal.ApplySnapshotToBody(
    snapshot,
    localBody,
    false
)
assertEqual(calls.authoritativeAppearance, 1,
    "authoritative appearance lane changed")
assertEqual(calls.authoritativeEquipment, 1,
    "authoritative equipment lane changed")
assertEqual(calls.liveSetup, 1,
    "authoritative live setup changed")

local firstNestedVisualSnapshot = {
    equipmentSummary = {
        worn = { Hat = "Base.Hat_Beany" },
        wornVisuals = {
            Hat = {
                fullType = "Base.Hat_Beany",
                baseTexture = 2,
                textureChoice = 4,
                tint = { r = 0.2, g = 0.3, b = 0.4 },
            },
        },
        attached = {},
    },
}
local secondNestedVisualSnapshot = {
    equipmentSummary = {
        worn = { Hat = "Base.Hat_Beany" },
        wornVisuals = {
            Hat = {
                fullType = "Base.Hat_Beany",
                baseTexture = 2,
                textureChoice = 4,
                tint = { r = 0.2, g = 0.3, b = 0.4 },
            },
        },
        attached = {},
    },
}
local firstNestedVisualKey =
    PNC.ClientPresenceSync.Internal.BuildVisualKey(
        firstNestedVisualSnapshot
    )
assertEqual(
    PNC.ClientPresenceSync.Internal.BuildVisualKey(
        secondNestedVisualSnapshot
    ),
    firstNestedVisualKey,
    "equivalent decoded visual tables changed the presentation key"
)
snapshot.equipmentSummary.wornVisuals =
    firstNestedVisualSnapshot.equipmentSummary.wornVisuals
PNC.ClientPresenceSync.Internal.ApplySnapshotToBody(
    snapshot,
    localBody,
    false
)
assertEqual(calls.authoritativeEquipment, 2,
    "first persisted worn visual was not applied")
snapshot.equipmentSummary.wornVisuals =
    secondNestedVisualSnapshot.equipmentSummary.wornVisuals
PNC.ClientPresenceSync.Internal.ApplySnapshotToBody(
    snapshot,
    localBody,
    false
)
assertEqual(calls.authoritativeEquipment, 2,
    "single-player rebuilt equivalent decoded item visuals")
secondNestedVisualSnapshot.equipmentSummary
    .wornVisuals.Hat.tint.g = 0.8
if PNC.ClientPresenceSync.Internal.BuildVisualKey(
    secondNestedVisualSnapshot
) == firstNestedVisualKey then
    error("real nested tint change did not invalidate presentation")
end

print("pnc_mp_replica_visual_ownership_smoke: ok")
