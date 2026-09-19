local T = require "tests/support/test"

PNC = {
    Core = {
        IsAuthority = function() return true end,
        Clamp = function(value, minimum, maximum)
            return math.max(minimum, math.min(maximum, value))
        end,
        Now = function() return 0 end,
    },
    Const = { DEFAULT_HP_MAX = 100 },
    Sandbox = {
        NPCZombieInfectionChance = function() return 100 end,
        NPCInfectionMortalityHours = function() return 48 end,
    },
    Registry = { MarkDirty = function() end },
    NPCWounds = {
        Internal = {},
        PartOrder = { "Head", "Torso_Upper" },
        Parts = {
            Head = { id = "Head" },
            Torso_Upper = { id = "Torso_Upper" },
        },
    },
}

local worldHour = 0
getGameTime = function()
    return { getWorldAgeHours = function() return worldHour end }
end
PNC.NPCWounds.Internal.WorldHour = function() return worldHour end

PNC.Health = {
    Ensure = function(record)
        record.health = record.health or {
            current = 100, max = 100, state = "normal",
        }
        return record.health
    end,
    ApplyDamage = function(record, _, event)
        PNC.NPCWounds.ApplyBodyDamage(record, event.amount)
        return true
    end,
}

local root = T.path("ProjectHoomans", "root", "")
T.load(root .. "shared/PNC/Core/Needs/PNC_NeedsDefinitions.lua")
T.load(root .. "shared/PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_BodyState.lua")
T.load(root .. "shared/PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_WholeBody.lua")
T.load(root .. "shared/PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Infection.lua")
T.load(root .. "shared/PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Diagnostics.lua")
T.load(root .. "shared/PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Debug.lua")

local infectionDebugMessages = {}
PNC.Core.IsRecordDebugEnabled = function(record)
    return record and record.runtime and record.runtime.debug == true
end
PNC.Core.LogRecordDebug = function(_, message)
    infectionDebugMessages[#infectionDebugMessages + 1] = message
end

local function makeRecord()
    return {
        id = "infection_test",
        alive = true,
        runtime = {},
        health = {
            current = 100,
            max = 100,
            state = "normal",
            body = {
                parts = {
                    Head = { current = 100, max = 100 },
                    Torso_Upper = { current = 100, max = 100 },
                },
                wounds = {},
            },
        },
    }
end

local unauthorized = makeRecord()
unauthorized.runtime.debug = true
PNC.Core.IsAuthority = nil
local accepted, reason = PNC.NPCWounds.ForceInfection(
    unauthorized, "Head"
)
T.equal(accepted, false, "infection mutation fails closed without authority")
T.equal(reason, "not_authority", "missing authority reason")
T.contains(infectionDebugMessages[#infectionDebugMessages],
    "health.infection event=force")
T.contains(infectionDebugMessages[#infectionDebugMessages],
    "status=rejected reason=not_authority")
T.equal(unauthorized.health.body.infection, nil,
    "missing authority leaves infection state unchanged")
accepted, reason = PNC.NPCWounds.ApplyDebugWound(
    unauthorized, nil, "Head", "bite"
)
T.equal(accepted, false, "debug wound fails closed without authority")
T.equal(reason.outcome, "not_authority", "debug wound authority result")
accepted, reason = PNC.NPCWounds.ApplyDebugInfection(
    unauthorized, nil, "Head", "fever"
)
T.equal(accepted, false, "debug infection fails closed without authority")
T.equal(reason, "not_authority", "debug infection authority result")

PNC.Core.IsAuthority = function() return false end
unauthorized.health.body.infection = { active = true, progress = 0 }
accepted, reason = PNC.NPCWounds.Internal.RefreshInfectionState(
    unauthorized, 24, true
)
T.equal(accepted, false, "client cannot advance infection state")
T.equal(reason, "not_authority", "progression authority reason")
T.equal(unauthorized.health.body.infection.progress, 0,
    "client progression leaves stored state unchanged")
accepted, reason = PNC.NPCWounds.ClearInfection(unauthorized)
T.equal(accepted, false, "client cannot clear infection")
T.equal(reason, "not_authority", "clear authority reason")
T.truthy(unauthorized.health.body.infection.active,
    "client clear leaves infection active")
accepted, reason = PNC.NPCWounds.PrepareInfectionDeath(unauthorized)
T.equal(accepted, false, "client cannot prepare infection death")
T.equal(reason, "not_authority", "death preparation authority reason")
T.truthy(unauthorized.health.body.infection.active,
    "client death preparation leaves infection active")
accepted, reason = PNC.NPCWounds.TriggerInfectionDeath(unauthorized, nil)
T.equal(accepted, false, "client cannot trigger infection death")
T.equal(reason, "not_authority", "death trigger authority reason")
T.truthy(unauthorized.health.body.infection.active,
    "client death trigger leaves infection active")

PNC.Core.IsAuthority = function() return true end

local record = makeRecord()
record.runtime.debug = true
PNC.NPCWounds.SyncOverallHealth(record)
T.equal(record.health.body.totalPartHealth, 200,
    "whole-body hitpoints are the sum of limb hitpoints")
T.equal(record.health.body.totalPartMax, 200,
    "whole-body maximum is the sum of limb maxima")
T.truthy(PNC.NPCWounds.ForceInfection(record, "Head"),
    "Knox infection can be applied")
T.contains(infectionDebugMessages[#infectionDebugMessages],
    "health.infection event=apply")
T.contains(infectionDebugMessages[#infectionDebugMessages],
    "status=applied reason=infected")
T.equal(PNC.NPCWounds.WholeBody.IsCurable("knox_fever"), false,
    "Knox fever is the incurable fever class")

worldHour = 43.2
PNC.NPCWounds.Internal.RefreshInfectionState(record, worldHour, false)
T.near(record.health.current, 100, 0.000001,
    "fever buildup does not overwrite or damage whole-body HP early")
T.near(record.health.body.wholeBodyAilments.knox_fever.severity,
    1, 0.000001, "Knox fever reaches full severity before damage")
T.contains(infectionDebugMessages[#infectionDebugMessages],
    "health.infection event=stage_transition")
T.contains(infectionDebugMessages[#infectionDebugMessages], "stage=terminal")

worldHour = 44.2
PNC.NPCWounds.Internal.RefreshInfectionState(record, worldHour, true)
T.truthy(record.health.current < 100 and record.health.current > 0,
    "full Knox fever applies incremental whole-body damage")
local healthyDamage = 100 - record.health.current

local injured = makeRecord()
worldHour = 0
T.truthy(PNC.NPCWounds.ForceInfection(injured, "Head"),
    "second Knox infection can be applied")
PNC.NPCWounds.ApplyBodyDamage(injured, 70)
T.near(injured.health.current, 30, 0.000001,
    "pre-existing limb damage lowers aggregate body HP")
worldHour = 43.2
PNC.NPCWounds.Internal.RefreshInfectionState(injured, worldHour, false)
T.near(injured.health.current, 30, 0.000001,
    "Knox fever does not reset existing injuries")
worldHour = 44.2
PNC.NPCWounds.Internal.RefreshInfectionState(injured, worldHour, true)
T.near(30 - injured.health.current, healthyDamage, 0.000001,
    "Knox damage uses the same aggregate body scale for injured NPCs")
T.truthy(injured.health.current < record.health.current,
    "an already injured NPC succumbs faster")

local body = injured.health.body
body.wounds.Head = {
    partId = "Head", bandaged = false, bleedingRate = 0.05,
}
PNC.NPCWounds.Recalculate(injured)
T.truthy(body.wholeBodyAilments.blood_loss.active == true,
    "unbandaged bleeding adds a whole-body flavor marker")
T.equal(body.wholeBodyAilments.blood_loss.severity, nil,
    "blood-loss flavor marker has no percentage")
body.wounds.Head.bandaged = true
PNC.NPCWounds.Recalculate(injured)
T.equal(body.wholeBodyAilments.blood_loss, nil,
    "bandaging removes the derived blood-loss marker")

T.truthy(PNC.NPCWounds.ClearInfection(injured),
    "debug/admin infection clear still works")
T.equal(body.wholeBodyAilments.knox_fever, nil,
    "clearing Knox infection removes its Whole Body fever")

T.finish("pnc_whole_body_infection_smoke")
