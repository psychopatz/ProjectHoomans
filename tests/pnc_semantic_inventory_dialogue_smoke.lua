local T = require "tests/support/test"
T.addPackagePaths()

local originalRequire = require
local queued = {}
local appended = {}
local fallbacks = {}

PsychopatzCore = {
    Conversation = {
        Text = {
            RegisterFallback = function(key, value)
                fallbacks[key] = value
                return value
            end,
            Resolve = function(value)
                return value and (value.fallback or fallbacks[value.key]) or ""
            end,
        },
    },
}
PNC = {
    Core = {
        Now = function() return 100 end,
        IsClientOnly = function() return false end,
    },
    Conversation = {},
    Network = { ClientState = {} },
    Semantics = {},
    PBrainZ = {
        IsProviderAvailable = function() return false end,
    },
}
PsychopatzConversationLLMInput = {
    new = function(_, x, y, width, height, options)
        return { x = x, y = y, width = width, height = height, options = options }
    end,
}

local Semantic = T.load(
    "PsychopatzCore",
    "common",
    "PsychopatzCore/Semantics/PsychopatzSemantic.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticCatalog.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueResponseCatalog.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialoguePolicy.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticInventoryQuery.lua"
)
T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticInventoryQueryAdapter.lua"
)
T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticDialogueInput_Context.lua"
)
T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticDialogueInput_Presentation.lua"
)
T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticDialogueInput_Actions.lua"
)
T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticDialogueInput_Inventory.lua"
)

PNC.Client = {
    RequestSemanticInventoryQuery = function(request)
        return true, "found", {
            accepted = true,
            status = "found",
            requestID = request.requestID,
            npcID = request.npcID,
            query = request.query,
            totalCount = 2,
            distinctItems = 1,
            items = {
                {
                    itemID = "fish-1",
                    fullType = "Base.Sardines",
                    displayName = "Sardines",
                    quantity = 2,
                },
            },
        }
    end,
}

require = function() return true end
local Input = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticDialogueInput.lua"
)
require = originalRequire

local session = {
    characterUUID = "player-one",
    conversationID = "conversation-one",
    append = function(self, speaker, value, metadata)
        appended[#appended + 1] = {
            speaker = speaker, value = value, metadata = metadata,
        }
        return { messageID = "message-" .. tostring(#appended) }
    end,
    queueMessage = function(self, speaker, payload, metadata)
        queued[#queued + 1] = {
            speaker = speaker, payload = payload, metadata = metadata,
        }
    end,
}
local view = {
    spec = { npcID = "npc-alice", context = {} },
    session = session,
    animationInteractive = true,
    isConversationInteractive = function(self)
        return self.session.busy ~= true
    end,
}
PsychopatzCore.Conversation.instance = view

local accepted, reason = Input.Submit(view, "do you have seefoods?")
T.equal(accepted, true, "inventory question reaches the local dialogue route")
T.equal(reason, nil, "inventory question is not rejected")
T.equal(#appended, 1, "inventory question enters conversation history once")
T.equal(#queued, 1, "inventory result queues one NPC response")
T.equal(queued[1].payload.fallback,
    "I have 2 seafood items: Sardines (2).",
    "inventory response displays the MarketSense-backed category result")
T.equal(queued[1].metadata.source.channel,
    "inventory_query_response",
    "inventory response remains distinguishable from task acknowledgements")
T.truthy(session.semanticDialogueContext,
    "inventory response initializes the dialogue context store")
local inventoryFocus = session.semanticDialogueContext:GetFocus(1)
T.equal(inventoryFocus[1].text, "Sardines",
    "inventory response records the returned item in discourse focus")
T.falsy(session.semanticInventoryQueries["1"],
    "completed inventory query is removed from pending state")
T.equal(view.lastSemanticDialogueResult.decision.route, "deterministic",
    "inventory query does not use the LLM fallback route")

-- A queued NPC line must not lock the live semantic channel.  The full view
-- reports animationInteractive separately from Session.busy; this is the
-- state reached while a reply is being typed or released.
session.busy = true
local queuedWhileSpeaking = Input.Submit(view, "do you have seafood?")
T.equal(queuedWhileSpeaking, true,
    "a second local turn is accepted while an NPC reply is queued")
T.equal(#queued, 2,
    "the second local turn queues its own authoritative inventory answer")
session.busy = nil

T.finish("pnc_semantic_inventory_dialogue_smoke")
