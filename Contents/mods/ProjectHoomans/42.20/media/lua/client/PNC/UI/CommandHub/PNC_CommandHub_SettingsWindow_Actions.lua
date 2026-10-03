-- Command Hub settings side-effect handlers.
--
-- This provider owns settings mutations and cross-window application.  The
-- window entry retains rendering, field population, and the public SettingsUI
-- lifecycle while this module owns the executor callbacks.

local Hub = PNC.CommandHub
local Internal = Hub.SettingsInternal
local Options = Internal.Options
local Theme = Internal.Theme
local CoreHub = Internal.CoreHub
local DisplaySettings = Internal.DisplaySettings
local trace = Internal.Trace
local tr = Internal.Translate
local getAudio = Internal.GetAudio
local themeTitle = Internal.ThemeTitle
local branchTitle = Internal.BranchTitle

local function applyOpacityToWindows(hub, opacity)
    if Hub.ChildController and Hub.ChildController.ApplyOpacity then
        return Hub.ChildController.ApplyOpacity(opacity)
    end
    Options.ApplyOpacity(hub, opacity)
    local actions = CoreHub.Actions and CoreHub.Actions.instance or nil
    if actions then Options.ApplyOpacity(actions, opacity) end
    local zones = Hub.ZoneUI and Hub.ZoneUI.instances or {}
    for _, window in pairs(zones) do
        if window then Options.ApplyOpacity(window, opacity) end
    end
end

function ISPNCCommandHubSettingsWindow:onReset()
    trace("pnc_settings_reset_start", "has_hub="
        .. tostring(Hub.instance ~= nil))
    local hub = self:getHub()
    if hub then
        Options.Reset()
        Theme.Reset()
        DisplaySettings.ResetNameplateTextScale(true)
        DisplaySettings.ResetNameplateBarScale(true)
        DisplaySettings.ResetRelationshipFeedbackScale(true)
        local audio = getAudio()
        if audio and audio.Set then
            local defaults = audio.defaults or {}
            audio.Set("playerSpeechTTS", defaults.playerSpeechTTS == true, true)
        end
        applyOpacityToWindows(hub, Options.GetOpacity())
        Options.ApplyRegisteredToolbarScale()
    end
    self:populate()
    self:setStatus(tr("UI_PNC_CommandHub_Settings_Applied",
        "Settings applied."))
    trace("pnc_settings_reset_result", "result=true")
end

function ISPNCCommandHubSettingsWindow:onThemeCycle()
    local ids = Theme.GetPresetIDs()
    local current = Theme.GetPresetID()
    local index = 1
    for position, id in ipairs(ids) do
        if id == current then index = position end
    end
    local nextIndex = index + 1
    if nextIndex > #ids then nextIndex = 1 end
    Theme.SetPreset(ids[nextIndex])
    self.themeButton:setTitle(themeTitle())
    self:setStatus(tr("UI_PNC_CommandHub_Settings_Applied",
        "Settings applied."))
end

function ISPNCCommandHubSettingsWindow:onBranchToggle()
    trace("pnc_settings_branch_start", "current=" .. tostring(Options.GetBranch()))
    local branch = Options.GetBranch() == "right" and "left" or "right"
    Options.SetBranch(branch)
    self.branchButton:setTitle(branchTitle())
    self:setStatus(tr("UI_PNC_CommandHub_Settings_Applied",
        "Settings applied."))
    if Hub.ChildController and Hub.ChildController.SyncPositions then
        Hub.ChildController.SyncPositions()
    else
        local hub = Hub.instance
        if hub and CoreHub.Actions and CoreHub.Actions.SyncPosition then
            CoreHub.Actions.SyncPosition(hub)
        end
        if Hub.ZoneUI and Hub.ZoneUI.SyncPositions then
            Hub.ZoneUI.SyncPositions()
        end
    end
    trace("pnc_settings_branch_result", "branch=" .. tostring(branch))
end

function ISPNCCommandHubSettingsWindow:onApply()
    trace("pnc_settings_apply_start", "has_hub=" .. tostring(Hub.instance ~= nil))
    local hub = self:getHub()
    if not hub then
        trace("pnc_settings_apply_result", "result=false reason=missing_hub")
        return
    end
    local opacity = math.floor(self.fields.opacity.slider:getValue() + 0.5)
    if not opacity then
        self:setStatus(tr("UI_PNC_CommandHub_Settings_Invalid",
            "Enter a valid opacity value."))
        trace("pnc_settings_apply_result", "result=false reason=invalid_values")
        return
    end
    Options.SetOpacityPercent(opacity)
    Options.SetSurfaceOpacityLift(
        math.floor(self.fields.surfaceLift.slider:getValue() + 0.5) / 100)
    Options.SetDetailOpacityLift(
        math.floor(self.fields.detailLift.slider:getValue() + 0.5) / 100)
    Options.SetTitlebarControlScale(
        math.floor(self.fields.titlebarScale.slider:getValue() + 0.5) / 100)
    DisplaySettings.SetNameplateTextScale(
        math.floor(self.fields.nameplateTextScale.slider:getValue()
            + 0.5) / 100,
        true)
    DisplaySettings.SetNameplateBarScale(
        math.floor(self.fields.nameplateBarScale.slider:getValue()
            + 0.5) / 100,
        true)
    DisplaySettings.SetRelationshipFeedbackScale(
        math.floor(self.fields.relationshipFeedbackScale.slider:getValue()
            + 0.5) / 100,
        true)
    local audio = getAudio()
    if self.audioCheckbox and audio and audio.Set then
        audio.Set("playerSpeechTTS", self.audioCheckbox:getChecked(), true)
    end
    applyOpacityToWindows(hub, opacity / 100)
    Options.ApplyRegisteredToolbarScale()
    self:populate()
    self:setStatus(tr("UI_PNC_CommandHub_Settings_Applied",
        "Settings applied."))
    trace("pnc_settings_apply_result", "result=true opacity="
        .. tostring(opacity))
end

return Internal
