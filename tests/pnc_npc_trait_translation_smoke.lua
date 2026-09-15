local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "client" },
    { "PsychopatzCore", "common" },
})

PNC = {}
local translationSource = T.read(
    "ProjectHoomans", "common_mod",
    "media/translation/EN/Character/Character.json")

local function splitLines(text)
    local lines = {}
    for line in string.gmatch(text, "([^\n]*)\n?") do
        lines[#lines + 1] = line
        if string.sub(text, -1) ~= "\n" and lines[#lines] == ""
            and #lines > 1
        then
            lines[#lines] = nil
            break
        end
    end
    return lines
end

getModFileReader = function(modID, path)
    if modID ~= "ProjectHoomans" then return nil end
    local ok, content = pcall(T.read, "ProjectHoomans", "common_mod", path)
    if not ok then return nil end
    local lines = splitLines(content)
    local index = 0
    return {
        readLine = function()
            index = index + 1
            return lines[index]
        end,
        close = function() end,
    }
end

T.load("ProjectHoomans", "shared",
    "PNC/Translation/PNC_TranslationBootstrap.lua")

local function translationValue(key)
    if type(key) ~= "string" or key == "" then return nil end
    return string.match(
        translationSource,
        "\"" .. key .. "\"%s*:%s*\"([^\"]+)\"")
end

getText = function(key)
    return translationValue(key) or key
end

local Registry = T.load(
    "ProjectHoomans", "shared", "PNC/Core/Traits/PNC_NPCTraitRegistry.lua")
T.load(
    "ProjectHoomans", "shared", "PNC/Core/Traits/PNC_NPCTraitDefinitions.lua")
local Shared = T.load(
    "ProjectHoomans", "client",
    "PNC/UI/CharacterWindow/PNC_CharacterWindow_Shared.lua")

local definitions = Registry.GetDefinitions()
T.truthy(#definitions > 0, "NPC trait registry is not empty")
for index = 1, #definitions do
    local definition = definitions[index]
    local label = translationValue(definition.labelKey)
    local description = translationValue(definition.descriptionKey)
    T.truthy(type(definition.labelKey) == "string"
        and definition.labelKey ~= "",
        definition.id .. " has a label key")
    T.truthy(type(definition.descriptionKey) == "string"
        and definition.descriptionKey ~= "",
        definition.id .. " has a description key")
    T.truthy(label and label ~= definition.labelKey,
        definition.id .. " label translation exists")
    T.truthy(description and description ~= definition.descriptionKey,
        definition.id .. " description translation exists")
    T.truthy(type(definition.iconPath) == "string"
        and definition.iconPath ~= "",
        definition.id .. " has an icon path")
    T.equal(Shared.TraitLabel(definition.id, definition), label,
        definition.id .. " resolves its translated label")
    T.equal(Shared.TraitDescription(definition.id, definition), description,
        definition.id .. " resolves its translated description")
end

-- Simulate a language/runtime where an unresolved key is returned verbatim.
-- The UI must remain readable and must never expose the canonical ID.
local originalGetKey = PNC.Translation.GetKey
PNC.Translation.GetKey = function(key) return key end
local scrapper = Registry.GetDefinition("pnc_scrapper")
T.equal(Shared.TraitLabel("pnc_scrapper", scrapper), "Scrapper",
    "unresolved label falls back to a readable trait name")
T.equal(Shared.TraitDescription("pnc_scrapper", scrapper),
    "Description unavailable",
    "unresolved description avoids exposing the trait ID")
PNC.Translation.GetKey = originalGetKey

T.finish("pnc_npc_trait_translation_smoke")
