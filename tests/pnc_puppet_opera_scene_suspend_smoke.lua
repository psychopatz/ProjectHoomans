local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
})

local now = 1000
local stopCalls = 0
local finishCalls = 0
local syncEvent

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
    },
    Core = {
        Now = function() return now end,
    },
    ActorControl = {
        CanWrite = function() return true end,
    },
    AnimationScenes = {
        Internal = {
            ClearLocalSceneKey = function() end,
            MarkSceneSync = function(_, eventName)
                syncEvent = eventName
            end,
        },
        Get = function(sceneId)
            if sceneId == "ambient.suspend_test" then
                return {
                    id = sceneId,
                    onStop = function()
                        stopCalls = stopCalls + 1
                    end,
                }
            end
            return nil
        end,
    },
    Animation = {
        FinishBump = function()
            finishCalls = finishCalls + 1
        end,
    },
}

T.load(
    T.path(
        "ProjectHoomans",
        "shared",
        "PNC/Core/Visuals/PNC_AnimationScenes/PNC_AnimationScenes_Lifecycle.lua"
    )
)

local record = {
    id = "suspend-test",
    presenceState = "live",
    runtime = {
        facilityActivity = {
            capability = "living",
            phase = "presenting",
        },
        animationScene = {
            id = "ambient.suspend_test",
            revision = 3,
            playbackRevision = 2,
            stepId = "sit",
            stepPosition = 1,
        },
    },
}

local body = {
    getModData = function()
        return {}
    end,
}

local suspended, reason = PNC.AnimationScenes.Suspend(
    record,
    body,
    "puppet_opera_override"
)
T.truthy(suspended == true, reason or "scene suspension failed")
T.truthy(record.runtime.animationScene == nil,
    "scene pointer survived Puppet suspension")
T.truthy(record.runtime.facilityActivity ~= nil,
    "provider runtime was destroyed during Puppet suspension")
T.truthy(record.runtime.lastAnimationScene.preservedOwner == true,
    "suspension was not marked as provider-preserving")
T.equal(stopCalls, 0,
    "provider cleanup callback ran during a temporary suspension")
T.equal(finishCalls, 1,
    "suspension did not release the old visual bump lease")
T.equal(syncEvent, "animation_scene_stop",
    "suspension did not publish the normal scene sync boundary")

return T.finish("pnc_puppet_opera_scene_suspend_smoke")
