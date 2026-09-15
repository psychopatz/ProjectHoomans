local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "PsychopatzCore", "common" },
})

local language = "TL"
local readersClosed = 0
local files = {
    ["ProjectHoomans|media/conversation/test/shared/EN/bundle.json"] =
        '{"english.only":"English fallback","translated":"English"}',
    ["ProjectHoomans|media/conversation/test/shared/TL/bundle.json"] =
        '{"translated":"Tagalog"}',
}

Translator = {
    getLanguage = function()
        return { toString = function() return language end }
    end,
}

local registered = {}
PNC = {}
PsychopatzCore = {
    Conversation = {
        Text = {
            RegisterTable = function(domain, active, values)
                registered[domain .. "|" .. active] = values
            end,
        },
    },
}

local function lines(text)
    local result = {}
    for line in string.gmatch(text, "([^\n]*)\n?") do
        result[#result + 1] = line
        if string.sub(text, -1) ~= "\n" and result[#result] == ""
            and #result > 1
        then
            result[#result] = nil
            break
        end
    end
    return result
end

getModFileReader = function(modID, path)
    local text = files[tostring(modID) .. "|" .. tostring(path)]
    if not text then return nil end
    local source = lines(text)
    local index = 0
    local reader = {}
    function reader:readLine()
        index = index + 1
        return source[index]
    end
    function reader:close()
        readersClosed = readersClosed + 1
    end
    return reader
end

local Loader = T.load(
    "ProjectHoomans", "shared",
    "PNC/Conversation/Blocks/PNC_ConversationTextLoader.lua")
local source = {
    modID = "ProjectHoomans",
    pathPattern = "media/conversation/test/shared/{language}/bundle.json",
    domain = "test.translation_fallback",
}

local ok, resolved = Loader.EnsureSource(source, {
    "english.only", "translated",
})
T.truthy(ok, "partial Tagalog conversation catalog loads")
T.equal(resolved.translated, "Tagalog",
    "Tagalog conversation value overlays English")
T.equal(resolved["english.only"], "English fallback",
    "missing Tagalog conversation key falls back to English")
T.equal(registered["test.translation_fallback|TL"]["english.only"],
    "English fallback", "registered active table is already overlaid")
T.truthy(Loader.diagnostics["test.translation_fallback"].usedFallback,
    "missing localized key is diagnosed")
T.equal(#Loader.diagnostics["test.translation_fallback"].missingLocalizedKeys,
    1, "one localized key is missing")

Loader.Reset()
language = "FR"
local fallbackOK, fallback = Loader.EnsureSource(source, {
    "english.only", "translated",
})
T.truthy(fallbackOK, "missing language file falls back to English")
T.equal(fallback.translated, "English",
    "missing language file returns English values")
T.truthy(Loader.diagnostics["test.translation_fallback"].localizedError,
    "missing language file is diagnosed")
T.truthy(readersClosed >= 3, "conversation readers close on every read")

T.finish("pnc_conversation_translation_fallback_smoke")
