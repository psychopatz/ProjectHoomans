-- Project Hoomans custom catalogs.
-- The loader belongs to PsychopatzCore; Hoomans only declares its catalog
-- ownership and provides a small key-aware facade for its UI code.
require "CustomTranslationManager"

local CoreTranslation
if type(require) == "function" then
    local ok, value = pcall(require,
        "PsychopatzCore/Translation/PsychopatzCoreTranslation")
    if ok then CoreTranslation = value end
end

PNC = PNC or {}
PNC.Translation = PNC.Translation or {}

local Translation = PNC.Translation
local Scope = CustomTranslationManager.forMod("ProjectHoomans")
local BASE_PATH = "media/translation"

local SYSTEMS = {
    "Character", "CommandHub", "Conversation", "Debug", "Discovery",
    "Factions", "Health", "Inventory", "Needs", "Provision", "Research",
    "Scavenge", "Settlement", "Tasks", "Workshop",
}

require "PNC/Translation/PNC_TranslationBootstrap_Segments"
local SEGMENT_SYSTEMS = Translation.Internal.SegmentSystems

Translation.Systems = Translation.Systems or {}
for _, systemName in ipairs(SYSTEMS) do
    if not Translation.Systems[systemName] then
        Translation.Systems[systemName] = Scope.registerSystem(systemName, BASE_PATH)
    end
end

-- Compatibility for code that used the old trait handle. The catalog itself
-- now lives at media/translation/<LANG>/Character/Character.json.
Translation.Traits = Translation.Systems.Character

local function systemForKey(key)
    if type(key) ~= "string" then return nil end
    local segment = string.match(key, "^UI_PNC_([^_]+)")
    return segment and SEGMENT_SYSTEMS[segment] or nil
end

function Translation.Get(systemName, key, fallback)
    local handle = Translation.Systems[systemName]
    if handle and type(handle.get) == "function" then
        return handle:get(key, fallback)
    end
    return fallback or key or ""
end

function Translation.GetKey(key, fallback)
    if type(key) ~= "string" or key == "" then
        return fallback or ""
    end
    local systemName = systemForKey(key)
    if systemName then
        return Translation.Get(systemName, key, fallback)
    end
    -- Only genuine PZ-native keys reach getText. Hoomans UI_PNC_* keys are
    -- always resolved through the Core-backed custom catalogs above.
    if type(getText) == "function" then
        local ok, value = pcall(getText, key)
        if ok and type(value) == "string" and value ~= "" and value ~= key then
            return value
        end
    end
    return fallback or key
end

if CoreTranslation and type(CoreTranslation.RegisterProvider) == "function" then
    CoreTranslation.RegisterProvider("ProjectHoomans", {
        getKey = function(key, fallback)
            return Translation.GetKey(key, fallback)
        end,
    })
end

function Translation.Tr(first, second, third)
    if third ~= nil and Translation.Systems[first] then
        return Translation.Get(first, second, third)
    end
    return Translation.GetKey(first, second)
end

local function formatText(value, args)
    value = string.gsub(value, "%%(%d+)", function(index)
        local position = tonumber(index)
        local replacement = position and args[position] or nil
        return replacement ~= nil and tostring(replacement) or "%%" .. index
    end)
    local ok, formatted = pcall(string.format, value,
        args[1], args[2], args[3], args[4])
    return ok and formatted or value
end

function Translation.TrFormat(key, fallback, ...)
    local value = Translation.GetKey(key, fallback)
    return formatText(value, { ... })
end

function Translation.Format(systemName, key, fallback, ...)
    local value = Translation.Get(systemName, key, fallback)
    return formatText(value, { ... })
end

return Translation
