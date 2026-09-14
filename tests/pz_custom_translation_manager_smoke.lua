local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "PsychopatzCore", "common" },
})

local activeLanguage = "ES"
local readersClosed = 0
local virtualFiles = {}

Translator = {
    getLanguage = function()
        return { toString = function() return activeLanguage end }
    end,
}

Events = {
    OnGameBoot = {
        listeners = {},
        Add = function(callback)
            Events.OnGameBoot.listeners[#Events.OnGameBoot.listeners + 1] = callback
        end,
    },
}

local function splitLines(text)
    local lines = {}
    for line in string.gmatch(text, "([^\n]*)\n?") do
        lines[#lines + 1] = line
        if string.sub(text, -1) ~= "\n"
            and lines[#lines] == ""
            and #lines > 1
        then
            lines[#lines] = nil
            break
        end
    end
    return lines
end

local function packagedSource(modID, path)
    local key = tostring(modID) .. "|" .. tostring(path)
    if virtualFiles[key] then return virtualFiles[key] end
    if modID == "ProjectHoomans" then
        local known = {
            ["media/translation/EN/Traits.json"] =
                T.read("ProjectHoomans", "common_mod",
                    "media/translation/EN/Traits.json"),
            ["media/translation/ES/Traits.json"] =
                T.read("ProjectHoomans", "common_mod",
                    "media/translation/ES/Traits.json"),
        }
        return known[path]
    end
    return nil
end

getModFileReader = function(modID, path)
    local text = packagedSource(modID, path)
    if not text then return nil end
    local lines = splitLines(text)
    local index = 0
    local reader = {}
    function reader:readLine()
        index = index + 1
        return lines[index]
    end
    function reader:close()
        readersClosed = readersClosed + 1
    end
    return reader
end

local Manager = T.load(
    "PsychopatzCore", "common",
    "PsychopatzCore/Translation/PsychopatzCustomTranslationManager.lua")
local Traits = T.load(
    "ProjectHoomans", "shared",
    "PNC/Translation/PNC_TranslationBootstrap.lua")

T.truthy(Traits, "Hoomans trait catalog registers a handle")
T.equal(Traits.modID, "ProjectHoomans", "trait catalog keeps its mod namespace")
T.equal(Traits.systemName, "Traits", "trait catalog keeps its system namespace")

for _, callback in ipairs(Events.OnGameBoot.listeners) do callback() end

T.equal(Manager.getLanguage(), "ES", "active language is read from Translator")
T.equal(Traits:get("UI_PNC_Trait_Friendly"), "Amistoso",
    "localized catalog overrides the English value")
T.equal(Traits:get("UI_PNC_Trait_Brawler"), "Brawler",
    "missing localized key falls back to English")
T.equal(Traits:get("missing.key", "Visible fallback"), "Visible fallback",
    "missing key uses the caller fallback")
T.truthy(Manager.Data.ProjectHoomans.Traits,
    "only the resolved Hoomans catalog is exposed in Data")
T.truthy(readersClosed >= 2, "English and localized readers are closed")

activeLanguage = "FR"
virtualFiles["OtherMod|media/translation/EN/Radio.json"] =
    '{"radio.test.line":"English radio line"}'
local radio = Manager.registerSystem({
    modID = "OtherMod",
    systemName = "Radio",
    basePath = "media/translation",
})
T.equal(radio:get("radio.test.line"), "English radio line",
    "unsupported language falls back to English file")

local duplicate = Manager.registerSystem({
    modID = "OtherMod",
    systemName = "Radio",
    basePath = "media/translation",
})
T.equal(duplicate, radio, "duplicate registration is idempotent")
local conflict = Manager.registerSystem({
    modID = "OtherMod",
    systemName = "Radio",
    basePath = "media/other-translation",
})
T.falsy(conflict, "conflicting registration is rejected")

virtualFiles["BadMod|media/translation/EN/Bad.json"] =
    '{"bad":null}'
local bad = Manager.registerSystem({
    modID = "BadMod",
    systemName = "Bad",
    basePath = "media/translation",
})
T.equal(bad:get("bad", "Safe fallback"), "Safe fallback",
    "non-string catalog values fail closed")
T.equal(Manager.Diagnostics["BadMod:Bad"].state, "error",
    "invalid catalog is recorded as an error")

T.finish("pz_custom_translation_manager_smoke")
