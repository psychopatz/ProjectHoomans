local T = require "tests/support/test"

local CLIENT = T.path("ProjectHoomans", "client", "")
local SHARED = T.path("ProjectHoomans", "shared", "")
T.addPackagePaths({ { "ProjectHoomans", "client" } })

local resolved = function(value)
    return type(value) == "table" and value.fallback or tostring(value or "")
end

PNC = {
    Network = { ClientState = {
        playerContext = { characterUUID = "char_alex" },
        playerNameKnowledge = { ["npc_12"] = true },
        snapshots = {
            npc_12 = { needs = { hunger = 0.65, thirst = 0.10, fatigue = 0.85 } },
        },
    } },
    CompanionCommands = {
        List = function()
            return {
                { id = "follow", clientOnly = false },
                {
                    id = "camp",
                    clientOnly = false,
                    llmDescription = "Use when the player says stay here for now.",
                },
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
T.load(SHARED .. "PNC/Core/Needs/PNC_NeedsDefinitions.lua")
T.load(SHARED .. "PNC/Conversation/PNC_ConversationLLMTools.lua")
getCurrentSaveName = function() return "Save One" end
getWorld = function()
    return {
        getGameMode = function() return "Apocalypse" end,
    }
end

T.load(CLIENT .. "PNC/Integrations/PBrainZ/PNC_PBrainZ_Context.lua")

local view = {
    spec = {
        npcID = "npc_12",
        characterUUID = "char_alex",
        context = {
            npcName = "Harley",
            playerName = "Alexandra Maximilian Longsurname",
            npcType = "survivor",
            conversationRelationshipID = "Acquaintance",
            audio_presentation = {
                effect_profile = "radio",
                environment = "normal",
                intensity = 0.8,
            },
            entry = {
                id = "npc_12",
                snapshot = {
                    archetypeLabel = "Scout",
                    vanillaTraits = { brave = true },
                    skillLevels = { Carpentry = 4 },
                    socialProfile = { loyalty = 0.8 },
                    activeBehavior = "following",
                },
            },
        },
    },
    session = {},
    historyPart = { messages = {
        { speaker = "npc", payload = { fallback = "Stay close." } },
        { speaker = "npc", payload = {
            fallback = "I cannot answer right now. (OpenAI-compatible provider request failed: APIStatusError.)",
        } },
        { speaker = "npc", source = { providerFailure = true }, payload = {
            fallback = "provider fallback without a legacy marker",
        } },
        { speaker = "player", payload = { fallback = "Do you need anything?" } },
    } },
}

local context = PNC.PBrainZ.Context.Build(view, "Where is the shelter?")
T.equal(context.world_uuid, "pz-save:Save One", "save-scoped world identity")
T.equal(context.world_mode, "singleplayer", "memory world mode")
T.equal(context.save_relative_path, "Apocalypse/Save One",
    "portable save-relative memory path")
T.equal(context.player_uuid, "char_alex", "stable player identity")
T.equal(context.npc_uuid, "npc_12", "stable NPC identity")
T.equal(context.audio_presentation.effect_profile, "radio",
    "interactive LLM carries audio effect profile")
T.equal(context.audio_presentation.intensity, 0.8,
    "interactive LLM carries audio effect intensity")
T.equal(context.player_name, "Alexandra",
    "interactive LLM uses the player's first name for speech")
T.equal(context.player_full_name, "Alexandra Maximilian Longsurname",
    "interactive LLM retains the player's full identity separately")
T.equal(context.player_surname, "Maximilian Longsurname",
    "interactive LLM retains the player's surname separately")
T.equal(context.character_card.archetype, "Scout", "canonical character card")
T.equal(context.character_card.skills.Carpentry, 4,
    "canonical character card exposes NPC skill truth to the provider")
T.equal(context.current_state.activeBehavior, "following", "compact state snapshot")
T.equal(context.current_state.needs.hunger_level, "SEVERE", "needs severity")
T.equal(context.current_state.needs.highest, "hunger", "highest current need")
T.equal(context.current_state.needs.urgency, "severe", "needs urgency")
T.truthy(#context.relationship_capabilities.available_reactions >= 4,
    "relationship capabilities exposed")
T.equal(#context.recent_conversation, 2, "provider failures pruned from recent conversation")
T.equal(context.recent_conversation[1].content, "Stay close.", "recent dialogue content")
T.equal(context.recent_conversation[2].role, "user", "player dialogue retained")
T.equal(context.recent_conversation[2].content, "Do you need anything?", "player content retained")
T.equal(context.available_tools[1]["function"].name, "social_react", "valid social tool name")
T.equal(context.available_tools[2]["function"].name, "ask_name", "valid identity tool name")
T.equal(context.available_tools[3]["function"].name, "order_follow", "valid order tool name")
T.equal(context.available_tools[4]["function"].name, "order_camp", "valid camp tool name")
T.truthy(string.find(
    context.available_tools[4]["function"].description,
    "stay here for now",
    1,
    true
), "camp intent guidance is exposed to the LLM")
T.equal(#context.available_tools, 4, "client-only tools are not exposed")
T.equal(context.semantic_ir_contract.outputField, "semantic_ir",
    "LLM context advertises the shared semantic output contract")
T.equal(context.dialogue_situation.npc.activity.id, "traveling",
    "legacy provider callers still receive a bounded activity situation")
T.equal(context.dialogue_situation.social.relationshipState, "Acquaintance",
    "legacy provider callers retain the relationship situation")

view.session.semanticDialoguePending = {
    rawText = "Can you do something about this?",
    preview = {
        ir = {
            rawText = "Can you do something about this?",
            normalizedText = "can you do something about this",
            intent = nil,
            confidence = 0.20,
            confidenceBand = "low",
            modifiers = { unresolved = true },
            diagnostics = {
                noMatch = true,
                recommendedRoute = "llm_fallback",
            },
            extensions = {
                topic = { id = "help" },
                facts = {
                    LOCATION = { status = "unknown" },
                },
            },
        },
        decision = {
            diagnostics = { reason = "no_match" },
        },
    },
    context = {
        semanticEntityIndex = {
            candidates = { { id = "npc_12", name = "Harley" } },
        },
        semanticFactValues = {
            LOCATION = { status = "unknown" },
        },
    },
}
local fallbackContext = PNC.PBrainZ.Context.Build(
    view,
    "Can you do something about this?"
)
T.equal(fallbackContext.current_topic, "help",
    "LLM fallback context uses the current semantic topic")
T.equal(fallbackContext.semantic_fallback.route, "llm_fallback",
    "LLM fallback is explicitly marked in the provider payload")
T.equal(
    fallbackContext.semantic_fallback.lua_interpretation.diagnostics.no_match,
    true,
    "LLM fallback receives bounded Lua diagnostics")
T.equal(
    fallbackContext.semantic_fallback.lua_interpretation.facts.LOCATION.status,
    "unknown",
    "LLM fallback receives bounded semantic fact evidence")
T.equal(fallbackContext.semantic_entity_index.candidates[1].id, "npc_12",
    "LLM fallback receives authorized semantic entity projections")

T.finish("pnc_pbrainz_context_smoke")
