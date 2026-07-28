local FILE = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/"
    .. "Presence/PNC_PresenceAdmission.lua"

local live = {}
local player = {
    getX = function() return 0 end,
    getY = function() return 0 end,
}

PNC = {
    Const = {
        MATERIALIZE_DISTANCE = 28,
        LIVE_BODY_MAX_GLOBAL = 4,
        LIVE_BODY_MAX_PER_PLAYER = 2,
    },
    Core = {
        DistanceSq = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return dx * dx + dy * dy
        end,
        LogWarn = function() end,
    },
    Registry = {
        ForEachLive = function(callback)
            for i = 1, #live do callback(live[i]) end
        end,
    },
}

dofile(FILE)

local candidate = { id = "candidate", x = 1, y = 1 }
local nearest = { player = player, distSq = 2 }
assert(PNC.PresenceAdmission.Evaluate(candidate, nearest),
    "empty live-body budget rejected a candidate")

live[1] = { id = "near:1", x = 1, y = 0 }
live[2] = { id = "near:2", x = 2, y = 0 }
local allowed, reason = PNC.PresenceAdmission.Evaluate(candidate, nearest)
assert(allowed == false and reason == "player_live_body_cap",
    "per-player live-body cap was not enforced")

live[2] = { id = "far:2", x = 100, y = 100 }
assert(PNC.PresenceAdmission.Evaluate(candidate, nearest),
    "far live bodies incorrectly consumed the per-player cap")
live[3] = { id = "far:3", x = 110, y = 100 }
live[4] = { id = "far:4", x = 120, y = 100 }
allowed, reason = PNC.PresenceAdmission.Evaluate(candidate, nearest)
assert(allowed == false and reason == "global_live_body_cap",
    "global live-body cap was not enforced")

live = {}
assert(PNC.PresenceAdmission.RegisterRule("threat_fixture",
    function(record)
        if record.blockedByThreat then
            return false, "threat_blocked"
        end
        return true
    end
))
candidate.blockedByThreat = true
allowed, reason = PNC.PresenceAdmission.Evaluate(candidate, nearest)
assert(allowed == false and reason == "threat_blocked",
    "custom admission rule was not applied")
assert(PNC.PresenceAdmission.UnregisterRule("threat_fixture"),
    "custom admission rule was not removable")

print("pnc_presence_admission_smoke: ok")
