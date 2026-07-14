local ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

local variables = {}
local crawler = false
local onFloor = false
local fallOnFront = false

PNC = {
    Core = { Now = function() return 1000 end },
    LiveBodyControl = {
        SyncLocomotionState = function()
            error("generic locomotion sync ran for an incapacitated body")
        end,
    },
    LocomotionProfiles = {
        GetBaseProfile = function(mode)
            return {
                moveAnim = mode == "crawl" and "Crawl" or "Walk",
                walkType = mode == "crawl" and "Crawl" or "Walk",
                engineWalkType = "",
                animSpeed = 0.72,
                isRunning = false,
                isCrawling = mode == "crawl",
            }
        end,
    },
}

dofile(ROOT .. "Visuals/PNC_Animation.lua")

local zombie = {
    setVariable = function(_, key, value) variables[key] = value end,
    setCrawler = function(_, value) crawler = value == true end,
    setOnFloor = function(_, value) onFloor = value == true end,
    setFallOnFront = function(_, value) fallOnFront = value == true end,
    setCanWalk = function() end,
    setRunning = function() end,
    setUseless = function() end,
    setWalkType = function() end,
    setSpeedMod = function() end,
    setAnimatingBackwards = function() end,
}

local stationary = {
    health = { state = "incapacitated" },
    runtime = { pathing = { phase = "idle", mode = "walk", visualMovingUntil = 0 } },
    activeBehavior = "Incapacitated",
}

PNC.Animation.SyncLocomotion(zombie, stationary)
assertEqual(crawler, true, "stationary incapacitated crawler flag")
assertEqual(onFloor, true, "stationary incapacitated floor flag")
assertEqual(fallOnFront, true, "stationary incapacitated front flag")
assertEqual(variables.bCrawling, true, "stationary incapacitated animation crawler variable")
assertEqual(variables.PNCAnim, "Downed", "stationary incapacitated animation")
assertEqual(variables.bMoving, false, "stationary incapacitated movement variable")

variables = {}
crawler = false
onFloor = false
fallOnFront = false
local moving = {
    health = { state = "incapacitated" },
    runtime = {
        pathing = {
            phase = "active",
            mode = "crawl",
            resolvedMode = "crawl",
            visualMovingUntil = 0,
            motionProfile = {
                animSpeed = 0.72,
                isCrawling = true,
            },
        },
    },
    activeBehavior = "Incapacitated",
}

PNC.Animation.SyncLocomotion(zombie, moving)
assertEqual(crawler, true, "moving incapacitated crawler flag")
assertEqual(onFloor, true, "moving incapacitated floor flag")
assertEqual(variables.PNCAnim, "Crawl", "moving incapacitated animation")
assertEqual(variables.bMoving, true, "moving incapacitated movement variable")

-- Remote clients receive the same snapshot many times while the engine may
-- independently reconcile zombie animation flags. The client tick must
-- restore the downed state even when the snapshot motion key is unchanged.
PNC.Const = {
    PRESENCE_LIVE = "live",
    PRESENCE_ABSTRACT = "abstract",
    BODY_TAG_VERSION = 1,
}
PNC.Core.IsClientOnly = function() return false end
PNC.Client = {}
PNC.Registry = nil
PNC.Visuals = nil
PNC.Equipment = nil
PNC.ClientInterpolation = nil
PNC.Network = {
    ClientState = {
        snapshots = {
            npc_1 = {
                id = "npc_1",
                presenceState = "live",
                alive = true,
                liveBodyOnlineID = 77,
                presenceRevision = 4,
                healthState = "incapacitated",
                activeBehavior = "Incapacitated",
                visualState = {
                    anim = "Downed",
                    mode = "crawl",
                    moving = false,
                    isCrawling = true,
                },
            },
        },
    },
}

dofile("Contents/mods/ProjectHoomans/42.19/media/lua/client/PNC/PNC_ClientPresenceSync.lua")
PNC.ClientPresenceSync.BodyByOnlineID["77"] = zombie

PNC.ClientPresenceSync.OnTick()
assertEqual(crawler, true, "remote client initial crawler flag")
assertEqual(onFloor, true, "remote client initial floor flag")

crawler = false
onFloor = false
fallOnFront = false
variables.bCrawling = false
variables.FallOnFront = false

PNC.ClientPresenceSync.OnTick()
assertEqual(crawler, true, "remote client repeated crawler flag")
assertEqual(onFloor, true, "remote client repeated floor flag")
assertEqual(fallOnFront, true, "remote client repeated front flag")
assertEqual(variables.bCrawling, true, "remote client repeated animation crawler variable")

print("pnc_incapacitated_pose_smoke: ok")
