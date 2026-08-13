local ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function capture(path)
    local calls = {}
    local originalRequire = require
    require = function(name)
        calls[#calls + 1] = name
        return true
    end
    dofile(path)
    require = originalRequire
    return calls
end

local function indexOf(values, expected)
    for index = 1, #values do
        if values[index] == expected then return index end
    end
    return nil
end

local resetBody
local resetRecord
local resetReason
local traversalQuery = function() return true, "test" end
PNC = {
    PathService = {
        Reset = function(body, record, reason)
            resetBody = body
            resetRecord = record
            resetReason = reason
            return true, "reset"
        end,
        IsTraversalActive = traversalQuery,
    },
}

local pathServiceCalls = capture(
    ROOT .. "shared/PNC/Core/Pathing/PNC_PathService.lua"
)
local expectedPathServiceCalls = {
    "PNC/Core/Pathing/PNC_PathService/PNC_PathService_Context",
    "PNC/Core/Pathing/PNC_PathService/PNC_PathService_Facing",
    "PNC/Core/Pathing/PNC_PathService/PNC_PathService_Logging",
    "PNC/Core/Pathing/PNC_PathService/PNC_PathService_Interactions",
    "PNC/Core/Pathing/PNC_PathService/PNC_PathService_TraversalRuntime",
    "PNC/Core/Pathing/PNC_PathService/PNC_PathService_Lane",
    "PNC/Core/Pathing/PNC_PathService/PNC_PathService_Motion",
}
for index = 1, #expectedPathServiceCalls do
    assertEqual(pathServiceCalls[index], expectedPathServiceCalls[index],
        "PathService dependency " .. tostring(index))
end
assertEqual(#pathServiceCalls, #expectedPathServiceCalls,
    "PathService dependency count")

local record = { id = "npc_boundary" }
local body = { id = "body_boundary" }
local ok, reason = PNC.PathService.Commands.Reset(
    record,
    body,
    "boundary_test"
)
assertEqual(ok, true, "record-first reset result")
assertEqual(reason, "reset", "record-first reset reason")
assertEqual(resetRecord, record, "record-first reset record")
assertEqual(resetBody, body, "record-first reset body")
assertEqual(resetReason, "boundary_test", "record-first reset context")
assertEqual(PNC.PathService.Reset ~= nil, true,
    "legacy reset remains available")
assertEqual(PNC.PathService.Queries.IsTraversalActive, traversalQuery,
    "PathService traversal query compatibility")

local combatResetRecord
local combatResetBody
local combatResetReason
PNC = {
    Const = { PRESENCE_LIVE = "live" },
    PathService = {
        Commands = {
            Reset = function(targetRecord, targetBody, targetReason)
                combatResetRecord = targetRecord
                combatResetBody = targetBody
                combatResetReason = targetReason
            end,
        },
        Reset = function()
            error("combat fallback bypassed the canonical reset command")
        end,
    },
}
dofile(
    ROOT
        .. "shared/PNC/Core/Combat/CombatTactics/"
        .. "PNC_CombatTactics_Movement.lua"
)
local combatRecord = { id = "npc_combat", presenceState = "abstract" }
local combatBody = { id = "body_combat" }
assertEqual(PNC.CombatTactics.Internal.RequestHold(
    combatRecord,
    combatBody,
    "combat_hold"
), true, "combat reset boundary result")
assertEqual(combatResetRecord, combatRecord,
    "combat reset boundary record")
assertEqual(combatResetBody, combatBody,
    "combat reset boundary body")
assertEqual(combatResetReason, "combat_hold",
    "combat reset boundary reason")

PNC = { Presence = {} }
local presenceCalls = capture(
    ROOT .. "shared/PNC/Core/Presence/PNC_PresenceRuntime.lua"
)
assertEqual(presenceCalls[1],
    "PNC/Core/Presence/PNC_PresenceAdmission",
    "Presence runtime admission dependency")
assertEqual(presenceCalls[2],
    "PNC/Core/Presence/PNC_MaterializationSafety",
    "Presence runtime safety dependency")
assertEqual(presenceCalls[3], "PNC/Core/Presence/PNC_Presence",
    "Presence runtime coordinator dependency")
assertEqual(#presenceCalls, 3, "Presence runtime dependency count")

PNC = {}
local sharedCalls = capture(
    ROOT .. "shared/PNC/Composition/PNC_SharedComposition.lua"
)
local presenceIndex = indexOf(
    sharedCalls,
    "PNC/Core/Presence/PNC_PresenceRuntime"
)
assertEqual(sharedCalls[presenceIndex - 1],
    "PNC/Core/Production/PNC_WorkBehavior",
    "Presence runtime initialization predecessor")
assertEqual(sharedCalls[presenceIndex - 2],
    "PNC/Core/Production/PNC_WorkAnimationScenes",
    "Production animation scene dependency")
assertEqual(sharedCalls[presenceIndex - 3],
    "PNC/Core/Facilities/PNC_FacilityJobs_Behavior",
    "Production work follows facility job behavior")
assertEqual(sharedCalls[presenceIndex + 1],
    "PNC/Core/Scheduling/PNC_SimulationClock",
    "Presence runtime initialization successor")

print("pnc_pathing_presence_boundary_smoke: OK")
