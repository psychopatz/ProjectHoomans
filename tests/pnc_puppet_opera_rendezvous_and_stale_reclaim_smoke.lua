local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
})

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local Anchors = T.load("ProjectHoomans", "shared",
    "PNC/Core/PuppetOpera/PNC_PuppetOpera_Anchors.lua")

local kissBlueprint = {
    id = "social.kiss_player_npc",
    actors = {
        actor_1 = { anchor = "a1" },
        actor_2 = { anchor = "a2" },
    },
    anchorFrame = {
        tolerance = 0.75,
        interactionDistance = 0.55,
        anchors = {
            a1 = { right = 0, forward = 0, z = 0, faceTarget = "actor_2" },
            a2 = { right = 0, forward = 1, z = 0, faceTarget = "actor_1" },
        },
    },
}

local function makeCell(blockedSet)
    local grid = {}
    for x = 0, 20 do
        for y = 0, 20 do
            local key = tostring(x) .. ":" .. tostring(y)
            local blocked = blockedSet[key] == true
            grid[key] = {
                getX = function() return x end,
                getY = function() return y end,
                getZ = function() return 0 end,
                isInARoom = function() return true end,
                isFree = function() return not blocked end,
                isSolid = function() return blocked end,
                isSolidTrans = function() return false end,
                isBlockedTo = function() return false end,
            }
        end
    end
    return {
        getGridSquare = function(_, x, y)
            return grid[tostring(math.floor(x)) .. ":" .. tostring(math.floor(y))]
        end,
    }
end

local playerFacingSouth = {
    getX = function() return 10.5 end,
    getY = function() return 10.5 end,
    getZ = function() return 0 end,
    getForwardDirectionX = function() return 0 end,
    getForwardDirectionY = function() return 1 end,
}

-- 1. Forward tile (10, 11) is a counter/wall -> auto-rotates to an open side.
local cellWallAhead = makeCell({ ["10:11"] = true })
local rotatedPlan, rotErr = Anchors.BuildPlan(
    kissBlueprint, playerFacingSouth, { cell = cellWallAhead })
T.equal(rotErr, nil, "rotated anchor plan succeeds")
T.truthy(rotatedPlan, "rotated plan returned")
T.equal(rotatedPlan.rendezvousAdjusted, "rotated",
    "blocked forward tile triggers cardinal rotation")
T.falsy(rotatedPlan.actors.actor_2.x == 10 and rotatedPlan.actors.actor_2.y == 11,
    "actor_2 is NOT placed on the blocked forward tile (10, 11)")

-- 2. All 4 adjacent tiles blocked (tight corner) -> shifts to nearest open pair.
local cellCorner = makeCell({
    ["10:11"] = true, ["10:9"] = true, ["9:10"] = true, ["11:10"] = true,
})
local shiftedPlan, shiftErr = Anchors.BuildPlan(
    kissBlueprint, playerFacingSouth, { cell = cellCorner })
T.equal(shiftErr, nil, "shifted rendezvous plan succeeds")
T.truthy(shiftedPlan, "shifted plan returned")
T.equal(shiftedPlan.rendezvousAdjusted, "shifted",
    "tight corner shifts both actors to nearest open local rendezvous")
local a1 = shiftedPlan.actors.actor_1
local a2 = shiftedPlan.actors.actor_2
T.truthy(cellCorner:getGridSquare(a1.x, a1.y, 0):isFree(true),
    "shifted actor_1 target is walkable")
T.truthy(cellCorner:getGridSquare(a2.x, a2.y, 0):isFree(true),
    "shifted actor_2 target is walkable")

-- 3. Stale PuppetOpera override is auto-reclaimed instead of wedging the NPC.
local releaseCalls = 0
PNC = {
    PuppetOpera = {
        Authority = {
            Sessions = { ["active-session"] = { id = "active-session" } },
        },
        Override = {
            Internal = {
                OverrideKey = "puppetOperaOverride",
                RuntimeOf = function(r) return r.runtime end,
                ActionStateOf = function() return "idle" end,
                UnsafeActionStates = {},
                ContextOf = function() return nil end,
                PathIsActive = function() return false end,
            },
            Release = function() releaseCalls = releaseCalls + 1 end,
        },
    },
}
local Override = T.load("ProjectHoomans", "server",
    "PNC/PuppetOpera/PNC_PuppetOpera_Override_Readiness.lua")

local npcBody = { isDead = function() return false end }
local npcRec = {
    id = "wilmer",
    alive = true,
    runtime = {
        puppetOperaOverride = { sessionId = "dead-session-99" },
        puppetOperaLease = { sessionId = "dead-session-99" },
    },
}
local ready, readyReason = Override.GetReadiness(npcRec, npcBody, {
    sessionId = "new-session-100",
})
T.equal(ready, true, "stale override from ended session is auto-reclaimed")
T.equal(releaseCalls, 1, "Override.Release invoked to clean stale override")
T.equal(npcRec.runtime.puppetOperaOverride, nil, "stale override cleared")
T.equal(npcRec.runtime.puppetOperaLease, nil, "stale lease cleared")

-- Active session is still properly protected.
npcRec.runtime.puppetOperaOverride = { sessionId = "active-session" }
local busyReady, busyReason = Override.GetReadiness(npcRec, npcBody, {
    sessionId = "other-session",
})
T.equal(busyReady, false, "genuinely active session still blocks takeover")
T.equal(busyReason, "npc_owned_by_other_puppet_override",
    "active session reports expected ownership error")
