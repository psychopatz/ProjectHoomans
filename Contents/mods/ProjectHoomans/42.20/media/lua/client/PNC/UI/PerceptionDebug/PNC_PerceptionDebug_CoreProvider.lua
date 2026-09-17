-- Hoomans adapter for the shared PsychopatzCore preview framework.
--
-- This file owns Hoomans presentation semantics only. Core owns session state,
-- render-plan caching, hit testing, and the native frame lifecycle.
PNC = PNC or {}
PNC.PerceptionDebug = PNC.PerceptionDebug or {}

local Namespace = PNC.PerceptionDebug
local Settings = Namespace.Settings
    or require "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_Settings"
local Model = Namespace.Model
    or require "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_Model"
local Perception = PNC.Perception and PNC.Perception.WorldObjects
    or require "PNC/Perception/WorldObjectPerception/PNC_ClientWorldObjectPerception"
local CampDiagnostics = PNC.PerceptionDebug.CampDiagnostics
    or require "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_CampDiagnostics"
local Preview = require "PsychopatzCore/Preview/PC_Preview"

local Provider = Namespace.CoreProvider or {}
Namespace.CoreProvider = Provider

function Provider.Translate(key, fallback)
    local translation = PNC and PNC.Translation
    if translation and type(translation.GetKey) == "function" then
        return translation.GetKey(key, fallback)
    end
    return fallback or key
end

Provider.ID = "projecthoomans.perception"
Provider.COLORS = {
    generic = { r = 0.78, g = 0.84, b = 0.92, a = 0.70 },
    semantic = { r = 0.32, g = 0.70, b = 1.00, a = 0.76 },
    sitting = { r = 0.24, g = 1.00, b = 0.46, a = 0.84 },
    sleeping = { r = 0.80, g = 0.42, b = 1.00, a = 0.84 },
    water = { r = 0.18, g = 0.66, b = 1.00, a = 0.82 },
    depleted = { r = 1.00, g = 0.62, b = 0.16, a = 0.78 },
    unsafe = { r = 1.00, g = 0.20, b = 0.16, a = 0.86 },
    job = { r = 1.00, g = 0.82, b = 0.24, a = 0.82 },
    room = { r = 0.38, g = 0.76, b = 1.00, a = 0.25 },
    campfire = { r = 1.00, g = 0.54, b = 0.12, a = 0.86 },
}

local function hasValues(values)
    return type(values) == "table" and #values > 0
end

function Provider.HasRenderableLayers(settings)
    settings = type(settings) == "table" and settings or {}
    return settings.showSemanticNames ~= false
        or settings.showSitting ~= false
        or settings.showSleeping ~= false
        or settings.showWater ~= false
        or settings.showCampZones ~= false
        or settings.showJobs ~= false
        or settings.showUnknownObjects == true
end

function Provider.ObjectVisible(object, settings)
    return Model.ObjectVisible(object, settings) == true
end

function Provider.ObjectPriority(object, settings)
    settings = type(settings) == "table" and settings or {}
    local facts = object and object.facts or {}
    if facts.waterDetected and settings.showWater ~= false then return 60 end
    if facts.validSleeping and settings.showSleeping ~= false then return 50 end
    if facts.validSitting and settings.showSitting ~= false then return 45 end
    if facts.isCampfire and settings.showCampZones ~= false then return 40 end
    if (facts.semanticName or facts.commandName)
        and settings.showSemanticNames ~= false
    then return 30 end
    if (hasValues(facts.jobs) or hasValues(facts.capabilities))
        and settings.showJobs ~= false
    then return 20 end
    return 10
end

function Provider.ObjectColor(object, settings)
    settings = type(settings) == "table" and settings or {}
    local facts = object and object.facts or {}
    local colors = Provider.COLORS
    if facts.waterDetected and settings.showWater ~= false then
        if facts.waterState == "UNSAFE" then return colors.unsafe end
        if facts.waterState == "DEPLETED" then return colors.depleted end
        if facts.waterState == "ACTIVE" then return colors.water end
    end
    if facts.validSleeping and settings.showSleeping ~= false then
        return colors.sleeping
    end
    if facts.validSitting and settings.showSitting ~= false then
        return colors.sitting
    end
    if facts.isCampfire and settings.showCampZones ~= false then
        return colors.campfire
    end
    if (facts.semanticName or facts.commandName)
        and settings.showSemanticNames ~= false
    then return colors.semantic end
    if (hasValues(facts.jobs) or hasValues(facts.capabilities))
        and settings.showJobs ~= false
    then return colors.job end
    return colors.generic
end

function Provider.ZoneVisible(zone, settings)
    settings = type(settings) == "table" and settings or {}
    return settings.showCampZones ~= false and type(zone) == "table"
        and (zone.kind == "room" or zone.kind == "campfire"
            or zone.kind == "radius")
end

function Provider.ZoneColor(zone)
    if zone and (zone.kind == "campfire" or zone.kind == "radius") then
        return Provider.COLORS.campfire
    end
    return Provider.COLORS.room
end

function Provider.ZoneLabel(zone)
    if type(zone) ~= "table" then return nil end
    if zone.kind == "campfire" or zone.kind == "radius" then
        return tostring(zone.label or "campfire")
    end
    return tostring(zone.label or zone.roomName or zone.roomType or "room")
end

function Provider.TooltipLines(object, settings)
    return Model.TooltipLines(object, settings)
end

function Provider.RefreshSnapshot()
    -- The generic Core window calls this only from its explicit Refresh
    -- action. Keep the same local-only, fresh-snapshot boundary as the
    -- existing Hoomans dashboard.
    local snapshot
    Perception.ClearSnapshotCache()
    snapshot = Perception.GetSnapshot({
        radius = Perception.DEFAULT_RADIUS,
        maxObjects = Perception.MAX_OBJECTS,
        cacheMs = 0,
        includeUnknown = Settings.Get("showUnknownObjects", false),
    })
    -- Keep command-result state outside the world observer. It is event
    -- driven and is copied into the frozen preview only on explicit refresh.
    if type(snapshot) == "table" then
        snapshot.diagnostics = snapshot.diagnostics or {}
        snapshot.diagnostics.campCommand = CampDiagnostics.Get()
    end
    return snapshot
end

Provider.definition = {
    id = Provider.ID,
    source = "Project Hoomans",
    title = "Hoomans Perception",
    titleKey = "UI_PNC_PerceptionDebug_CoreProvider_Title",
    description = "Client-local semantic world preview",
    descriptionKey = "UI_PNC_PerceptionDebug_CoreProvider_Description",
    version = 1,
    maxRenderObjects = 32,
    maxRenderZones = 8,
    getSettings = function() return Settings.All() end,
    getSettingsRevision = function() return Settings.GetRevision() end,
    translate = Provider.Translate,
    refreshSnapshot = Provider.RefreshSnapshot,
    getOptionDefinitions = function() return Settings.GetOptionDefinitions() end,
    objectRows = Model.ObjectRows,
    detailRows = Model.DetailRows,
    summary = Model.Summary,
    campPreviewRows = Model.CampPreviewRows,
    hasRenderableLayers = Provider.HasRenderableLayers,
    objectVisible = Provider.ObjectVisible,
    objectPriority = Provider.ObjectPriority,
    objectColor = Provider.ObjectColor,
    zoneVisible = Provider.ZoneVisible,
    zoneColor = Provider.ZoneColor,
    zoneLabel = Provider.ZoneLabel,
    tooltipLines = Provider.TooltipLines,
    layers = {
        {
            id = "semantic",
            title = "Semantic objects",
            titleKey = "UI_PNC_PerceptionDebug_CoreProvider_LayerSemantic",
            kind = "object",
            settingKey = "showSemanticNames",
            tag = "semantic",
            priority = 30,
            color = Provider.COLORS.semantic,
        },
        {
            id = "sitting",
            title = "Valid sitting objects",
            titleKey = "UI_PNC_PerceptionDebug_CoreProvider_LayerSitting",
            kind = "object",
            settingKey = "showSitting",
            tag = "sitting",
            priority = 45,
            color = Provider.COLORS.sitting,
        },
        {
            id = "sleeping",
            title = "Valid sleeping objects",
            titleKey = "UI_PNC_PerceptionDebug_CoreProvider_LayerSleeping",
            kind = "object",
            settingKey = "showSleeping",
            tag = "sleeping",
            priority = 50,
            color = Provider.COLORS.sleeping,
        },
        {
            id = "water",
            title = "Water objects",
            titleKey = "UI_PNC_PerceptionDebug_CoreProvider_LayerWater",
            kind = "object",
            settingKey = "showWater",
            tag = "water",
            priority = 60,
            color = Provider.COLORS.water,
        },
        {
            id = "camp.room",
            title = "Camp rooms",
            titleKey = "UI_PNC_PerceptionDebug_CoreProvider_LayerRoom",
            kind = "zone",
            settingKey = "showCampZones",
            tag = "camp.room",
            priority = 30,
            color = Provider.COLORS.room,
        },
        {
            id = "campfire",
            title = "Campfire radius",
            titleKey = "UI_PNC_PerceptionDebug_CoreProvider_LayerCampfire",
            kind = "zone",
            settingKey = "showCampZones",
            tag = "campfire",
            priority = 40,
            color = Provider.COLORS.campfire,
        },
        {
            id = "jobs",
            title = "Jobs and capabilities",
            titleKey = "UI_PNC_PerceptionDebug_CoreProvider_LayerJobs",
            kind = "object",
            settingKey = "showJobs",
            tag = "job",
            priority = 20,
            color = Provider.COLORS.job,
        },
    },
}

local registered, value = Preview.RegisterProvider(Provider.definition)
Provider.registered = registered == true
Provider.registration = value

return Provider
