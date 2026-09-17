-- Settings shared by the perception dashboard, native ModOptions, and the
-- world overlay.  Keeping this contract separate makes future perception
-- providers (for example plants) add a toggle without growing the window or
-- the semantic scanner itself.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and PsychopatzCore.RuntimeRole.AllowsClientCode
    and not PsychopatzCore.RuntimeRole.AllowsClientCode()
then return end

PNC = PNC or {}
PNC.PerceptionDebug = PNC.PerceptionDebug or {}

local Settings = PNC.PerceptionDebug.Settings or {}
PNC.PerceptionDebug.Settings = Settings
Settings.revision = tonumber(Settings.revision) or 0

local DEFAULTS = {
    showObjectNames = true,
    showSemanticNames = true,
    showUsage = true,
    showSitting = true,
    showSleeping = true,
    showWater = true,
    showCampZones = true,
    showJobs = true,
    showUnknownObjects = false,
    showTooltip = true,
    showCampPreview = true,
}

local LABELS = {
    showObjectNames = "UI_PNC_PerceptionDebug_ShowObjectNames",
    showSemanticNames = "UI_PNC_PerceptionDebug_ShowSemanticNames",
    showUsage = "UI_PNC_PerceptionDebug_ShowUsage",
    showSitting = "UI_PNC_PerceptionDebug_ShowSitting",
    showSleeping = "UI_PNC_PerceptionDebug_ShowSleeping",
    showWater = "UI_PNC_PerceptionDebug_ShowWater",
    showCampZones = "UI_PNC_PerceptionDebug_ShowCampZones",
    showJobs = "UI_PNC_PerceptionDebug_ShowJobs",
    showUnknownObjects = "UI_PNC_PerceptionDebug_ShowUnknown",
    showTooltip = "UI_PNC_PerceptionDebug_ShowTooltip",
    showCampPreview = "UI_PNC_PerceptionDebug_ShowCampPreview",
}

local ORDER = {
    "showObjectNames",
    "showSemanticNames",
    "showUsage",
    "showSitting",
    "showSleeping",
    "showWater",
    "showCampZones",
    "showJobs",
    "showUnknownObjects",
    "showTooltip",
    "showCampPreview",
}

local localValues = Settings.localValues or {}
Settings.localValues = localValues

local function store()
    return PNC.SettingsStore
end

local function ensureStoreDefaults()
    local current = store()
    if not current then return end
    current.defaults = current.defaults or {}
    current.values = current.values or {}
    for key, defaultValue in pairs(DEFAULTS) do
        current.defaults[key] = current.defaults[key] == nil
            and defaultValue or current.defaults[key]
        if current.values[key] == nil then
            current.values[key] = defaultValue
        end
    end
end

local function normalize(key, value)
    if DEFAULTS[key] == nil then return nil end
    return value == true
end

function Settings.Get(key, fallback)
    key = tostring(key or "")
    -- This module shares the native options page with nameplates, but it does
    -- not share their setting namespace. Reject unknown keys before touching
    -- the legacy ProjectHoomans store; otherwise a nameplate `enabled` value
    -- can accidentally activate this debug surface again.
    if DEFAULTS[key] == nil then return fallback == true end
    local current = store()
    if current and current.Get then
        local value = current:Get(key, nil)
        if value ~= nil then return value == true end
    end
    if localValues[key] ~= nil then return localValues[key] == true end
    if DEFAULTS[key] ~= nil then return DEFAULTS[key] == true end
    return fallback == true
end

function Settings.Set(key, value, save)
    key = tostring(key or "")
    value = normalize(key, value)
    if value == nil then return nil end
    localValues[key] = value
    Settings.revision = Settings.revision + 1
    local current = store()
    if current and current.Set then
        ensureStoreDefaults()
        current:Set(key, value, save ~= false)
    end
    -- Keep the frame hook dormant when the enabled session has no world
    -- layer selected. Resolve the overlay lazily so this settings module does
    -- not create a load-order dependency on the renderer.
    local overlay = PNC.PerceptionDebug
        and PNC.PerceptionDebug.Overlay or nil
    if overlay and type(overlay.SyncRenderHook) == "function" then
        overlay.SyncRenderHook()
    end
    return value
end

function Settings.GetRevision()
    local current = store()
    -- Loading the shared store can happen after this module is required. The
    -- loaded bit is part of the revision so the overlay does not retain the
    -- pre-load defaults forever.
    return tostring(Settings.revision) .. ":"
        .. tostring(current and current.loaded == true)
end

function Settings.Toggle(key)
    return Settings.Set(key, not Settings.Get(key, false))
end

function Settings.ApplyDefaults()
    ensureStoreDefaults()
    for key, defaultValue in pairs(DEFAULTS) do
        if localValues[key] == nil then localValues[key] = defaultValue end
    end
    return Settings.All()
end

function Settings.All()
    local output = {}
    for key, defaultValue in pairs(DEFAULTS) do
        output[key] = Settings.Get(key, defaultValue)
    end
    return output
end

function Settings.GetOptionDefinitions()
    Settings.ApplyDefaults()
    local definitions = {}
    for index = 1, #ORDER do
        local key = ORDER[index]
        local optionKey = key
        definitions[#definitions + 1] = {
            id = optionKey,
            label = LABELS[optionKey],
            get = function()
                return Settings.Get(optionKey, DEFAULTS[optionKey])
            end,
            set = function(value) Settings.Set(optionKey, value, true) end,
        }
    end
    return definitions
end

Settings.Defaults = DEFAULTS
Settings.Labels = LABELS
Settings.ApplyDefaults()

return Settings
