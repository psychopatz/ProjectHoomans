local ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

local function assertNear(actual, expected, label)
    if math.abs((tonumber(actual) or 0) - expected) > 0.000001 then
        error((label or "assertNear") .. ": expected=" .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

local now = 10000
local currentWorldHour = 100
local randomValues = {}
local records = {}
local bodies = {}
local broadcasts = 0
local corpseReason

ZombRand = function(maximum)
    local value = table.remove(randomValues, 1) or 0
    return value % maximum
end
getGameTime = function()
    return { getWorldAgeHours = function() return currentWorldHour end }
end

PNC = {
    Const = {
        DEFAULT_HP_MAX = 100,
        DEFAULT_ENGINE_BUFFER = 1000,
        INCAPACITATED_ENGINE_BUFFER = 1000,
        INCAPACITATED_HP = 1,
        INCAPACITATED_GRACE_MS = 1500,
        RECENT_DAMAGE_SHOW_MS = 4000,
        DEBUG_COMBAT_HOLD_MS = 2500,
        REVIVE_HP = 10,
        REVIVE_PROTECTION_MS = 3000,
        WOUND_BLEED_UPDATE_MS = 1000,
        WOUND_DIRTY_FLUSH_MS = 5000,
        BANDAGE_TYPE = "Base.Bandage",
        BANDAGE_RANGE = 3,
        PRESENCE_CORPSE = "corpse",
    },
    Core = {
        Now = function() return now end,
        IsAuthority = function() return true end,
        Clamp = function(value, minimum, maximum)
            return math.max(minimum, math.min(maximum, value))
        end,
        DistanceSq = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return dx * dx + dy * dy
        end,
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local output = {}
            for key, item in pairs(value) do output[key] = PNC.Core.DeepCopy(item) end
            return output
        end,
    },
    Registry = {
        Get = function(id) return records[tostring(id)] end,
        GetLiveZombie = function(id) return bodies[tostring(id)] end,
        MarkDirty = function() end,
    },
    BodyLifecycle = {
        CreateInertCorpse = function(_, _, reason) corpseReason = reason end,
    },
    Network = {
        BroadcastRecord = function() broadcasts = broadcasts + 1 end,
        BroadcastRemoval = function() end,
    },
}

dofile(ROOT .. "Base/PNC_Sandbox.lua")
dofile(ROOT .. "Health/PNC_Health.lua")
dofile(ROOT .. "Health/PNC_NPCWounds.lua")
dofile(ROOT .. "Health/PNC_Treatment.lua")
dofile(ROOT .. "API/PNC_API.lua")

SandboxVars = {
    ProjectHoomans = {
        NPCZombieWoundChance = 100,
        NPCZombieBiteChance = 100,
        NPCZombieLacerationChance = 0,
        NPCZombieInfectionChance = 100,
        NPCInfectionMortalityHours = 48,
        NPCReanimationHours = 1,
    },
}

BodyPartType = {
    Head = { index = function() return 0 end },
    Neck = { index = function() return 1 end },
    Torso_Upper = { index = function() return 2 end },
    Torso_Lower = { index = function() return 3 end },
    Groin = { index = function() return 4 end },
    UpperArm_L = { index = function() return 5 end }, UpperArm_R = { index = function() return 6 end },
    ForeArm_L = { index = function() return 7 end }, ForeArm_R = { index = function() return 8 end },
    Hand_L = { index = function() return 9 end }, Hand_R = { index = function() return 10 end },
    UpperLeg_L = { index = function() return 11 end }, UpperLeg_R = { index = function() return 12 end },
    LowerLeg_L = { index = function() return 13 end }, LowerLeg_R = { index = function() return 14 end },
    Foot_L = { index = function() return 15 end }, Foot_R = { index = function() return 16 end },
}

local function makeRecord(id)
    return {
        id = id,
        alive = true,
        x = 0, y = 0, z = 0,
        presenceState = "live",
        runtime = {},
        health = { current = 100, max = 100, state = "normal" },
    }
end

local protection = 0
local body = {
    getX = function() return 0 end, getY = function() return 0 end, getZ = function() return 0 end,
    getBodyPartClothingDefense = function() return protection end,
    setUseless = function() end, setHealth = function() end, setZombiesDontAttack = function() end,
}
local attacker = {
    getX = function() return 1 end, getY = function() return 0 end, getZ = function() return 0 end,
}

local record = makeRecord("wounded")
records[record.id] = record
bodies[record.id] = body
randomValues = { 0, 0, 0 }
local applied, result = PNC.NPCWounds.ResolveZombieAttack(record, body, attacker)
assertEqual(applied, true, "unarmored wound")
assertEqual(result.woundType, "bite", "bite roll")
assertNear(record.health.current, 88, "bite initial damage")
assertEqual(PNC.NPCWounds.HasActiveInfection(record), true, "bite infection")
assertEqual(record.health.body.openWoundCount, 1, "open wound count")

local wound = record.health.body.wounds[result.partId]
assert(wound and wound.bandaged == false, "wound was not recorded")
assertNear(record.health.body.overallPercent, 88, "body-part aggregate health")
assertNear(record.health.body.parts[result.partId].current, 76, "wounded part takes focused damage")
local woundSnapshot = PNC.NPCWounds.BuildSnapshot(record)
assertNear(woundSnapshot.overallPercent, 88, "snapshot aggregate health")
assertEqual(woundSnapshot.totalPartMax, 1700, "snapshot total body-part maximum")

local removed = 0
local item = {}
local container = { Remove = function() removed = removed + 1 end }
function item:getContainer() return container end
local list = { size = function() return 1 end, get = function() return item end }
local inventory = {
    getAllTypeRecurse = function() return list end,
    getItemCount = function() return 1 end,
}
local player = {
    getInventory = function() return inventory end,
    getX = function() return 0 end, getY = function() return 0 end, getZ = function() return 0 end,
    isDead = function() return false end,
}
local success, reason = PNC.Treatment.TryBandage(player, record.id, result.partId)
assertEqual(success, true, "bandage action")
assertEqual(reason, "bandaged", "bandage reason")
assertEqual(removed, 1, "bandage consumed")
assertEqual(record.health.body.openWoundCount, 0, "bleeding controlled")
assertEqual(record.health.body.bandagedWoundCount, 1, "bandaged count")
assertEqual(broadcasts, 1, "bandage broadcast")
assertEqual(PNC.NPCWounds.HasActiveInfection(record), true, "bandage does not cure Knox infection")

local debugRecord = makeRecord("debug_bandage")
records[debugRecord.id] = debugRecord
bodies[debugRecord.id] = body
protection = 0
randomValues = { 0, 0, 0 }
applied, result = PNC.NPCWounds.ResolveZombieAttack(debugRecord, body, attacker)
assertEqual(applied, true, "debug bandage wound")
local removedBeforeDebug = removed
success, reason = PNC.Treatment.TryBandage(player, debugRecord.id, result.partId, { consumeItem = false })
assertEqual(success, true, "debug bandage action")
assertEqual(reason, "bandaged_debug", "debug bandage reason")
assertEqual(removed, removedBeforeDebug, "debug bandage consumes no item")

local specificDebug = makeRecord("debug_specific_wound")
records[specificDebug.id] = specificDebug
bodies[specificDebug.id] = body
applied, result = PNC.API.DebugCommand(specificDebug.id, "damage_part", {
    partId = "Hand_R",
    woundType = "laceration",
})
assertEqual(applied, true, "specific debug wound applied")
assertEqual(result.partId, "Hand_R", "specific debug wound part")
assertEqual(result.woundType, "laceration", "specific debug wound type")
assertNear(specificDebug.health.current, 92, "specific debug wound damage")
assertEqual(specificDebug.health.body.wounds.Hand_R.bandaged, false, "specific debug wound can be bandaged")

local randomDebug = makeRecord("debug_random_wound")
randomValues = { 0, 2 }
applied, result = PNC.NPCWounds.ApplyDebugWound(randomDebug, body)
assertEqual(applied, true, "random debug wound applied")
assertEqual(result.partId, "Head", "random debug wound part")
assertEqual(result.woundType, "bite", "random debug wound type")

local protected = makeRecord("protected")
protection = 100
randomValues = { 0, 0 }
applied, result = PNC.NPCWounds.ResolveZombieAttack(protected, body, attacker)
assertEqual(applied, false, "full protection parry")
assertEqual(result.outcome, "parried", "parry outcome")
assertEqual(protected.health.current, 100, "parry health")

protection = 0
SandboxVars.ProjectHoomans.NPCZombieInfectionChance = 0
local safeBite = makeRecord("safe_bite")
randomValues = { 0, 0, 0 }
applied, result = PNC.NPCWounds.ResolveZombieAttack(safeBite, body, attacker)
assertEqual(applied, true, "bite with infection disabled")
assertEqual(result.woundType, "bite", "disabled infection still permits bites")
assertEqual(PNC.NPCWounds.HasActiveInfection(safeBite), false, "zero infection chance")

SandboxVars.ProjectHoomans.NPCZombieInfectionChance = 50
local failedInfectionRoll = makeRecord("failed_infection_roll")
randomValues = { 0, 0, 0, 6000 }
applied, result = PNC.NPCWounds.ResolveZombieAttack(failedInfectionRoll, body, attacker)
assertEqual(applied, true, "infection roll leaves bite wound intact")
assertEqual(result.woundType, "bite", "infection roll changed bite outcome")
assertEqual(PNC.NPCWounds.HasActiveInfection(failedInfectionRoll), false,
    "infection chance roll was not independent")

SandboxVars.ProjectHoomans.NPCZombieInfectionChance = 0
local forcedInfection = makeRecord("forced_infection")
records[forcedInfection.id] = forcedInfection
bodies[forcedInfection.id] = body
applied, result = PNC.API.DebugCommand(forcedInfection.id, "infection", {
    partId = "Neck",
    stage = "fever",
})
assertEqual(applied, true, "debug infection bypasses sandbox roll")
assertEqual(forcedInfection.health.body.infection.sourcePart, "Neck", "debug infection part")
assertEqual(forcedInfection.health.body.infection.stage, "fever", "debug fever stage")
assert(forcedInfection.health.body.infection.temperatureC > 38, "debug fever temperature missing")
assert(forcedInfection.health.current < 88, "fever did not progressively lower health")

local fatalDebug = makeRecord("fatal_debug_infection")
records[fatalDebug.id] = fatalDebug
bodies[fatalDebug.id] = body
applied, result = PNC.API.DebugCommand(fatalDebug.id, "infection", {
    partId = "Torso_Upper",
    stage = "fatal",
})
assertEqual(applied, true, "debug fatal infection")
assertEqual(fatalDebug.alive, false, "debug infection death")
assertEqual(fatalDebug.health.body.infection.stage, "fatal", "debug fatal stage")
assertEqual(fatalDebug.health.body.infection.reanimateAtWorldHour, 101,
    "debug fatal reanimation schedule")

SandboxVars.ProjectHoomans.NPCZombieBiteChance = 0
SandboxVars.ProjectHoomans.NPCZombieLacerationChance = 100
local bleeding = makeRecord("bleeding")
randomValues = { 0, 0, 0 }
applied = PNC.NPCWounds.ResolveZombieAttack(bleeding, body, attacker)
assertEqual(applied, true, "bleeding wound")
PNC.NPCWounds.SetOverallHealth(bleeding, 0.01)
bleeding.health.body.lastBleedAt = now
now = now + 1000
PNC.Health.Update(bleeding, body, now)
assertEqual(bleeding.alive, true, "ordinary blood loss remains revivable")
assertEqual(bleeding.health.state, "incapacitated", "blood loss enters incapacitation")
assertEqual(bleeding.health.incapacitatedReason, "blood_loss", "blood loss reason")

SandboxVars.ProjectHoomans.NPCZombieInfectionChance = 100
currentWorldHour = 140
local healthBeforeFever = record.health.current
PNC.Health.Update(record, body, now + 500)
assertEqual(record.health.body.infection.stage, "fever", "infection fever progression")
assert(record.health.body.infection.temperatureC > 38, "infection fever temperature")
assert(record.health.current < healthBeforeFever, "infection health decline")
currentWorldHour = 148
PNC.Health.Update(record, body, now + 1000)
assertEqual(record.alive, false, "terminal infection kills")
assertEqual(record.health.state, "dead", "terminal infection state")
assertEqual(record.health.body.infection.fatal, true, "fatal infection marker")
assertEqual(record.health.body.infection.reanimateAtWorldHour, 149, "reanimation schedule")
assertEqual(corpseReason, "zombie_infection", "infection corpse reason")

currentWorldHour = 200
local pending = makeRecord("pending_infection")
SandboxVars.ProjectHoomans.NPCZombieBiteChance = 100
SandboxVars.ProjectHoomans.NPCZombieLacerationChance = 0
randomValues = { 0, 0, 0 }
PNC.NPCWounds.ResolveZombieAttack(pending, body, attacker)
currentWorldHour = 248
PNC.Health.Update(pending, nil, now + 2000)
assertEqual(pending.alive, true, "abstract infection waits for a body")
assertEqual(pending.health.body.infection.pendingFatal, true, "pending fatal infection")
PNC.Health.Update(pending, body, now + 3000)
assertEqual(pending.alive, false, "pending infection kills after materialization")

print("pnc_npc_wounds_smoke: ok")
