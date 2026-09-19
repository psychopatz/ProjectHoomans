local T = require "tests/support/test"

local records = { npc_1 = { id = "npc_1", alive = true } }
local authority = false
local healthCalls = 0
local debugWoundCalls = 0
local debugInfectionCalls = 0
local broadcasts = 0

PNC = {
    Core = {
        IsAuthority = function() return authority end,
    },
    Registry = {
        Get = function(id) return records[id] end,
        GetLiveZombie = function() return {} end,
    },
    Health = {
        ApplyDamage = function()
            healthCalls = healthCalls + 1
            return true
        end,
    },
    NPCWounds = {
        ApplyDebugWound = function()
            debugWoundCalls = debugWoundCalls + 1
            return true
        end,
        ApplyDebugInfection = function()
            debugInfectionCalls = debugInfectionCalls + 1
            return true
        end,
    },
    Network = {
        BroadcastRecord = function() broadcasts = broadcasts + 1 end,
        BroadcastRemoval = function() broadcasts = broadcasts + 1 end,
    },
}

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/API/PNC_API/HealthSnapshots.lua"
)

local applied, reason = PNC.API.ApplyDamage("npc_1", { amount = 10 })
T.equal(applied, false, "client cannot apply damage through the public API")
T.equal(reason, "not_authority", "API reports an authority rejection")
T.equal(healthCalls, 0, "non-authority request does not reach health state")
T.equal(broadcasts, 0, "non-authority request does not broadcast")
applied, reason = PNC.API.ApplyDebugWound("npc_1", {})
T.equal(applied, false, "client cannot request a debug wound")
T.equal(reason, "not_authority", "debug wound reports authority rejection")
applied, reason = PNC.API.ApplyDebugInfection("npc_1", {})
T.equal(applied, false, "client cannot request debug infection")
T.equal(reason, "not_authority", "debug infection reports authority rejection")
T.equal(debugWoundCalls, 0, "client debug wound does not reach wound mutation")
T.equal(debugInfectionCalls, 0,
    "client debug infection does not reach infection mutation")

authority = true
PNC.Health.ApplyDamage = function()
    healthCalls = healthCalls + 1
    return false
end
applied, reason = PNC.API.ApplyDamage("npc_1", { amount = 10 })
T.equal(applied, false, "rejected damage is not reported as applied")
T.equal(reason, "damage_rejected", "API returns the health rejection reason")
T.equal(broadcasts, 0, "rejected damage does not broadcast")

PNC.Health.ApplyDamage = function()
    healthCalls = healthCalls + 1
    return true
end
applied = PNC.API.ApplyDamage("npc_1", { amount = 10 })
T.equal(applied, true, "authoritative damage is applied")
T.equal(broadcasts, 1, "accepted damage broadcasts once")

print("pnc_health_api_authority_smoke: PASS")
