local T = require "tests/support/test"
T.addPackagePaths()

local authority = true
local now = 1000
PNC = {
    Core = {
        IsAuthority = function() return authority end,
        Now = function() return now end,
    },
    Identity = {
        RollAppearance = function()
            return {
                skinTexture = "MaleBody01",
                hairModel = "Short",
                beardModel = "Goatee",
            }
        end,
    },
}

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Visuals/PNC_Visuals.lua"
)

-- Networked server/host authority must use the full resolved lane. Only a pure
-- client replica may use the non-owning replica appearance lane.
local calls = {
    resolved = 0,
    replica = 0,
}
PNC.Visuals.ApplyResolvedAppearance = function()
    calls.resolved = calls.resolved + 1
end
PNC.Visuals.ApplyReplicaAppearance = function()
    calls.replica = calls.replica + 1
end

local record = {
    id = "npc_visual_authority",
    isFemale = false,
}
PNC.Visuals.ApplyHumanVisuals({}, record)
T.equal(calls.resolved, 1,
    "server/SP authority used replica appearance")
T.equal(calls.replica, 0,
    "server/SP authority entered client replica lane")

authority = false
PNC.Visuals.ApplyHumanVisuals({}, record)
T.equal(calls.resolved, 1,
    "pure client used authoritative appearance")
T.equal(calls.replica, 1,
    "pure client did not use replica appearance")

-- Restore only the helper used by drift repair. The repair path must never
-- touch worn/attached clothing; it owns human identity fields only.
local skin = "ZombieRot03"
local hair = "Messy"
local beard = "FullBeard"
local female = false
local modelRefreshes = 0
local noTeeth = false
local bodyVisuals = { ["Base.Tattoo"] = true }
local humanVisual = {
    hasBodyVisualFromItemType = function(_, item) return bodyVisuals[item] == true end,
    addBodyVisualFromItemType = function(_, item) bodyVisuals[item] = true end,
    removeBodyVisualFromItemType = function(_, item) bodyVisuals[item] = nil end,
    removeDirt = function() end,
    removeBlood = function() end,
    getSkinTexture = function() return skin end,
    setSkinTextureName = function(_, value) skin = value end,
    getHairModel = function() return hair end,
    setHairModel = function(_, value) hair = value end,
    getBeardModel = function() return beard end,
    setBeardModel = function(_, value) beard = value end,
}
local body = {
    isFemale = function() return female end,
    setFemaleEtc = function(_, value) female = value == true end,
    setNoTeeth = function(_, value) noTeeth = value == true end,
    getHumanVisual = function() return humanVisual end,
    getWornItems = function()
        error("human identity repair touched worn items")
    end,
    getAttachedItems = function()
        error("human identity repair touched attached items")
    end,
    getItemVisuals = function()
        error("human identity repair touched item visuals")
    end,
    dressInNamedOutfit = function()
        error("human identity repair dressed clothing")
    end,
    resetModelNextFrame = function()
        modelRefreshes = modelRefreshes + 1
    end,
    resetModel = function()
        modelRefreshes = modelRefreshes + 1
    end,
}
local desired = {
    hairStubble = true,
    beardStubble = true,
    skinTexture = "MaleBody01",
    hairModel = "Short",
    beardModel = "Goatee",
}

local repaired, reason =
    PNC.Visuals.RepairReplicaHumanAppearance(
        body,
        desired,
        false,
        now
    )
T.equal(repaired, true,
    "zombie-looking replica was not repaired")
T.equal(reason, "repaired", "visual repair reason")
T.equal(skin, "MaleBody01", "survivor skin was not restored")
T.equal(hair, "Short", "survivor hair was not restored")
T.equal(beard, "Goatee", "survivor beard was not restored")
T.truthy(bodyVisuals["Base.M_Hair_Stubble"], "replica receives male scalp stubble")
T.truthy(bodyVisuals["Base.M_Beard_Stubble"], "replica receives beard stubble")
T.truthy(bodyVisuals["Base.Tattoo"], "stubble repair keeps unrelated body visuals")
T.truthy(noTeeth, "humanized replica regained zombie teeth")
T.truthy(modelRefreshes > 0,
    "visual repair did not refresh the rendered model")

local refreshAfterRepair = modelRefreshes
now = 1100
repaired, reason =
    PNC.Visuals.RepairReplicaHumanAppearance(
        body,
        desired,
        false,
        now
    )
T.equal(repaired, false, "visual integrity check ignored throttle")
T.equal(reason, "throttled", "visual throttle reason")
T.equal(modelRefreshes, refreshAfterRepair,
    "throttled visual check refreshed model")

now = 1300
repaired, reason =
    PNC.Visuals.RepairReplicaHumanAppearance(
        body,
        desired,
        false,
        now
    )
T.equal(repaired, false,
    "unchanged human appearance rebuilt the model")
T.equal(reason, "current", "current appearance reason")
T.equal(modelRefreshes, refreshAfterRepair,
    "current human appearance refreshed model")

-- Simulate a later native zombie replication packet overwriting HumanVisual.
skin = "ZombieRot02"
now = 1600
repaired, reason =
    PNC.Visuals.RepairReplicaHumanAppearance(
        body,
        desired,
        false,
        now
    )
T.equal(repaired, true,
    "post-bind zombie skin overwrite was not repaired")
T.equal(skin, "MaleBody01",
    "post-bind repair did not restore survivor skin")
T.truthy(modelRefreshes > refreshAfterRepair,
    "post-bind drift repair did not refresh model")

PNC.Visuals.MaintainHumanAppearance(body, desired, true, false)
T.truthy(bodyVisuals["Base.F_Hair_Stubble"], "female actor receives female scalp stubble")
T.falsy(bodyVisuals["Base.M_Hair_Stubble"], "body change removes mismatched scalp stubble")
T.falsy(bodyVisuals["Base.M_Beard_Stubble"], "female actor omits beard stubble")
PNC.Visuals.MaintainHumanAppearance(body, { hairStubble = false }, true, false)
T.falsy(bodyVisuals["Base.F_Hair_Stubble"], "shaving clears the existing overlay")
T.truthy(bodyVisuals["Base.Tattoo"], "shaving keeps unrelated body visuals")

PNC.Visuals.MaintainHumanAppearance(body, { skinTexture = "MaleBody04", chestHair = true }, false, false)
T.equal(skin, "MaleBody04a", "IsoZombie chest hair uses the matching vanilla hairy texture")
T.truthy(PNC.Visuals.ReplicaHumanAppearanceMatches(body, { skinTexture = "MaleBody04", chestHair = true }, false))
PNC.Visuals.MaintainHumanAppearance(body, { skinTexture = "MaleBody04a", chestHair = false }, false, false)
T.equal(skin, "MaleBody04", "disabling chest hair restores the shaved texture of the same tone")

return T.finish("pnc_mp_human_visual_repair_smoke")
