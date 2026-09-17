-- Compatibility façade for the shared PsychopatzCore preview session.
--
-- This public name is retained for the Hoomans window and older debug tools.
-- It contains no scanner, frame hook, render plan, or world drawing code;
-- those responsibilities live in Core and are created only on demand.
PNC = PNC or {}
PNC.PerceptionDebug = PNC.PerceptionDebug or {}

local Namespace = PNC.PerceptionDebug
local Provider = Namespace.CoreProvider
    or require "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_CoreProvider"
local Preview = require "PsychopatzCore/Preview/PC_Preview"
local Primitives = Namespace.OverlayPrimitives
    or require "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_OverlayPrimitives"
local Perception = PNC.Perception and PNC.Perception.WorldObjects
    or require "PNC/Perception/WorldObjectPerception/PNC_ClientWorldObjectPerception"

local Overlay = Namespace.Overlay or {}
Namespace.Overlay = Overlay

Overlay.VERSION = 1
Overlay.MAX_RENDER_OBJECTS = 32
Overlay.MAX_RENDER_ZONES = 8
Overlay.enabled = false
Overlay.eventsInstalled = false
Overlay.drawer = nil
Overlay.hovered = nil
Overlay.hoveredZone = nil
Overlay.snapshot = nil
Overlay.visibleObjects = {}
Overlay.settings = nil
Overlay.settingsRevision = nil
Overlay.settingsKey = nil
Overlay.renderPlan = nil
Overlay.renderPlanSnapshot = nil
Overlay.renderPlanSettingsKey = nil
Overlay.hoverKey = nil
Overlay.hoverPlan = nil
Overlay.tooltipKey = nil
Overlay.tooltipObject = nil
Overlay.tooltipLines = nil
Overlay.tooltipWidth = nil

local function coreState()
    return Preview.GetSession(Provider.ID)
end

local function syncState()
    local state = coreState()
    Overlay.enabled = state and state.enabled == true or false
    Overlay.eventsInstalled = Preview.IsHookInstalled()
    Overlay.drawer = state and state.drawer or nil
    Overlay.snapshot = state and state.snapshot or nil
    Overlay.visibleObjects = state and state.visibleObjects or {}
    Overlay.settings = state and state.settings or nil
    Overlay.settingsRevision = state and state.settingsRevision or nil
    Overlay.settingsKey = state and state.settingsKey or nil
    Overlay.renderPlan = state and state.renderPlan or nil
    Overlay.renderPlanSnapshot = state and state.renderPlanSnapshot or nil
    Overlay.renderPlanSettingsKey = state
        and state.renderPlanSettingsKey or nil
    Overlay.hoverKey = state and state.hoverKey or nil
    Overlay.hoverPlan = state and state.renderPlan or nil
    Overlay.hovered = state and state.hovered or nil
    Overlay.tooltipKey = state and state.tooltipKey or nil
    Overlay.tooltipObject = state and state.tooltipObject or nil
    Overlay.tooltipLines = state and state.tooltipLines or nil
    Overlay.tooltipWidth = state and state.tooltipWidth or nil
    return state
end

Overlay.ColorForObject = Provider.ObjectColor
Overlay.PriorityForObject = Provider.ObjectPriority
Overlay.HasRenderableLayers = function(settings)
    return Preview.HasRenderableLayers(Provider.ID, settings)
end

function Overlay.SyncRenderHook()
    local result = Preview.SyncRenderHook()
    syncState()
    return result
end

function Overlay.SetSnapshot(snapshot)
    local normalized, reason = Preview.SetSnapshot(Provider.ID, snapshot)
    syncState()
    if normalized == nil then return nil, reason end
    return normalized
end

function Overlay.SetEnabled(enabled)
    local result, reason = Preview.SetEnabled(Provider.ID, enabled == true)
    syncState()
    if result == false and reason then return result, reason end
    return result
end

function Overlay.Toggle()
    local result, reason = Preview.Toggle(Provider.ID)
    syncState()
    if result == false and reason then return result, reason end
    return result
end

function Overlay.IsEnabled()
    syncState()
    return Overlay.enabled == true
end

function Overlay.SetSettings(settings, revision)
    local result, reason = Preview.SetSettings(Provider.ID, settings,
        revision)
    syncState()
    if result == nil then return nil, reason end
    return result
end

function Overlay.SetSnapshotAndEnable(snapshot)
    Overlay.SetSnapshot(snapshot)
    return Overlay.SetEnabled(true)
end

function Overlay.Clear(clearPerception)
    local result = Preview.Clear(Provider.ID)
    if clearPerception == true and Perception.ClearSnapshotCache then
        Perception.ClearSnapshotCache()
    end
    syncState()
    return result
end

function Overlay.Install()
    if not Overlay.enabled then
        syncState()
        return true
    end
    local state = coreState()
    if not state then
        Preview.SetEnabled(Provider.ID, Overlay.enabled == true)
    else
        Preview.SyncRenderHook()
    end
    syncState()
    return Overlay.eventsInstalled or not Overlay.enabled
end

function Overlay.Uninstall()
    -- Core arbitrates the single shared hook, so another provider can keep it
    -- installed. This compatibility method synchronizes the global lifecycle
    -- instead of removing a hook behind Core's back.
    local result = Preview.SyncRenderHook()
    syncState()
    return result
end

function Overlay.Render()
    local result = Preview.Render()
    syncState()
    return result
end

function Overlay.Reset()
    Overlay.SetEnabled(false)
    Overlay.Clear(true)
end

syncState()

return Overlay
