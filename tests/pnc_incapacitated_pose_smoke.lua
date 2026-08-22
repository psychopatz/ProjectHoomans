local T = require "tests/support/test"

local CLIENT_ROOT = T.path("ProjectHoomans", "client", "")
T.addPackagePaths()

local ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")

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

T.load(ROOT .. "Pathing/PNC_LiveBodyControl.lua")
PNC.LiveBodyControl.SyncLocomotionState = function()
    error("generic locomotion sync ran for an incapacitated body")
end
T.load(ROOT .. "Visuals/PNC_Animation.lua")

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
        T.equal(state, "idle_state", "downed idle transition state")
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
T.equal(staggerBack, false, "incapacitation clears stagger latch")
T.equal(stateEventDelay, 0, "incapacitation expires stagger action timer")
T.equal(legacyIdleResets, 0, "incapacitation avoids legacy idle timer reset")
advanceActionContext()
T.equal(actionState, "idle", "stale stagger exits on next ActionContext update")
T.equal(crawler, false, "stationary incapacitated avoids vanilla crawler state")
T.equal(onFloor, false, "stationary incapacitated avoids vanilla floor state")
T.equal(fallOnFront, false, "stationary incapacitated avoids vanilla front state")
T.equal(variables.bCrawling, false, "stationary incapacitated vanilla crawler variable")
T.equal(variables.PNCActor, true, "stationary incapacitated custom animation actor")
T.equal(variables.PNCWalkType, "Crawl", "stationary incapacitated idle crawl selector")
T.equal(variables.PNCAnim, "Downed", "stationary incapacitated animation")
T.equal(variables.bMoving, false, "stationary incapacitated movement variable")

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
T.equal(actionState, "idle", "moving crawl releases repeated hit reaction")
T.equal(finishingEvents, 1, "moving crawl reports hit-reaction completion")
T.equal(staggerBack, false, "moving crawl clears pending stagger latch")
T.equal(legacyIdleResets, 0, "moving crawl avoids legacy idle timer reset")
T.equal(crawler, false, "moving incapacitated avoids vanilla crawler state")
T.equal(onFloor, false, "moving incapacitated avoids vanilla floor state")
T.equal(fallOnFront, false, "moving incapacitated avoids vanilla front state")
T.equal(variables.PNCActor, true, "moving incapacitated custom animation actor")
T.equal(variables.PNCAnim, "Crawl", "moving incapacitated animation")
T.equal(variables.PNCMoveAnim, "Crawl", "moving incapacitated crawl-cycle selector")
T.equal(variables.PNCWalkType, "Crawl", "moving incapacitated crawl family selector")
T.equal(variables.bMoving, true, "moving incapacitated movement variable")

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

T.load(T.path("ProjectHoomans", "client", "PNC/PNC_ClientPresenceSync.lua"))
PNC.ClientPresenceSync.BodyByOnlineID["77"] = zombie

local visualKeySnapshot = {
    liveBodyInstanceID = "body_1",
    liveBodyLease = "lease_1",
    liveBodyOnlineID = 77,
    presenceRevision = 4,
    attackMode = false,
    visualProfile = "profile",
    isFemale = false,
    appearance = { outfit = "Naked" },
    equipmentSummary = {
        primaryFullType = "Base.Axe",
        worn = { Shirt = "Base.Shirt_FormalWhite" },
        attached = {},
    },
}
local visualKey = PNC.ClientPresenceSync.Internal.BuildVisualKey(
    visualKeySnapshot
)
local handsKey = PNC.ClientPresenceSync.Internal.BuildHandsKey(
    visualKeySnapshot
)
visualKeySnapshot.presenceRevision = 5
visualKeySnapshot.attackMode = true
T.equal(
    PNC.ClientPresenceSync.Internal.BuildVisualKey(visualKeySnapshot),
    visualKey,
    "combat transition rebuilt immutable clothing presentation"
)
if PNC.ClientPresenceSync.Internal.BuildHandsKey(visualKeySnapshot)
    == handsKey
then
    error("combat transition did not invalidate hand presentation")
end

PNC.ClientPresenceSync.OnTick()
T.equal(crawler, false, "remote client avoids vanilla crawler state")
T.equal(onFloor, false, "remote client avoids vanilla floor state")

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
T.equal(staggerBack, false, "remote client clears repeated stagger latch")
T.equal(stateEventDelay, 0, "remote client expires repeated stagger timer")
T.equal(legacyIdleResets, legacyResetsBeforeRemoteRepair, "remote client avoids legacy idle timer reset")
advanceActionContext()
T.equal(actionState, "idle", "remote client releases stale hit reaction")
T.equal(crawler, false, "remote client repeated vanilla crawler state")
T.equal(onFloor, false, "remote client repeated vanilla floor state")
T.equal(fallOnFront, false, "remote client repeated vanilla front state")
T.equal(variables.bCrawling, false, "remote client repeated vanilla crawler variable")
T.equal(variables.PNCActor, true, "remote client restores custom animation actor")
T.equal(variables.PNCWalkType, "Crawl", "remote client restores idle crawl selector")

-- The authoritative path tick sees the same state after late damage callbacks.
-- Its suppression path must use the ActionContext exit condition as well.
actionState = "staggerback"
staggerBack = true
stateEventDelay = 900
local suppressed, suppressedState = PNC.LiveBodyControl.SuppressZombieState(zombie, {}, 2000)
T.equal(suppressed, true, "path suppression recognizes staggerback")
T.equal(suppressedState, "staggerback", "path suppression reports staggerback")
T.equal(staggerBack, false, "path suppression clears stagger latch")
T.equal(stateEventDelay, 0, "path suppression expires stagger timer")
T.equal(legacyIdleResets, legacyResetsBeforeRemoteRepair, "path suppression avoids legacy idle timer reset")
advanceActionContext()
T.equal(actionState, "idle", "path-suppressed stagger exits next ActionContext update")
T.finish("pnc_incapacitated_pose_smoke")

T.finish("pnc_incapacitated_pose_smoke")
