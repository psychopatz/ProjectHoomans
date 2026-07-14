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
local actionState = "staggerback"
local staggerBack = true
local stateEventDelay = 700
local legacyIdleResets = 0
local finishingEvents = 0

ZombieIdleState = {
    instance = function() return "idle_state" end,
}

PNC = {
    Core = { Now = function() return 1000 end },
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

dofile(ROOT .. "Pathing/PNC_LiveBodyControl.lua")
PNC.LiveBodyControl.SyncLocomotionState = function()
    error("generic locomotion sync ran for an incapacitated body")
end
dofile(ROOT .. "Visuals/PNC_Animation.lua")

local function advanceActionContext()
    if string.find(actionState, "staggerback", 1, true) == 1
        and staggerBack == false
        and stateEventDelay <= 0
    then
        actionState = "idle"
    end
end

local zombie = {
    getActionStateName = function() return actionState end,
    getModData = function() return {} end,
    changeState = function(_, state)
        assertEqual(state, "idle_state", "downed idle transition state")
        -- This is the legacy AI state machine, not animation ActionContext.
        -- ZombieIdleState.enter() installs a new random state-event delay.
        stateEventDelay = 600
        legacyIdleResets = legacyIdleResets + 1
    end,
    setVariable = function(_, key, value) variables[key] = value end,
    setBumpDone = function() end,
    setBumpStaggered = function() end,
    setBumpFall = function() end,
    setBumpType = function() end,
    setHitReaction = function() end,
    setStaggerBack = function(_, value) staggerBack = value == true end,
    setStateEventDelayTimer = function(_, value) stateEventDelay = value end,
    reportEvent = function(_, event)
        if event == "ActiveAnimFinishing" then
            finishingEvents = finishingEvents + 1
            actionState = "idle"
        end
    end,
    setTarget = function() end,
    clearAggroList = function() end,
    setAttackedBy = function() end,
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
assertEqual(staggerBack, false, "incapacitation clears stagger latch")
assertEqual(stateEventDelay, 0, "incapacitation expires stagger action timer")
assertEqual(legacyIdleResets, 0, "incapacitation avoids legacy idle timer reset")
advanceActionContext()
assertEqual(actionState, "idle", "stale stagger exits on next ActionContext update")
assertEqual(crawler, false, "stationary incapacitated avoids vanilla crawler state")
assertEqual(onFloor, false, "stationary incapacitated avoids vanilla floor state")
assertEqual(fallOnFront, false, "stationary incapacitated avoids vanilla front state")
assertEqual(variables.bCrawling, false, "stationary incapacitated vanilla crawler variable")
assertEqual(variables.PNCActor, true, "stationary incapacitated custom animation actor")
assertEqual(variables.PNCWalkType, "Crawl", "stationary incapacitated idle crawl selector")
assertEqual(variables.PNCAnim, "Downed", "stationary incapacitated animation")
assertEqual(variables.bMoving, false, "stationary incapacitated movement variable")

variables = {}
crawler = false
onFloor = false
fallOnFront = false
actionState = "hitreaction"
staggerBack = true
stateEventDelay = 700
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
assertEqual(actionState, "idle", "moving crawl releases repeated hit reaction")
assertEqual(finishingEvents, 1, "moving crawl reports hit-reaction completion")
assertEqual(staggerBack, false, "moving crawl clears pending stagger latch")
assertEqual(legacyIdleResets, 0, "moving crawl avoids legacy idle timer reset")
assertEqual(crawler, false, "moving incapacitated avoids vanilla crawler state")
assertEqual(onFloor, false, "moving incapacitated avoids vanilla floor state")
assertEqual(fallOnFront, false, "moving incapacitated avoids vanilla front state")
assertEqual(variables.PNCActor, true, "moving incapacitated custom animation actor")
assertEqual(variables.PNCAnim, "Crawl", "moving incapacitated animation")
assertEqual(variables.PNCMoveAnim, "Crawl", "moving incapacitated crawl-cycle selector")
assertEqual(variables.PNCWalkType, "Crawl", "moving incapacitated crawl family selector")
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
assertEqual(crawler, false, "remote client avoids vanilla crawler state")
assertEqual(onFloor, false, "remote client avoids vanilla floor state")

crawler = false
onFloor = false
fallOnFront = false
actionState = "staggerback"
staggerBack = true
stateEventDelay = 700
variables.PNCActor = false
variables.PNCWalkType = ""
local legacyResetsBeforeRemoteRepair = legacyIdleResets

PNC.ClientPresenceSync.OnTick()
assertEqual(staggerBack, false, "remote client clears repeated stagger latch")
assertEqual(stateEventDelay, 0, "remote client expires repeated stagger timer")
assertEqual(legacyIdleResets, legacyResetsBeforeRemoteRepair, "remote client avoids legacy idle timer reset")
advanceActionContext()
assertEqual(actionState, "idle", "remote client releases stale hit reaction")
assertEqual(crawler, false, "remote client repeated vanilla crawler state")
assertEqual(onFloor, false, "remote client repeated vanilla floor state")
assertEqual(fallOnFront, false, "remote client repeated vanilla front state")
assertEqual(variables.bCrawling, false, "remote client repeated vanilla crawler variable")
assertEqual(variables.PNCActor, true, "remote client restores custom animation actor")
assertEqual(variables.PNCWalkType, "Crawl", "remote client restores idle crawl selector")

-- The authoritative path tick sees the same state after late damage callbacks.
-- Its suppression path must use the ActionContext exit condition as well.
actionState = "staggerback"
staggerBack = true
stateEventDelay = 900
local suppressed, suppressedState = PNC.LiveBodyControl.SuppressZombieState(zombie, {}, 2000)
assertEqual(suppressed, true, "path suppression recognizes staggerback")
assertEqual(suppressedState, "staggerback", "path suppression reports staggerback")
assertEqual(staggerBack, false, "path suppression clears stagger latch")
assertEqual(stateEventDelay, 0, "path suppression expires stagger timer")
assertEqual(legacyIdleResets, legacyResetsBeforeRemoteRepair, "path suppression avoids legacy idle timer reset")
advanceActionContext()
assertEqual(actionState, "idle", "path-suppressed stagger exits next ActionContext update")

print("pnc_incapacitated_pose_smoke: ok")
