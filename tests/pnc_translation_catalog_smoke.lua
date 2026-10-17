local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "PsychopatzCore", "common" },
})

local Loader = T.load(
    "ProjectHoomans", "shared",
    "PNC/Conversation/Blocks/PNC_ConversationTextLoader.lua")
local Json = require "PsychopatzCore/Serialization/PsychopatzJson"

local conversationManifest, manifestReason = Json.Decode(T.read(
    "ProjectHoomans", "common_mod",
    "media/translation/manifests/Conversation.json"))
T.truthy(conversationManifest,
    "Conversation translation manifest loads: " .. tostring(manifestReason))

local systems = {
    "Character", "CommandHub", "Conversation", "Debug", "Discovery",
    "Factions", "Health", "Inventory", "Needs", "Provision", "Research",
    "Scavenge", "Settlement", "Tasks", "Workshop",
}

local function readCatalog(language, system)
    if system == "Conversation" then
        local values = {}
        local paths = conversationManifest.languages[language]
        T.truthy(type(paths) == "table",
            language .. " Conversation manifest paths exist")
        for _, relativePath in ipairs(paths) do
            local shard, reason = Loader.Decode(T.read(
                "ProjectHoomans",
                "common_mod",
                "media/translation/" .. relativePath))
            T.truthy(shard, language .. " Conversation shard: "
                .. tostring(reason))
            for key, value in pairs(shard) do
                T.falsy(values[key],
                    "Conversation shard key has one owner: " .. key)
                values[key] = value
            end
        end
        return values
    end
    local path = "media/translation/" .. language .. "/" .. system
        .. "/" .. system .. ".json"
    local values, reason = Loader.Decode(T.read(
        "ProjectHoomans", "common_mod", path))
    T.truthy(values, language .. " " .. system .. ": " .. tostring(reason))
    return values
end

local function placeholderTokens(value)
    local tokens = {}
    local index = 1
    while index <= #value do
        local start, finish = string.find(value, "%", index, true)
        if not start then break end
        local cursor = finish + 1
        while cursor <= #value and string.match(
            string.sub(value, cursor, cursor), "%d")
        do
            cursor = cursor + 1
        end
        if cursor <= #value and string.match(
            string.sub(value, cursor, cursor), "%a")
        then
            cursor = cursor + 1
        end
        tokens[#tokens + 1] = string.sub(value, start, cursor - 1)
        index = cursor
    end
    return table.concat(tokens, "|")
end

for _, system in ipairs(systems) do
    local english = readCatalog("EN", system)
    local tagalog = readCatalog("TL", system)
    local count = 0
    for key, value in pairs(english) do
        count = count + 1
        T.equal(type(tagalog[key]), "string",
            "TL key parity " .. system .. ":" .. key)
        T.truthy(tagalog[key] ~= "", "TL value is non-empty " .. key)
        T.equal(placeholderTokens(tagalog[key]), placeholderTokens(value),
            "placeholder parity " .. system .. ":" .. key)
    end
    local reverse = 0
    for key in pairs(tagalog) do reverse = reverse + 1; T.truthy(
        english[key], "EN key parity " .. system .. ":" .. key)
    end
    T.equal(reverse, count, "catalog entry count parity " .. system)
end

for _, domain in ipairs({ "Sandbox", "ItemName", "UI" }) do
    local english = Loader.Decode(T.read(
        "ProjectHoomans", "common_mod",
        "media/lua/shared/Translate/EN/" .. domain .. ".json"))
    local tagalog = Loader.Decode(T.read(
        "ProjectHoomans", "common_mod",
        "media/lua/shared/Translate/TL/" .. domain .. ".json"))
    for key, value in pairs(english) do
        T.equal(type(tagalog[key]), "string",
            "native " .. domain .. " key parity " .. key)
        T.truthy(tagalog[key] ~= "",
            "native " .. domain .. " value is non-empty " .. key)
        T.equal(placeholderTokens(tagalog[key]), placeholderTokens(value),
            "native placeholder parity " .. domain .. ":" .. key)
    end
    for key in pairs(tagalog) do
        T.truthy(english[key], "native reverse parity " .. domain .. ":" .. key)
    end
end

T.finish("pnc_translation_catalog_smoke")
