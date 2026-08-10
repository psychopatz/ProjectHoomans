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
    if not modData then
        return presentation ~= nil, false
    end
    if not presentation then
        if modData.PNC_ClientAnimationSceneKey == nil then
            return false, false
        end
        if Animation and Animation.FinishBump then
            Animation.FinishBump(zombie, true)
        end
        modData.PNC_ClientAnimationSceneKey = nil
        return false, true
    end
    if modData.PNC_ClientAnimationSceneKey
        ~= presentation.key
    then
        if Animation and Animation.PlayBump then
            Animation.PlayBump(
                zombie,
                recordView,
                presentation.bump,
                {
                    sceneId = presentation.id,
                    leaseUntil = presentation.leaseUntil,
                }
            )
        end
        modData.PNC_ClientAnimationSceneKey =
            presentation.key
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
            }
        )
    end
    return true, false
end


Internal.GetScenePresentation = getScenePresentation
Internal.SyncAnimationScene = syncAnimationScene

