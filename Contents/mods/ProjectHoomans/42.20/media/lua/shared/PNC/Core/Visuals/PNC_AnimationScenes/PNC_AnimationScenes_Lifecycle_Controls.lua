-- Animation-scene stop, interruption, and surrender controls.

PNC = PNC or {}
PNC.AnimationScenes = PNC.AnimationScenes or {}
PNC.AnimationScenes.Internal = PNC.AnimationScenes.Internal or {}

local Scenes = PNC.AnimationScenes
local Internal = Scenes.Internal
local ActorControl = PNC.ActorControl

function Scenes.Stop(record, zombie, reason, owner)
    local allowed
    local ownerReason
    if ActorControl and ActorControl.CanWrite then
        allowed, ownerReason = ActorControl.CanWrite(
            record,
            owner,
            "animation_scene_stop",
            { reason = reason or "scene_stopped" }
        )
        if allowed == false then
            return false, ownerReason or "puppet_opera_owned"
        end
    end
    return Internal.ClearScene(
        record,
        zombie,
        reason or "scene_stopped",
        true
    )
end

-- Clear a presentation scene while preserving the provider runtime that owns
-- it. Puppet Opera uses this handoff when it temporarily takes an actor from
-- a facility, ambient, or conversation presentation. The provider can then
-- rebuild its visual scene after the Puppet lease is released.
function Scenes.Suspend(record, zombie, reason)
    return Internal.ClearScene(
        record,
        zombie,
        reason or "scene_suspended",
        true,
        { preserveOwner = true }
    )
end

function Scenes.RequestFromPool(record, zombie, poolName, options)
    local sceneId
    options = type(options) == "table" and options or {}
    poolName = tostring(poolName or "")
    if poolName == "" or not Scenes.Pools[poolName] then
        return false, "pool_missing"
    end
    sceneId = Internal.ChoosePoolScene(
        poolName,
        options.excludeSceneId
            and tostring(options.excludeSceneId) or nil
    )
    if not sceneId then
        return false, "pool_empty"
    end
    return Scenes.Request(record, zombie, sceneId, options)
end

function Scenes.Interrupt(record, zombie, reason, owner)
    local scene = record and record.runtime
        and record.runtime.animationScene or nil
    local definition = scene and Scenes.Get(scene.id) or nil
    local interruptKey = tostring(reason or "externalBump")
    local allowed
    local ownerReason
    if not scene or not definition then return false end
    if ActorControl and ActorControl.CanWrite then
        allowed, ownerReason = ActorControl.CanWrite(
            record,
            owner,
            "animation_scene_interrupt",
            { reason = reason or "externalBump" }
        )
        if allowed == false then
            return false, ownerReason or "puppet_opera_owned"
        end
    end
    if definition.interrupts[interruptKey] == false then
        return false
    end
    return Internal.ClearScene(
        record,
        zombie,
        "interrupted:" .. interruptKey,
        true
    )
end

function Scenes.OnExternalBump(record, zombie, bumpType)
    local scene = record and record.runtime
        and record.runtime.animationScene or nil
    local definition = scene and Scenes.Get(scene.id) or nil
    if not scene or not definition then return false end
    if tostring(scene.bump or "") == tostring(bumpType or "")
        or "PNC_" .. tostring(scene.bump or "") == tostring(bumpType or "")
    then
        return false
    end
    if definition.interrupts.externalBump == false then
        return false
    end
    return Internal.ClearScene(
        record,
        zombie,
        "interrupted:externalBump",
        false
    )
end

function Scenes.StartSurrender(record, zombie, options)
    return Scenes.Request(record, zombie, "social.surrender", options)
end

function Scenes.StopSurrender(record, zombie, reason)
    local scene = record and record.runtime
        and record.runtime.animationScene or nil
    if not scene or scene.id ~= "social.surrender" then
        return false
    end
    return Scenes.Stop(record, zombie, reason or "surrender_released")
end

return Scenes
