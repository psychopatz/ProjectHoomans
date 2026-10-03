-- Animation-scene debug actions, rendering, and window lifecycle provider.

PNC = PNC or {}
PNC.AnimationSceneDebugWindow = PNC.AnimationSceneDebugWindow or {}
local WindowAPI = PNC.AnimationSceneDebugWindow
local Model = PNC.AnimationSceneDebugModel
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local addDetail = UI.AddKeyValue

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
    if not PNC.NPCPresentationDebug
        or not PNC.NPCPresentationDebug.Open
    then
        require "PNC/UI/NPCPresentationDebug/PNC_NPCPresentationDebug"
    end
    if PNC.NPCPresentationDebug
        and PNC.NPCPresentationDebug.Open
    then
        PNC.NPCPresentationDebug.Open(
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
