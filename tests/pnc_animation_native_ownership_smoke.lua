local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local movingWrites = 0
local variables = {}

PNC = {
    Core = { Now = function() return 1000 end },
    Animation = {
        Internal = {
            applyBumpLeaseBodyMode = function() end,
            resolveProfile = function()
                return {
                    moveAnim = "Walk",
                    walkType = "",
                    engineWalkType = "",
                    animSpeed = 1.0,
                    isRunning = false,
                    isCrawling = false,
                }
            end,
            setPNCStateVars = function() end,
            setLocomotionVars = function(_, _, moving)
                movingWrites = movingWrites + 1
                variables.PNCMoving = moving
            end,
            applyWalkType = function() end,
            getActionStateName = function() return "idle" end,
            setManagedUseless = function() end,
        },
        IsBumpActionActive = function() return false end,
    },
    LiveBodyControl = {
        SyncLocomotionState = function() end,
    },
}

T.load("ProjectHoomans", "shared",
    "PNC/Core/Visuals/PNC_Animation/PNC_Animation_NativeLocomotion.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Core/Visuals/PNC_Animation/PNC_Animation_LiveSetup.lua")

local body = {
    setVariable = function(_, name, value) variables[name] = value end,
    isMoving = function() return false end,
    setMoving = function(_, value)
        movingWrites = movingWrites + 1
        variables.isMoving = value
    end,
    setRunning = function() end,
}
local navigation = {
    provider = "engine_path",
    nativeActive = true,
}
local record = { runtime = { localNavigation = navigation } }

T.truthy(PNC.Animation.IsNativeLocomotionOwner(record),
    "engine path reports native locomotion ownership")
T.falsy(PNC.Animation.Apply(body, record, "Walk", nil, true),
    "generic animation yields to native locomotion")
T.equal(movingWrites, 0,
    "generic animation does not write moving state during native pathing")
T.falsy(variables.PNCMoving,
    "native style keeps PNC movement false without physical progress")

navigation.nativeActive = false
T.truthy(PNC.Animation.Apply(body, record, "Walk", nil, true),
    "generic animation resumes after native ownership ends")
T.truthy(movingWrites > 0,
    "scripted locomotion writes movement after native ownership ends")
T.truthy(variables.PNCMoving,
    "scripted locomotion publishes movement after native ownership ends")

T.finish("pnc_animation_native_ownership_smoke")
