--[[
    PNC Client Presence Visuals: registered animation-scene presentation
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Internal = Sync.Internal
local Animation = PNC.Animation
local Core = PNC.Core
local Diagnostics = PNC.PerformanceScalingDiagnostics

local function isFurnitureSeatingScene(sceneId)
    if sceneId == "facility.living.sitFurniture"
        or sceneId == "ambient.roam.sitFurniture"
    then
        return true
    end
    return nil
end

local function isSleepScene(sceneId)
    return string.find(
        tostring(sceneId or ""),
        "facility.sleep.",
        1,
        true
    ) == 1
end

local function keepsManagedBodyUseless(sceneId)
    return isFurnitureSeatingScene(sceneId) == true
        or isSleepScene(sceneId) == true
end

local function isWaterScene(sceneId)
    return string.find(
        tostring(sceneId or ""),
        "survival.drink.",
        1,
        true
    ) == 1
        or string.find(tostring(sceneId or ""), "survival.fill.", 1, true)
            == 1
end

local function sceneBodyState(zombie)
    local modData
    local actionState
    local contextState
    if not zombie then
        return "action= context= bump= lease=false"
    end
    modData = zombie.getModData and zombie:getModData() or nil
    actionState = zombie.getActionStateName
        and zombie:getActionStateName() or ""
    contextState = PNC.LiveBodyControl
        and PNC.LiveBodyControl.GetActionContextStateName
        and PNC.LiveBodyControl.GetActionContextStateName(zombie) or ""
    return "action=" .. tostring(actionState)
        .. " context=" .. tostring(contextState)
        .. " bump=" .. tostring(
            zombie.getBumpType and zombie:getBumpType()
                or modData and modData.PNC_BumpRequestedType or ""
        )
        .. " lease=" .. tostring(
            modData and modData.PNC_BumpActionLease == true or false
        )
end

local function logSceneReplica(eventName, recordView, presentation,
    zombie, reason)
    if Diagnostics and Diagnostics.LogSeatingState
        and Diagnostics.IsSeatingSceneId
        and presentation
        and Diagnostics.IsSeatingSceneId(presentation.id)
    then
        Diagnostics.LogSeatingState(
            "client_" .. tostring(eventName or "scene"),
            recordView,
            zombie,
            presentation,
            reason,
            {
                "clientReplica=true",
                "presentationKey=" .. tostring(presentation.key or ""),
                "presentationBump=" .. tostring(presentation.bump or ""),
            }
        )
    end
    if not presentation
        or not isWaterScene(presentation.id)
        or not Core
        or not Core.LogInfo
    then
        return
    end
    Core.LogInfo(
        "[PNC][ANIM] " .. tostring(eventName)
            .. " npc=" .. tostring(recordView and recordView.id or "nil")
            .. " scene=" .. tostring(presentation.id or "")
            .. " bump=" .. tostring(presentation.bump or "")
            .. " " .. sceneBodyState(zombie)
            .. " reason=" .. tostring(reason or "")
    )
end

local function getScenePresentation(snapshot, now)
    local visualState = snapshot and snapshot.visualState or {}
    local finishAt
    local leaseUntil
    if visualState.sceneActive ~= true
        or tostring(visualState.sceneId or "") == ""
        or tostring(visualState.sceneBump or "") == ""
    then
        return nil
    end
    finishAt = tonumber(visualState.sceneFinishAt) or 0
    leaseUntil = finishAt
    if visualState.sceneLoop == true and finishAt <= 0 then
        leaseUntil = now + 10000
    end
    return {
        key = tostring(visualState.sceneId)
            .. ":" .. tostring(
                visualState.sceneRevision or 0
            )
            .. ":" .. tostring(
                visualState.scenePlaybackRevision or 0
            ),
        id = tostring(visualState.sceneId),
        bump = tostring(visualState.sceneBump),
        loop = visualState.sceneLoop == true,
        finishAt = finishAt,
        leaseUntil = leaseUntil,
    }
end

local function syncAnimationScene(
    zombie,
    recordView,
    modData,
    presentation
)
    local previousPresentation
    if not modData then
        return presentation ~= nil, false
    end
    if not presentation then
        if modData.PNC_ClientAnimationSceneKey == nil then
            return false, false
        end
        previousPresentation = {
            id = modData.PNC_ClientAnimationSceneId,
            bump = modData.PNC_ClientAnimationSceneBump,
        }
        logSceneReplica(
            "scene_replica_stopped",
            recordView,
            previousPresentation,
            zombie,
            "snapshot_inactive"
        )
        if Animation and Animation.FinishBump then
            Animation.FinishBump(zombie, true)
        end
        modData.PNC_ClientAnimationSceneKey = nil
        modData.PNC_ClientAnimationSceneId = nil
        modData.PNC_ClientAnimationSceneBump = nil
        return false, true
    end
    if modData.PNC_ClientAnimationSceneKey
        ~= presentation.key
    then
        if Animation and Animation.PlayBump then
            local played
            local playReason
            played,
                playReason = Animation.PlayBump(
                zombie,
                recordView,
                presentation.bump,
                {
                    sceneId = presentation.id,
                    leaseUntil = presentation.leaseUntil,
                    keepManagedUseless = keepsManagedBodyUseless(
                        presentation.id
                    ),
                }
            )
            if played == false then
                logSceneReplica(
                    "scene_replica_deferred",
                    recordView,
                    presentation,
                    zombie,
                    playReason or "bump_rejected"
                )
                return true, false
            end
        end
        logSceneReplica(
            "scene_replica_started",
            recordView,
            presentation,
            zombie,
            "snapshot"
        )
        modData.PNC_ClientAnimationSceneKey =
            presentation.key
        modData.PNC_ClientAnimationSceneId = presentation.id
        modData.PNC_ClientAnimationSceneBump = presentation.bump
    elseif presentation.loop
        and Animation
        and Animation.MaintainBump
    then
        Animation.MaintainBump(
            zombie,
            recordView,
            presentation.bump,
            presentation.leaseUntil,
            {
                sceneId = presentation.id,
                keepManagedUseless = keepsManagedBodyUseless(
                    presentation.id
                ),
            }
        )
    end
    return true, false
end


Internal.GetScenePresentation = getScenePresentation
Internal.SyncAnimationScene = syncAnimationScene
