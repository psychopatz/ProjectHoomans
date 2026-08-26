require "PsychopatzCore/UI/PsychopatzUI"
require "ISUI/ISComboBox"
require "PNC/Debug/PNC_AnimationSceneDebugModel"

PNC = PNC or {}
PNC.AnimationSceneDebugWindow =
    PNC.AnimationSceneDebugWindow or {}

local WindowAPI = PNC.AnimationSceneDebugWindow
local Model = PNC.AnimationSceneDebugModel
local UI = PsychopatzCore.UI
local addDetail = UI.AddKeyValue

ISPNCAnimationSceneDebugWindow =
    PsychopatzWindow:derive(
        "ISPNCAnimationSceneDebugWindow"
    )

local function drawSceneItem(list, y, row, alternate)
    local scene = row.item
    local selected = list.selected == row.index
    if selected then
        list:drawRect(
            0, y, list:getWidth(), list.itemheight,
            0.35, 0.20, 0.52, 0.78
        )
    elseif alternate then
        list:drawRect(
            0, y, list:getWidth(), list.itemheight,
            0.12, 0.16, 0.18, 0.20
        )
    end
    list:drawText(
        tostring(scene.label or scene.id),
        8, y + 5,
        0.92, 0.94, 1.00, 1,
        UIFont.Small
    )
    list:drawText(
        tostring(scene.id)
            .. "  →  PNC_" .. tostring(scene.bump),
        8, y + 23,
        0.58, 0.82, 0.95, 1,
        UIFont.Small
    )
    list:drawText(
        "category=" .. tostring(scene.category)
            .. "  pool=" .. tostring(scene.pool or "-")
            .. "  weight=" .. tostring(scene.weight),
        8, y + 41,
        0.70, 0.72, 0.74, 1,
        UIFont.Small
    )
    return y + list.itemheight
end

function ISPNCAnimationSceneDebugWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCAnimationSceneDebugWindow:createChildren()
    PsychopatzWindow.createChildren(self)

    self.search = UI.CreateTextEntry(self, {
        clearButton = true,
        width = 100,
        height = 26,
        onTextChange = function()
            self:refreshCatalog()
        end,
    })

    self.groupFilter = ISComboBox:new(
        0, 0, 180, 26, self,
        ISPNCAnimationSceneDebugWindow.onGroupChanged
    )
    self.groupFilter:initialise()
    self.groupFilter:instantiate()
    self:addChild(self.groupFilter)

    self.gapEntry = UI.CreateTextEntry(self, {
        text = "750",
        width = 90,
        height = 26,
        onlyNumbers = true,
    })

    self.list = UI.CreateList(self, {
        itemHeight = 59,
        doDrawItem = drawSceneItem,
    })
    self.details = UI.CreateKeyValueList(self, {
        itemHeight = 26,
        valueXMax = 152,
        valueXRatio = 0.35,
        ellipsize = false,
        labelX = 8,
        labelY = 6,
        valueY = 6,
        labelColor = { r = 0.62, g = 0.72, b = 0.80, a = 1 },
        valueColor = { r = 0.92, g = 0.92, b = 0.92, a = 1 },
        warningColor = { r = 1.0, g = 0.52, b = 0.28, a = 1 },
        alternateColor = { r = 0.16, g = 0.18, b = 0.20, a = 1 },
        alternateAlpha = 0.12,
        drawSelection = false,
    })

    self.buttons = {}
    local definitions = {
        { "play", "Play Scene", "onPlay", "selected" },
        { "step", "Roll Pool Once", "onStep", "warning" },
        { "cycle", "Auto Cycle Pool", "onCycle", "warning" },
        { "stop", "Stop Scene / Cycle", "onStop", "danger" },
        { "overlay", "Scene Overlay", "onOverlay", "quiet" },
        { "refresh", "Refresh Registry", "onRefresh", "quiet" },
        { "xml", "Open XML Player", "onOpenXML", "quiet" },
    }
    for _, definition in ipairs(definitions) do
        local button = UI.CreateButton(self, {
            id = definition[1],
            title = definition[2],
            target = self,
            onclick =
                ISPNCAnimationSceneDebugWindow[
                    definition[3]
                ],
            variant = definition[4],
        })
        self.buttons[#self.buttons + 1] = button
        self[definition[1] .. "Button"] = button
    end
    self:refreshGroups()
    self:refreshCatalog()
    self:requestResponsiveLayout(true)
end

function ISPNCAnimationSceneDebugWindow:onResponsiveLayout()
    local width = self:getWidth()
    local height = self:getHeight()
    local margin = 12
    local top = 58
    local gapWidth = 92
    local groupWidth = math.max(
        170,
        math.floor(width * 0.26)
    )
    local searchWidth = math.max(
        190,
        width - margin * 2 - groupWidth
            - gapWidth - 16
    )
    self.search:setX(margin)
    self.search:setY(top)
    self.search:setWidth(searchWidth)
    self.search:setHeight(26)
    self.groupFilter:setX(
        margin + searchWidth + 8
    )
    self.groupFilter:setY(top)
    self.groupFilter:setWidth(groupWidth)
    self.groupFilter:setHeight(26)
    self.gapEntry:setX(
        margin + searchWidth + 8
            + groupWidth + 8
    )
    self.gapEntry:setY(top)
    self.gapEntry:setWidth(gapWidth)
    self.gapEntry:setHeight(26)

    local buttonsTop = height - 43
    local mainTop = top + 36
    local mainHeight = math.max(
        130,
        buttonsTop - mainTop - 10
    )
    local leftWidth = math.max(
        280,
        math.floor((width - margin * 3) * 0.53)
    )
    self.list:setX(margin)
    self.list:setY(mainTop)
    self.list:setWidth(leftWidth)
    self.list:setHeight(mainHeight)
    self.details:setX(margin * 2 + leftWidth)
    self.details:setY(mainTop)
    self.details:setWidth(
        math.max(220, width - leftWidth - margin * 3)
    )
    self.details:setHeight(mainHeight)

    local buttonWidth = math.max(
        112,
        math.floor(
            (width - margin * 2 - 40)
                / #self.buttons
        )
    )
    local x = margin
    for _, button in ipairs(self.buttons) do
        button:setX(x)
        button:setY(buttonsTop)
        button:setWidth(buttonWidth)
        button:setHeight(28)
        x = x + buttonWidth + 8
    end
end

function ISPNCAnimationSceneDebugWindow:setTarget(entry)
    entry = entry or {}
    self.contextEntry = entry
    self.npcId = tostring(entry.id or "")
    self.npcName = tostring(
        entry.name
            or entry.record and entry.record.name
            or self.npcId
    )
    self.body = entry.zombie
    self.record = entry.record or entry.snapshot
    local title = "NPC Scene Lab — " .. self.npcName
    if self.setTitle then self:setTitle(title)
    else self.title = title end
    self:refreshDetails(true)
end

function ISPNCAnimationSceneDebugWindow:refreshGroups()
    local previous = self:selectedGroup()
    local previousKey = previous and previous.key or "all"
    self.groups = Model.GetGroups()
    self.groupFilter:clear()
    self.groupFilter.selected = 1
    for index, group in ipairs(self.groups) do
        self.groupFilter:addOption(group.label)
        if group.key == previousKey then
            self.groupFilter.selected = index
        end
    end
end

function ISPNCAnimationSceneDebugWindow:selectedGroup()
    return self.groups
        and self.groups[
            tonumber(self.groupFilter.selected) or 1
        ] or nil
end

function ISPNCAnimationSceneDebugWindow:onGroupChanged()
    self:refreshCatalog()
end

function ISPNCAnimationSceneDebugWindow:getSelectedScene()
    local row = self.list and self.list:getItem() or nil
    return row and row.item or nil
end

function ISPNCAnimationSceneDebugWindow:refreshCatalog()
    if not self.list then return end
    local previous = self:getSelectedScene()
    local previousId = previous and previous.id or nil
    self.totalCount = #PNC.AnimationScenes.List()
    local scenes = Model.GetScenes(
        self.search and self.search:getText() or "",
        self:selectedGroup()
    )
    self.list:clear()
    for _, scene in ipairs(scenes) do
        self.list:addItem(scene.id, scene)
        if scene.id == previousId then
            self.list.selected = #self.list.items
        end
    end
    if #self.list.items > 0
        and (tonumber(self.list.selected) or 0) < 1
    then
        self.list.selected = 1
    end
    self.visibleCount = #self.list.items
    self:refreshDetails(true)
end

function ISPNCAnimationSceneDebugWindow:resolveBody()
    if self.body
        and (not self.body.isDead
            or self.body:isDead() ~= true)
    then
        return self.body
    end
    local sync = PNC.ClientPresenceSync
    self.body = sync
        and sync.BodyByID
        and sync.BodyByID[self.npcId] or nil
    return self.body
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
        addDetail(self.details, "Scene ID", scene.id)
        addDetail(self.details, "Label", scene.label)
        addDetail(
            self.details,
            "Description",
            scene.description
        )
        addDetail(self.details, "Category", scene.category)
        addDetail(self.details, "Pool", scene.pool)
        addDetail(self.details, "Weight", scene.weight)
        addDetail(
            self.details,
            "Engine selector",
            "PNC_" .. tostring(scene.bump)
        )
        addDetail(
            self.details,
            "Composition",
            tostring(#(scene.steps or {}))
                .. " step(s) / "
                .. tostring(scene.sequenceMode or "ordered")
                .. " / "
                .. tostring(scene.repeatMode or "once")
        )
        addDetail(
            self.details,
            "Playback",
            tostring(scene.repeatMode or "once")
                .. " scene / "
                .. (
                    scene.loop
                        and "looped primitive"
                        or "one-shot primitives"
                )
        )
        addDetail(self.details, "Priority", scene.priority)
        addDetail(
            self.details,
            "Blocking",
            scene.blocking == true
        )
    else
        addDetail(
            self.details,
            "Selection",
            "No matching registered scene",
            true
        )
    end
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

function ISPNCAnimationSceneDebugWindow:send(action, payload)
    payload = payload or {}
    payload.id = self.npcId
    self.lastRequest = {
        action = action,
        at = PNC.Core and PNC.Core.Now
            and PNC.Core.Now() or 0,
        sent = PNC.Client
            and PNC.Client.SendDebug
            and PNC.Client.SendDebug(
                action,
                payload
            ) == true,
    }
    self:refreshDetails(true)
end

function ISPNCAnimationSceneDebugWindow:onPlay()
    local scene = self:getSelectedScene()
    if scene then
        self:send("animation_scene_play", {
            sceneId = scene.id,
        })
    end
end

function ISPNCAnimationSceneDebugWindow:onStep()
    local scene = self:getSelectedScene()
    if scene and scene.pool then
        self:send("animation_scene_pool_step", {
            pool = scene.pool,
        })
    end
end

function ISPNCAnimationSceneDebugWindow:onCycle()
    local scene = self:getSelectedScene()
    if scene and scene.pool then
        self:send("animation_scene_pool_start", {
            pool = scene.pool,
            gapMs = tonumber(self.gapEntry:getText())
                or 750,
        })
    end
end

function ISPNCAnimationSceneDebugWindow:onStop()
    self:send("animation_scene_stop", {})
end

function ISPNCAnimationSceneDebugWindow:onOverlay()
    if PNC.Nameplates
        and PNC.Nameplates.ToggleAnimationSceneDebug
    then
        local enabled =
            PNC.Nameplates.ToggleAnimationSceneDebug()
        if self.overlayButton then
            UI.SetButtonVariant(
                self.overlayButton,
                enabled and "selected" or "quiet"
            )
        end
    end
end

function ISPNCAnimationSceneDebugWindow:onRefresh()
    self:refreshGroups()
    self:refreshCatalog()
end

function ISPNCAnimationSceneDebugWindow:onOpenXML()
    if not PNC.AnimationDebugWindow then
        require "PNC/UI/PNC_AnimationDebugWindow"
    end
    if PNC.AnimationDebugWindow
        and PNC.AnimationDebugWindow.Open
    then
        PNC.AnimationDebugWindow.Open(
            self.contextEntry
        )
    end
end

function ISPNCAnimationSceneDebugWindow:prerender()
    self:refreshDetails(false)
    local scene = self:getSelectedScene()
    local hasPool = scene
        and scene.pool ~= nil
        and scene.pool ~= ""
    self.playButton:setEnable(scene ~= nil)
    self.stepButton:setEnable(hasPool == true)
    self.cycleButton:setEnable(hasPool == true)
    self.stopButton:setEnable(self.npcId ~= "")
    if self.overlayButton
        and PNC.Nameplates
        and PNC.Nameplates.IsAnimationSceneDebugEnabled
    then
        UI.SetButtonVariant(
            self.overlayButton,
            PNC.Nameplates.IsAnimationSceneDebugEnabled()
                and "selected" or "quiet"
        )
    end
    PsychopatzWindow.prerender(self)
end

function ISPNCAnimationSceneDebugWindow:render()
    PsychopatzWindow.render(self)
    local runtime = Model.GetRuntime(
        self.npcId,
        self.record
    )
    self:drawText(
        "Target: " .. tostring(self.npcName)
            .. " [" .. tostring(self.npcId) .. "]"
            .. (
                runtime.sceneActive
                and "  LIVE SCENE: "
                    .. tostring(runtime.sceneId)
                or "  scene inactive"
            ),
        12, 34,
        runtime.sceneActive and 0.55 or 0.72,
        runtime.sceneActive and 1.00 or 0.80,
        runtime.sceneActive and 0.65 or 0.86,
        1,
        UIFont.Small
    )
    self:drawTextRight(
        tostring(self.visibleCount or 0)
            .. " / "
            .. tostring(self.totalCount or 0)
            .. " registered  |  gap ms",
        self:getWidth() - 12,
        34,
        0.72, 0.78, 0.84, 1,
        UIFont.Small
    )
end

function ISPNCAnimationSceneDebugWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    WindowAPI.instance = nil
end

function ISPNCAnimationSceneDebugWindow:new(
    x, y, width, height, options
)
    local object = PsychopatzWindow:new(
        x, y, width, height, options
    )
    setmetatable(object, self)
    self.__index = self
    return object
end

function WindowAPI.Open(contextEntry)
    if not PNC.Client
        or not PNC.Client.CanUseDebug
        or PNC.Client.CanUseDebug() ~= true
    then
        return nil
    end
    local window = WindowAPI.instance
    if not window then
        window = UI.NewWindow(
            ISPNCAnimationSceneDebugWindow,
            {
                title = "NPC Scene Lab",
                resizable = true,
                responsiveSpec = {
                    width = 1160,
                    height = 720,
                    minWidth = 820,
                    minHeight = 520,
                    maxWidth = 1500,
                    maxHeight = 980,
                },
            }
        )
        window:initialise()
        window:instantiate()
        WindowAPI.instance = window
    end
    window:setTarget(contextEntry)
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    return window
end

local function onResetLua()
    if WindowAPI.instance then
        WindowAPI.instance:close()
    end
end

if Events and Events.OnResetLua then
    Events.OnResetLua.Add(onResetLua)
end

return WindowAPI
