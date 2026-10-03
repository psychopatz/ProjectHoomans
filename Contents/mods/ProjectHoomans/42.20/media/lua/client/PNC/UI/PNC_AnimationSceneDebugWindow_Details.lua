-- Animation-scene debug detail projection provider.

PNC = PNC or {}
PNC.AnimationSceneDebugWindow = PNC.AnimationSceneDebugWindow or {}
local WindowAPI = PNC.AnimationSceneDebugWindow
local Model = PNC.AnimationSceneDebugModel
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local addDetail = UI.AddKeyValue

local function appendSceneDetails(details, scene)
    addDetail(details, "Scene ID", scene.id)
    addDetail(details, "Label", scene.label)
    addDetail(
        details,
        "Description",
        scene.description
    )
    addDetail(details, "Category", scene.category)
    addDetail(details, "Pool", scene.pool)
    addDetail(details, "Weight", scene.weight)
    addDetail(
        details,
        "Engine selector",
        "PNC_" .. tostring(scene.bump)
    )
    addDetail(
        details,
        "Composition",
        tostring(#(scene.steps or {}))
            .. " step(s) / "
            .. tostring(scene.sequenceMode or "ordered")
            .. " / "
            .. tostring(scene.repeatMode or "once")
    )
    addDetail(
        details,
        "Playback",
        tostring(scene.repeatMode or "once")
            .. " scene / "
            .. (
                scene.loop
                    and "looped primitive"
                    or "one-shot primitives"
            )
    )
    addDetail(details, "Priority", scene.priority)
    addDetail(
        details,
        "Blocking",
        scene.blocking == true
    )
end

local function appendRuntimeDetails(self, runtime)
    addDetail(
        self.details,
        "Authority scene",
        runtime.sceneActive
            and runtime.sceneId or "inactive"
    )
    addDetail(
        self.details,
        "Authority bump",
        runtime.sceneBump
    )
    addDetail(
        self.details,
        "Scene revision",
        tostring(runtime.sceneRevision)
            .. " / playback "
            .. tostring(runtime.scenePlaybackRevision)
    )
    addDetail(
        self.details,
        "Sequence step",
        tostring(runtime.sceneStepPosition)
            .. "/" .. tostring(runtime.sceneStepCount)
            .. " " .. tostring(runtime.sceneStepId or "-")
            .. " / pass "
            .. tostring(runtime.sceneSequenceIteration)
            .. " / " .. tostring(runtime.sceneRepeatMode)
    )
    addDetail(
        self.details,
        "Scene timing",
        tostring(runtime.sceneStartedAt)
            .. " → " .. tostring(runtime.sceneFinishAt)
    )
    addDetail(
        self.details,
        "Next primitive",
        runtime.sceneNextStepAt ~= 0
            and runtime.sceneNextStepAt or "-"
    )
    addDetail(
        self.details,
        "Pool cycle",
        runtime.cycleActive
            and (
                tostring(runtime.cyclePool)
                    .. " / gap "
                    .. tostring(runtime.cycleGapMs)
                    .. " ms"
            )
            or "inactive"
    )
    addDetail(
        self.details,
        "Debug mode",
        runtime.debugMode
    )
    addDetail(
        self.details,
        "Cycle completed",
        runtime.cycleCompletedCount
    )
    addDetail(
        self.details,
        "Cycle last scene",
        runtime.cycleLastSceneId
    )
    addDetail(
        self.details,
        "Last debug error",
        runtime.cycleLastError,
        runtime.cycleLastError ~= nil
    )
    addDetail(
        self.details,
        "Last request transport",
        self.lastRequest
            and (
                tostring(self.lastRequest.action)
                    .. " / sent="
                    .. tostring(self.lastRequest.sent)
            )
            or "none",
        self.lastRequest
            and self.lastRequest.sent ~= true
    )
end

local function appendClientDetails(self)
    local localState = Model.GetBodyRuntime(
        self:resolveBody()
    )
    addDetail(
        self.details,
        "Client BumpType",
        localState.bumpType
    )
    addDetail(
        self.details,
        "Client action state",
        localState.actionState
    )
    addDetail(
        self.details,
        "Previous action state",
        localState.previousActionState
    )
    addDetail(
        self.details,
        "Client animation state",
        localState.animationState
    )
    addDetail(
        self.details,
        "Client track 0:0",
        localState.track
    )
    addDetail(
        self.details,
        "Track time / frame @30",
        localState.trackTime ~= nil
            and (
                tostring(localState.trackTime)
                    .. " / "
                    .. tostring(localState.trackFrame)
            )
            or "-"
    )
end

function ISPNCAnimationSceneDebugWindow:refreshDetails(force)
    if not self.details then return end
    local scene = self:getSelectedScene()
    local runtime = Model.GetRuntime(
        self.npcId,
        self.record
    )
    local now = PNC.Core
        and PNC.Core.Now
        and PNC.Core.Now() or 0
    local key = tostring(scene and scene.id or "")
        .. ":" .. tostring(runtime.sceneRevision)
        .. ":" .. tostring(runtime.scenePlaybackRevision)
        .. ":" .. tostring(runtime.cycleCompletedCount)
        .. ":" .. tostring(runtime.cycleActive)
    if not force
        and self.detailKey == key
        and now < (tonumber(self.nextDetailAt) or 0)
    then
        return
    end
    self.detailKey = key
    self.nextDetailAt = now + 150
    self.details:clear()
    if scene then
        appendSceneDetails(self.details, scene)
    else
        addDetail(
            self.details,
            "Selection",
            "No matching registered scene",
            true
        )
    end
    appendRuntimeDetails(self, runtime)
    appendClientDetails(self)
end



return WindowAPI
