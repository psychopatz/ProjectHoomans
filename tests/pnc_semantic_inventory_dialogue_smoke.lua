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

local inventoryRequestCount = 0
PNC.Client = {
    RequestSemanticInventoryQuery = function(request)
        inventoryRequestCount = inventoryRequestCount + 1
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
T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticDialogueInput_Trace.lua"
)
T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticDialogueInput_ProviderFallback.lua"
)
T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticDialogueInput_Lifecycle.lua"
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

local InventoryResponses = require
    "PNC/Semantics/PNC_SemanticDialogueInput_InventoryResponses"
local allItemsReply = InventoryResponses.ForResult({
    status = "found",
    query = { concept = "ANY_ITEM", text = "items" },
    totalCount = 3,
    distinctItems = 2,
    items = {
        { displayName = "Sardines", quantity = 2 },
        { displayName = "Pistol", quantity = 1 },
    },
})
T.equal(allItemsReply.fallback,
    "I have 3 items: Sardines (2), Pistol (1).",
    "open inventory responses list concrete carried items")
local noItemsReply = InventoryResponses.ForResult({
    status = "empty",
    query = { concept = "ANY_ITEM", text = "items" },
})
T.equal(noItemsReply.fallback, "I don't have any items.",
    "empty open inventory questions receive a direct answer")

local inventoryPending = Input.Internal.InventoryPending
local pendingRequestIDs = {}
for index = 1, inventoryPending.MAX_PENDING do
    local requestID = "bounded:" .. tostring(index)
    local registered, registerReason = inventoryPending.Register(
        view, requestID, { query = { concept = "FOOD" } })
    T.equal(registered, true, "pending inventory query is registered")
    T.equal(registerReason, nil, "pending inventory registration succeeds")
    pendingRequestIDs[#pendingRequestIDs + 1] = requestID
end
local duplicateRegistered, duplicateReason = inventoryPending.Register(
    view, pendingRequestIDs[1], { query = { concept = "FOOD" } })
T.falsy(duplicateRegistered,
    "duplicate inventory request IDs are not resubmitted")
T.equal(duplicateReason, "inventory_query_already_pending",
    "duplicate inventory requests return an explicit reason")
local missingSession, missingSessionReason = inventoryPending.Register(
    {}, "missing-session", { query = { concept = "FOOD" } })
T.falsy(missingSession,
    "inventory queries require a conversation session")
T.equal(missingSessionReason, "inventory_query_session_unavailable",
    "missing inventory sessions fail explicitly")
local missingID, missingIDReason = inventoryPending.Register(
    view, nil, { query = { concept = "FOOD" } })
T.falsy(missingID, "inventory queries require a request ID")
T.equal(missingIDReason, "inventory_query_request_id_missing",
    "missing inventory request IDs fail explicitly")
local overLimitRegistered, overLimitReason = inventoryPending.Register(
    view, "bounded:overflow", { query = { concept = "FOOD" } })
T.falsy(overLimitRegistered,
    "inventory queries beyond the pending cap are rejected")
T.equal(overLimitReason, "inventory_query_pending_limit",
    "the pending-query limit has an explicit failure reason")
local requestsBeforeLimit = inventoryRequestCount
local limitedSubmission = Input.Submit(view, "do you have seefoods?")
T.equal(limitedSubmission, true,
    "a full pending-query map does not reject local dialogue input")
T.equal(inventoryRequestCount, requestsBeforeLimit,
    "the pending-query cap prevents another transport request")
local pendingCount = 0
for _ in pairs(session.semanticInventoryQueries) do
    pendingCount = pendingCount + 1
end
T.equal(pendingCount, inventoryPending.MAX_PENDING,
    "pending inventory query state stays bounded")
for _, requestID in ipairs(pendingRequestIDs) do
    T.truthy(inventoryPending.Take(view, requestID),
        "completed request correlation can be removed")
end

for index = 1, 17 do
    local received, inactiveReason = Input.ReceiveInventoryQueryResult({
        requestID = "orphan:" .. tostring(index),
        npcID = "npc-alice",
        status = "found",
        query = { concept = "FOOD" },
        items = {},
    })
    T.equal(received, false, "unmatched inventory results are not presented")
    T.equal(inactiveReason, "inventory_query_not_active",
        "unmatched inventory result keeps its routing reason")
end
T.equal(#PNC.Network.ClientState.semanticInventoryQueryResultOrder, 16,
    "unmatched inventory result cache stays bounded")
T.equal(PNC.Network.ClientState.semanticInventoryQueryResults["orphan:1"], nil,
    "old unmatched inventory results are evicted")
T.truthy(PNC.Network.ClientState.semanticInventoryQueryResults["orphan:17"],
    "new unmatched inventory results remain available")

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

PNC.Client.RequestSemanticInventoryQuery = function()
    inventoryRequestCount = inventoryRequestCount + 1
    return false, "semantic_inventory_query_service_unavailable"
end
local requestsBeforeFailure = inventoryRequestCount
local unavailableSubmission = Input.Submit(view, "do you have seefoods?")
T.equal(unavailableSubmission, true,
    "an unavailable inventory transport does not reject the local turn")
T.equal(inventoryRequestCount, requestsBeforeFailure + 1,
    "the transport rejection reaches the inventory adapter")
local strandedPending = 0
for _ in pairs(session.semanticInventoryQueries or {}) do
    strandedPending = strandedPending + 1
end
T.equal(strandedPending, 0,
    "a rejected inventory transport releases its pending correlation")

T.finish("pnc_semantic_inventory_dialogue_smoke")
