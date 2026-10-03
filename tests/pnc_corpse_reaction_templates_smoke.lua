local T = require "tests/support/test"
T.addPackagePaths()

local ROOT = T.path(
    "ProjectHoomans",
    "common_lua",
    "PNC/Conversation/Definitions/Memory/GossipTemplates/Death/CorpseReaction/"
)
local definitions = {}
local ids = {}
local codes = {}
local events = {}

PNC = {
    Conversation = {
        Memory = {
            RegisterGossipTemplate = function(definition)
                definitions[#definitions + 1] = definition
                return true
            end,
        },
    },
}

T.load(ROOT .. "Relative/01_PNC_GossipTemplate.lua")
T.load(ROOT .. "Friend/01_PNC_GossipTemplate.lua")
T.load(ROOT .. "Comrade/01_PNC_GossipTemplate.lua")
T.load(ROOT .. "Hostile/01_PNC_GossipTemplate.lua")
T.load(ROOT .. "Neutral/01_PNC_GossipTemplate.lua")

T.equal(#definitions, 49, "corpse reactions include base and revenge variants")
for _, definition in ipairs(definitions) do
    T.truthy(not ids[definition.id], "gossip IDs must be unique")
    T.truthy(not codes[definition.code], "gossip codes must be unique")
    ids[definition.id] = true
    codes[definition.code] = true
    events[definition.event] = (events[definition.event] or 0) + 1
    T.truthy(definition.textKey, "every reaction has a localized text key")
    local expectedArguments = string.find(definition.event, "revenge", 1, true)
        and 3 or 2
    T.equal(#definition.arguments, expectedArguments,
        "reaction arguments include corpse, faction, and revenge identity")
end

for _, event in ipairs({
    "corpse_seen_relative",
    "corpse_seen_friend",
    "corpse_seen_comrade",
    "corpse_seen_hostile",
    "corpse_seen_neutral",
}) do
    T.equal(events[event], 5, "each relation has five distinct replies")
end

T.finish("pnc_corpse_reaction_templates_smoke")
