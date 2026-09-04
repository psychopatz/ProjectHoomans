-- Modular, translation-friendly flavor text for companion commands.
--
-- Other mods may extend or replace a command's lines with:
--   PNC.CompanionCommandFlavor.Register("follow", {
--       player = { { key = "UI_MyMod_Follow_Player", fallback = "With me." } },
--       npc = { { key = "UI_MyMod_Follow_NPC", fallback = "Right behind you." } },
--   })

PNC = PNC or {}
PNC.CompanionCommandFlavor = PNC.CompanionCommandFlavor or {}

local Flavor = PNC.CompanionCommandFlavor
local CoreFlavor

local function getCoreFlavor()
    if CoreFlavor then return CoreFlavor end
    CoreFlavor = PsychopatzCore and PsychopatzCore.SocialFlavor or nil
    if not CoreFlavor then
        pcall(require, "PsychopatzCore/Conversation/PsychopatzSocialFlavor")
        CoreFlavor = PsychopatzCore and PsychopatzCore.SocialFlavor or nil
    end
    return CoreFlavor
end

Flavor.Groups = Flavor.Groups or {}

local function normalizeLines(lines)
    local output = {}
    local i
    local line
    if type(lines) ~= "table" then return output end
    for i = 1, #lines do
        line = lines[i]
        if type(line) == "string" and line ~= "" then
            output[#output + 1] = { fallback = line }
        elseif type(line) == "table"
            and (line.key ~= nil or line.fallback ~= nil)
        then
            output[#output + 1] = {
                key = line.key and tostring(line.key) or nil,
                fallback = tostring(line.fallback or line.key or ""),
                weight = tonumber(line.weight) or nil,
            }
        end
    end
    return output
end

function Flavor.Register(commandID, definition)
    local id = tostring(commandID or "")
    local normalized
    local core
    if id == "" or type(definition) ~= "table" then return false end
    normalized = {
        player = normalizeLines(definition.player),
        npc = normalizeLines(definition.npc),
    }
    Flavor.Groups[id] = normalized
    -- Keep the legacy command API available to callers, but make Core's
    -- shared flavor registry the canonical source for queue-backed speech.
    core = getCoreFlavor()
    if core and core.Register then
        core.Register(id, {
            id = id,
            default = normalized,
        })
    end
    return true
end

function Flavor.Get(commandID)
    return Flavor.Groups[tostring(commandID or "")]
end

local function stableHash(value)
    local textValue = tostring(value or "")
    local hash = 17
    local i
    for i = 1, #textValue do
        hash = (hash * 31 + string.byte(textValue, i)) % 2147483647
    end
    return hash
end

local function translate(line)
    local value
    if not line then return nil end
    if line.key and getText then
        value = getText(line.key)
        if value and value ~= "" and value ~= line.key then
            return value
        end
    end
    return line.fallback ~= "" and line.fallback or nil
end

local function formatTokens(text, context)
    local output = text
    local key
    local value
    if not output then return nil end
    for key, value in pairs(context or {}) do
        output = string.gsub(
            output,
            "{" .. tostring(key) .. "}",
            function()
                return tostring(value or "")
            end
        )
    end
    return output
end

function Flavor.Resolve(commandID, speaker, seed, context)
    local core = getCoreFlavor()
    local group = Flavor.Get(commandID)
    local lines = group and group[tostring(speaker or "")] or nil
    local index
    if core and core.Resolve then
        return core.Resolve(commandID, speaker, seed, context)
    end
    if not lines or #lines <= 0 then return nil end
    index = (stableHash(
        tostring(commandID or "")
            .. ":" .. tostring(speaker or "")
            .. ":" .. tostring(seed or "")
    ) % #lines) + 1
    return formatTokens(translate(lines[index]), context)
end

return Flavor
