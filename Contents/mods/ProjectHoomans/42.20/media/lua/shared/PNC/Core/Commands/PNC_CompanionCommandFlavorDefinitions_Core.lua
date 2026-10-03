-- Shared registration helpers for the deterministic flavor data shards.
PNC = PNC or {}
PNC.CompanionCommandFlavor = PNC.CompanionCommandFlavor or {}

local Flavor = PNC.CompanionCommandFlavor

local function register(commandID, playerLines, npcLines)
    Flavor.Register(commandID, {
        player = playerLines,
        npc = npcLines,
    })
end
local function registerSimpleEmote(id, playerLines, reservedLines, warmLines)
    register("vanilla_emote_" .. id, playerLines, reservedLines)
    register("vanilla_emote_" .. id .. "_npc_reserved", nil, reservedLines)
    register("vanilla_emote_" .. id .. "_npc_warm", nil, warmLines)
end

local NPC_TYPES = { "hostile", "neutral", "colonist", "lover", "family" }

local function title(value)
    value = tostring(value or "")
    return string.upper(string.sub(value, 1, 1))
        .. string.sub(value, 2)
end

local function registerTypedReply(
    emoteID,
    stem,
    npcType,
    first,
    second,
    state
)
    local suffix = state and "_" .. title(state) or ""
    local keyStem = "UI_PNC_Flavor_VanillaEmote_" .. stem
        .. "_NPC_" .. title(npcType) .. suffix
    register(
        "vanilla_emote_" .. emoteID .. "_npc_" .. npcType
            .. (state and "_" .. state or ""),
        nil,
        {
            { key = keyStem .. "_1", fallback = first },
            { key = keyStem .. "_2", fallback = second },
        }
    )
end

local function registerTypedReplies(emoteID, stem, variants)
    local index
    local npcType
    local lines
    for index = 1, #NPC_TYPES do
        npcType = NPC_TYPES[index]
        lines = variants[npcType]
        registerTypedReply(
            emoteID,
            stem,
            npcType,
            lines[1],
            lines[2]
        )
    end
end

local function registerDailyTypedReplies(emoteID, stem, variants)
    local index
    local npcType
    local states
    for index = 1, #NPC_TYPES do
        npcType = NPC_TYPES[index]
        states = variants[npcType]
        registerTypedReply(
            emoteID,
            stem,
            npcType,
            states.first[1],
            states.first[2],
            "first"
        )
        registerTypedReply(
            emoteID,
            stem,
            npcType,
            states.returning[1],
            states.returning[2],
            "returning"
        )
    end
end
local function registerSocialGreeting(npcType, tier, state, lines)
    local stem = "SocialGreeting_" .. title(npcType) .. "_"
        .. title(tier) .. "_" .. title(state)
    register(
        "social_greeting_npc_" .. npcType .. "_" .. tier .. "_" .. state,
        nil,
        {
            {
                key = "UI_PNC_Flavor_" .. stem .. "_1",
                fallback = lines[1],
            },
            {
                key = "UI_PNC_Flavor_" .. stem .. "_2",
                fallback = lines[2],
            },
        }
    )
end

Flavor.DefinitionInternal = {
    register = register,
    registerSimpleEmote = registerSimpleEmote,
    registerTypedReplies = registerTypedReplies,
    registerDailyTypedReplies = registerDailyTypedReplies,
    registerSocialGreeting = registerSocialGreeting,
}

return Flavor
