local T = require "tests/support/test"
T.addPackagePaths()

local authority = true
local now = 1000
PNC = {
    Core = {
        IsAuthority = function() return authority end,
        Now = function() return now end,
    },
    VisualProfiles = {
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
local humanVisual = {
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

return T.finish("pnc_mp_human_visual_repair_smoke")
