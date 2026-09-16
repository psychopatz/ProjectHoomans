local T = require "tests/support/test"

local OBSERVERS_FILE = T.path(
    "ProjectHoomans",
    "server",
    "PNC/Compatibility/Mods/Necroa/PNC_Necroa_ExposureServer_Observers.lua"
)

local worldHour = 12
local hasMask = false
local emitted = {}
local presented = 0
local observerRecord = { id = "npc-warning", alive = true }
local observerBody = {
    getX = function() return 10 end,
    getY = function() return 10 end,
    getZ = function() return 0 end,
}
local player = {
    getOnlineID = function() return 7 end,
    getX = function() return 10 end,
    getY = function() return 10 end,
    getZ = function() return 0 end,
}

getTimeInMillis = function() return worldHour * 3600000 end
getGameTime = function()
    return {
        getWorldAgeHours = function() return worldHour end,
    }
end

PNC = {
    Compatibility = {
        Necroa = {
            Mask = {
                HasMask = function() return hasMask end,
            },
        },
    },
    EntityRef = {
        ForNPC = function(id) return "npc:" .. tostring(id) end,
    },
    Network = {
        SendConversationRelationshipForNPC = function()
            presented = presented + 1
        end,
    },
    Registry = {
        ForEachLive = function(callback)
            callback(observerRecord, observerBody)
        end,
    },
    SocialEventHooks = {
        ResolvePlayerKey = function()
            return "player:7"
        end,
    },
    SocialEvents = {
        Emit = function(event)
            emitted[#emitted + 1] = event
            return {
                ok = true,
                eventID = event.id,
                details = {},
            }
        end,
    },
    VanillaEmoteInteractions = {
        ResolveNPCType = function() return "colonist" end,
    },
}

local Observers = T.load(OBSERVERS_FILE)
local Exposure = {
    RADIUS = 14,
    State = {
        npcMask = {},
        playerMask = {},
        playerWarningAt = {},
    },
}

Observers.Player(Exposure, player)
T.equal(#emitted, 1, "unmasked player received an initial warning")
T.equal(presented, 1, "initial warning was presented once")

Observers.Player(Exposure, player)
worldHour = 12.5
Observers.Player(Exposure, player)
T.equal(#emitted, 1, "repeated ticks do not flood the warning")

worldHour = 13
Observers.Player(Exposure, player)
T.equal(#emitted, 2, "warning repeats after one in-game hour")

hasMask = true
Observers.Player(Exposure, player)
worldHour = 13.5
hasMask = false
Observers.Player(Exposure, player)
T.equal(#emitted, 2, "mask removal inside the same hour stays throttled")

worldHour = 14
Observers.Player(Exposure, player)
T.equal(#emitted, 3, "warning resumes in the next game hour")

T.finish("pnc_necroa_player_warning_throttle_smoke")
