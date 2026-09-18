-- Window construction, teardown, and public opening API.

PNC = PNC or {}

local Internal = PNC.PuppetOperaDebugWindow.Internal
local WindowAPI = PNC.PuppetOperaDebugWindow
local Model = Internal.Model
local Client = Internal.Client
local UI = Internal.UI
local tr = Internal.tr
local Class = ISPNCPuppetOperaDebugWindow

function Class:initialise()
    PsychopatzWindow.initialise(self)
end

function Class:createChildren()
    PsychopatzWindow.createChildren(self)
    self.model = Model
    self.loopEnabled = false
    self.editorStatus = nil
    self.refreshCounter = 0

    self.blueprintCombo = ISComboBox:new(0, 0, 1, 1, self,
        ISPNCPuppetOperaDebugWindow.onBlueprintChanged)
    self.blueprintCombo:initialise()
    self.blueprintCombo:instantiate()
    self:addChild(self.blueprintCombo)

    self.actorCombo = ISComboBox:new(0, 0, 1, 1, self,
        ISPNCPuppetOperaDebugWindow.onActorChanged)
    self.actorCombo:initialise()
    self.actorCombo:instantiate()
    self:addChild(self.actorCombo)

    self.topButtons = {}
    for _, definition in ipairs({
        { "create", "UI_PNC_PuppetOpera_CreateNew", "CREATE NEW", "quiet" },
        { "duplicate", "UI_PNC_PuppetOpera_Duplicate", "DUPLICATE", "quiet" },
        { "save", "UI_PNC_PuppetOpera_SaveDraft", "SAVE DRAFT", "selected" },
        { "reset", "UI_PNC_PuppetOpera_ResetDraft", "RESET DRAFT", "quiet" },
    }) do
        local button = UI.CreateButton(self, {
            id = definition[1],
            title = tr(definition[2], definition[3]),
            target = self,
            onclick = UI.ButtonCallback(function(clicked)
                return self:onTopAction(clicked)
            end),
            variant = definition[4],
        })
        self.topButtons[#self.topButtons + 1] = button
    end

    Internal.createTabs(self)

    self.controls = {}
    for _, definition in ipairs({
        { "play", "UI_PNC_PuppetOpera_Play", "Play", "selected" },
        { "replay", "UI_PNC_PuppetOpera_Replay", "Replay", "quiet" },
        { "loop", "UI_PNC_PuppetOpera_Loop", "Loop: OFF", "quiet" },
        { "stop", "UI_PNC_PuppetOpera_StopRestore", "Stop / Restore", "danger" },
        { "trace", "UI_PNC_PuppetOpera_DumpTrace", "Dump trace", "quiet" },
        { "clear", "UI_PNC_PuppetOpera_ClearStatus", "Clear status", "quiet" },
    }) do
        local button = UI.CreateButton(self, {
            id = definition[1],
            title = tr(definition[2], definition[3]),
            variant = definition[4],
            target = self,
            onclick = UI.ButtonCallback(function(clicked)
                return self:onControl(clicked)
            end),
        })
        self.controls[#self.controls + 1] = button
    end
    self:requestResponsiveLayout(true)
end

function Class:close()
    if Client and Client.StopPlacementPreview then
        Client.StopPlacementPreview()
    end
    if Client and Client.StopPreview then Client.StopPreview() end
    self:setVisible(false)
    self:removeFromUIManager()
    WindowAPI.instance = nil
end

function WindowAPI.Open(contextEntry)
    if not PNC.Client or not PNC.Client.CanUseDebug
        or PNC.Client.CanUseDebug() ~= true
    then
        return nil
    end
    local window = WindowAPI.instance
    if not window then
        window = UI.NewWindow(ISPNCPuppetOperaDebugWindow, {
            title = Internal.TEXT_TITLE,
            resizable = true,
            responsiveSpec = {
                width = 1160,
                height = 760,
                minWidth = 1,
                minHeight = 1,
                maxWidth = 1600,
                maxHeight = 1080,
            },
        })
        window:initialise()
        window:instantiate()
        WindowAPI.instance = window
    end
    if Model.ResetEditorSelection then
        Model.ResetEditorSelection()
    end
    if Model.ClearActorBindings then
        Model.ClearActorBindings()
    end
    -- A context-menu actor is only an opening context. Do not silently bind
    -- it to a scene slot; the builder must begin neutral and require an
    -- explicit drag/target selection so multi-actor drafts remain auditable.
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    window:refreshViews()
    Client.Refresh()
    return window
end

return Class
