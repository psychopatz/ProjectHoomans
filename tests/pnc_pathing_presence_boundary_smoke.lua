local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "root", "")

local function capture(path)
    local calls = {}
    local originalRequire = require
    require = function(name)
        calls[#calls + 1] = name
        return true
    end
    T.load(path)
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
    "PNC/Core/Pathing/PNC_TraversalAction",
    "PNC/Core/Pathing/PNC_PathService/PNC_PathService_Context",
    "PNC/Core/Pathing/PNC_PathService/PNC_PathService_Facing",
    "PNC/Core/Pathing/PNC_PathService/PNC_PathService_Logging",
    "PNC/Core/Pathing/PNC_PathService/PNC_PathService_Interactions",
    "PNC/Core/Pathing/PNC_PathService/PNC_PathService_TraversalRuntime",
    "PNC/Core/Pathing/PNC_PathService/PNC_PathService_Lane",
    "PNC/Core/Pathing/PNC_PathService/PNC_PathService_Motion",
}
for index = 1, #expectedPathServiceCalls do
    T.equal(pathServiceCalls[index], expectedPathServiceCalls[index],
        "PathService dependency " .. tostring(index))
end
T.equal(#pathServiceCalls, #expectedPathServiceCalls,
    "PathService dependency count")

local pathContextCalls = capture(
    ROOT
        .. "shared/PNC/Core/Pathing/PNC_PathService/"
        .. "PNC_PathService_Context.lua"
)
local expectedPathContextCalls = {
    "PNC/Core/Pathing/PNC_PathService/Context/PNC_PathService_Context_Config",
    "PNC/Core/Pathing/PNC_PathService/Context/PNC_PathService_Context_WorldState",
    "PNC/Core/Pathing/PNC_PathService/Context/PNC_PathService_Context_PositionRecovery",
    "PNC/Core/Pathing/PNC_PathService/Context/PNC_PathService_Context_TraversalMemory",
    "PNC/Core/Pathing/PNC_PathService/Context/PNC_PathService_Context_BodyOwnership",
    "PNC/Core/Pathing/PNC_PathService/Context/PNC_PathService_Context_Goals",
    "PNC/Core/Pathing/PNC_PathService/Context/PNC_PathService_Context_Animation",
}
for index = 1, #expectedPathContextCalls do
    T.equal(
        pathContextCalls[index],
        expectedPathContextCalls[index],
        "PathService Context dependency " .. tostring(index)
    )
end
T.equal(
    #pathContextCalls,
    #expectedPathContextCalls,
    "PathService Context dependency count"
)

local pathLaneCalls = capture(
    ROOT
        .. "shared/PNC/Core/Pathing/PNC_PathService/"
        .. "PNC_PathService_Lane.lua"
)
local expectedPathLaneCalls = {
    "PNC/Core/Pathing/PNC_PathService/Lane/PNC_PathService_Lane_TraversalStatus",
    "PNC/Core/Pathing/PNC_PathService/Lane/PNC_PathService_Lane_StateDefaults",
    "PNC/Core/Pathing/PNC_PathService/Lane/PNC_PathService_Lane_StateOwnership",
    "PNC/Core/Pathing/PNC_PathService/Lane/PNC_PathService_Lane_State",
    "PNC/Core/Pathing/PNC_PathService/Lane/PNC_PathService_Lane_NativeGoalBlock",
    "PNC/Core/Pathing/PNC_PathService/Lane/PNC_PathService_Lane_VehicleGoalBlock",
    "PNC/Core/Pathing/PNC_PathService/Lane/PNC_PathService_Lane_GoalState",
    "PNC/Core/Pathing/PNC_PathService/Lane/PNC_PathService_Lane_Intent",
}
for index = 1, #expectedPathLaneCalls do
    T.equal(
        pathLaneCalls[index],
        expectedPathLaneCalls[index],
        "PathService Lane dependency " .. tostring(index)
    )
end
T.equal(
    #pathLaneCalls,
    #expectedPathLaneCalls,
    "PathService Lane dependency count"
)

local traversalRuntimeCalls = capture(
    ROOT
        .. "shared/PNC/Core/Pathing/PNC_PathService/"
        .. "PNC_PathService_TraversalRuntime.lua"
)
local expectedTraversalRuntimeCalls = {
    "PNC/Core/Pathing/PNC_PathService/TraversalRuntime/PNC_PathService_TraversalRuntime_Signals",
    "PNC/Core/Pathing/PNC_PathService/TraversalRuntime/PNC_PathService_TraversalRuntime_Lifecycle",
    "PNC/Core/Pathing/PNC_PathService/TraversalRuntime/PNC_PathService_TraversalRuntime_Progress",
}
for index = 1, #expectedTraversalRuntimeCalls do
    T.equal(
        traversalRuntimeCalls[index],
        expectedTraversalRuntimeCalls[index],
        "TraversalRuntime dependency " .. tostring(index)
    )
end
T.equal(
    #traversalRuntimeCalls,
    #expectedTraversalRuntimeCalls,
    "TraversalRuntime dependency count"
)

local liveBodyControlCalls = capture(
    ROOT .. "shared/PNC/Core/Pathing/PNC_LiveBodyControl.lua"
)
local expectedLiveBodyControlCalls = {
    "PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_State",
    "PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_NativeMovementLease",
    "PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_GroundedLease",
    "PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_GroundedCounter",
    "PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_DamageReaction",
    "PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_GroundedRecovery",
    "PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_Presentation",
    "PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_Audio",
    "PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_Maintenance",
    "PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_Safety",
    "PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_Events",
}
for index = 1, #expectedLiveBodyControlCalls do
    T.equal(
        liveBodyControlCalls[index],
        expectedLiveBodyControlCalls[index],
        "LiveBodyControl dependency " .. tostring(index)
    )
end
T.equal(
    #liveBodyControlCalls,
    #expectedLiveBodyControlCalls,
    "LiveBodyControl dependency count"
)

local enginePlannerCalls = capture(
    ROOT .. "shared/PNC/Core/Pathing/PNC_EnginePathPlanner.lua"
)
local expectedEnginePlannerCalls = {
    "PNC/Core/Pathing/PNC_EnginePathPlanner/PNC_EnginePathPlanner_Passage",
    "PNC/Core/Pathing/PNC_EnginePathPlanner/PNC_EnginePathPlanner_Request",
    "PNC/Core/Pathing/PNC_EnginePathPlanner/PNC_EnginePathPlanner_Steering",
    "PNC/Core/Pathing/PNC_EnginePathPlanner/PNC_EnginePathPlanner_PumpTraversal",
    "PNC/Core/Pathing/PNC_EnginePathPlanner/PNC_EnginePathPlanner_PumpProgress",
    "PNC/Core/Pathing/PNC_EnginePathPlanner/PNC_EnginePathPlanner_Pump",
    "PNC/Core/Pathing/PNC_EnginePathPlanner/PNC_EnginePathPlanner_Frames",
    "PNC/Core/Pathing/PNC_EnginePathPlanner/PNC_EnginePathPlanner_Lifecycle",
}
for index = 1, #expectedEnginePlannerCalls do
    T.equal(
        enginePlannerCalls[index],
        expectedEnginePlannerCalls[index],
        "EnginePathPlanner dependency " .. tostring(index)
    )
end
T.equal(
    #enginePlannerCalls,
    #expectedEnginePlannerCalls,
    "EnginePathPlanner dependency count"
)

local enginePlannerContextCalls = capture(
    ROOT .. "shared/PNC/Core/Pathing/PNC_EnginePathPlanner_Context.lua"
)
local expectedEnginePlannerContextCalls = {
    "PNC/Core/Pathing/PNC_EnginePathPlanner_Context/PNC_EnginePathPlanner_Context_State",
    "PNC/Core/Pathing/PNC_EnginePathPlanner_Context/PNC_EnginePathPlanner_Context_Passage",
    "PNC/Core/Pathing/PNC_EnginePathPlanner_Context/PNC_EnginePathPlanner_Context_NativeState",
    "PNC/Core/Pathing/PNC_EnginePathPlanner_Context/PNC_EnginePathPlanner_Context_AuthorityLease",
    "PNC/Core/Pathing/PNC_EnginePathPlanner_Context/PNC_EnginePathPlanner_Context_RequestCleanup",
    "PNC/Core/Pathing/PNC_EnginePathPlanner_Context/PNC_EnginePathPlanner_Context_RoutePolicy",
}
for index = 1, #expectedEnginePlannerContextCalls do
    T.equal(
        enginePlannerContextCalls[index],
        expectedEnginePlannerContextCalls[index],
        "EnginePathPlanner Context dependency " .. tostring(index)
    )
end
T.equal(
    #enginePlannerContextCalls,
    #expectedEnginePlannerContextCalls,
    "EnginePathPlanner Context dependency count"
)

local fakeLocomotionCalls = capture(
    ROOT .. "shared/PNC/Core/Pathing/PNC_FakeLocomotion.lua"
)
local expectedFakeLocomotionCalls = {
    "PNC/Core/Pathing/PNC_FakeLocomotion/PNC_FakeLocomotion_Profiles",
    "PNC/Core/Pathing/PNC_FakeLocomotion/PNC_FakeLocomotion_Steering",
    "PNC/Core/Pathing/PNC_FakeLocomotion/PNC_FakeLocomotion_Body",
    "PNC/Core/Pathing/PNC_FakeLocomotion/PNC_FakeLocomotion_Candidate",
    "PNC/Core/Pathing/PNC_FakeLocomotion/PNC_FakeLocomotion_Step",
}
for index = 1, #expectedFakeLocomotionCalls do
    T.equal(
        fakeLocomotionCalls[index],
        expectedFakeLocomotionCalls[index],
        "FakeLocomotion dependency " .. tostring(index)
    )
end
T.equal(
    #fakeLocomotionCalls,
    #expectedFakeLocomotionCalls,
    "FakeLocomotion dependency count"
)

local traversalQueryCalls = capture(
    ROOT .. "shared/PNC/Core/Pathing/PNC_TraversalQuery.lua"
)
local expectedTraversalQueryCalls = {
    "PNC/Core/Pathing/TraversalQuery/PNC_TraversalQuery_Internal",
    "PNC/Core/Pathing/TraversalQuery/PNC_TraversalQuery_Squares",
    "PNC/Core/Pathing/TraversalQuery/PNC_TraversalQuery_Objects",
    "PNC/Core/Pathing/TraversalQuery/PNC_TraversalQuery_Fences",
    "PNC/Core/Pathing/TraversalQuery/PNC_TraversalQuery_Passages",
    "PNC/Core/Pathing/TraversalQuery/PNC_TraversalQuery_Planning",
    "PNC/Core/Pathing/TraversalQuery/PNC_TraversalQuery_FenceSearch",
}
for index = 1, #expectedTraversalQueryCalls do
    T.equal(
        traversalQueryCalls[index],
        expectedTraversalQueryCalls[index],
        "TraversalQuery dependency " .. tostring(index)
    )
end
T.equal(
    #traversalQueryCalls,
    #expectedTraversalQueryCalls,
    "TraversalQuery dependency count"
)

local record = { id = "npc_boundary" }
local body = { id = "body_boundary" }
local ok, reason = PNC.PathService.Commands.Reset(
    record,
    body,
    "boundary_test"
)
T.equal(ok, true, "record-first reset result")
T.equal(reason, "reset", "record-first reset reason")
T.equal(resetRecord, record, "record-first reset record")
T.equal(resetBody, body, "record-first reset body")
T.equal(resetReason, "boundary_test", "record-first reset context")
T.equal(PNC.PathService.Reset ~= nil, true,
    "legacy reset remains available")
T.equal(PNC.PathService.Queries.IsTraversalActive, traversalQuery,
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
T.load(
    ROOT
        .. "shared/PNC/Core/Combat/CombatTactics/"
        .. "PNC_CombatTactics_Movement.lua"
)
local combatRecord = { id = "npc_combat", presenceState = "abstract" }
local combatBody = { id = "body_combat" }
T.equal(PNC.CombatTactics.Internal.RequestHold(
    combatRecord,
    combatBody,
    "combat_hold"
), true, "combat reset boundary result")
T.equal(combatResetRecord, combatRecord,
    "combat reset boundary record")
T.equal(combatResetBody, combatBody,
    "combat reset boundary body")
T.equal(combatResetReason, "combat_hold",
    "combat reset boundary reason")

PNC = { Presence = {} }
local presenceCalls = capture(
    ROOT .. "shared/PNC/Core/Presence/PNC_PresenceRuntime.lua"
)
T.equal(presenceCalls[1],
    "PNC/Core/Presence/PNC_PresenceAdmission",
    "Presence runtime admission dependency")
T.equal(presenceCalls[2],
    "PNC/Core/Presence/PNC_MaterializationSafety",
    "Presence runtime safety dependency")
T.equal(presenceCalls[3], "PNC/Core/Presence/PNC_Presence",
    "Presence runtime coordinator dependency")
T.equal(#presenceCalls, 3, "Presence runtime dependency count")

PNC = {}
local sharedCalls = capture(
    ROOT .. "shared/PNC/Composition/PNC_SharedComposition.lua"
)
local presenceIndex = indexOf(
    sharedCalls,
    "PNC/Core/Presence/PNC_PresenceRuntime"
)
T.equal(sharedCalls[presenceIndex - 1],
    "PNC/Core/Production/PNC_WorkBehavior",
    "Presence runtime initialization predecessor")
T.equal(sharedCalls[presenceIndex - 2],
    "PNC/Core/Scavenge/PNC_ScavengeAnimationScenes",
    "Scavenge animation scene dependency")
T.equal(sharedCalls[presenceIndex - 3],
    "PNC/Core/Production/PNC_WorkAnimationScenes",
    "Production animation scene dependency")
T.equal(sharedCalls[presenceIndex - 4],
    "PNC/Core/Facilities/PNC_FacilityJobs_Behavior",
    "Production work follows facility job behavior")
T.equal(sharedCalls[presenceIndex + 1],
    "PNC/Core/Scheduling/PNC_SimulationClock",
    "Presence runtime initialization successor")
T.finish("pnc_pathing_presence_boundary_smoke")
