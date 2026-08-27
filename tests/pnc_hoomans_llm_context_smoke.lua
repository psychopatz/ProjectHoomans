local T = require "tests/support/test"

local CLIENT = T.path("ProjectHoomans", "client", "")
T.addPackagePaths({ { "ProjectHoomans", "client" } })

local resolved = function(value)
    return type(value) == "table" and value.fallback or tostring(value or "")
end

PNC = {
    Network = { ClientState = {
        playerContext = { characterUUID = "char_alex" },
    } },
    CompanionCommands = {
        List = function()
            return {
                { id = "follow", clientOnly = false },
                { id = "scavenge_nearby", clientOnly = true },
            }
        end,
    },
    Conversation = {
        Relationship = {
            GetPresentation = function() return { state = "Acquaintance", approval = 4 } end,
        },
    },
}
PsychopatzCore = {
    Conversation = { Text = { Resolve = resolved } },
}
getCurrentSaveName = function() return "Save One" end

T.load(CLIENT .. "PNC/Integrations/PNC_HoomansLLMContext.lua")

local view = {
    spec = {
        npcID = "npc_12",
        characterUUID = "char_alex",
        context = {
            npcName = "Harley",
            playerName = "Alex",
            npcType = "survivor",
            conversationRelationshipID = "Acquaintance",
            entry = {
                id = "npc_12",
                snapshot = {
                    archetypeLabel = "Scout",
                    vanillaTraits = { brave = true },
                    socialProfile = { loyalty = 0.8 },
                    activeBehavior = "following",
                },
            },
        },
    },
    session = {},
    historyPart = { messages = {
        { speaker = "npc", payload = { fallback = "Stay close." } },
    } },
}

local context = PNC.HoomansLLM.Context.Build(view, "Where is the shelter?")
T.equal(context.world_uuid, "pz-save:Save One", "save-scoped world identity")
T.equal(context.player_uuid, "char_alex", "stable player identity")
T.equal(context.npc_uuid, "npc_12", "stable NPC identity")
T.equal(context.character_card.archetype, "Scout", "canonical character card")
T.equal(context.current_state.activeBehavior, "following", "compact state snapshot")
T.equal(#context.recent_conversation, 1, "bounded recent conversation")
T.equal(context.recent_conversation[1].content, "Stay close.", "recent dialogue content")
T.equal(context.available_tools[1]["function"].name, "social_react", "valid social tool name")
T.equal(context.available_tools[2]["function"].name, "order_follow", "valid order tool name")
T.equal(#context.available_tools, 2, "client-only tools are not exposed")

T.finish("pnc_hoomans_llm_context_smoke")
