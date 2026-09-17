-- Conversation-context bridge for authoritative gift results.
--
-- A successful transfer is also a semantic event: the NPC now has a concrete
-- item that later phrases such as "eat it" may refer to.  Keep only a bounded
-- serializable projection here.  Native inventory objects and player-owned
-- state never enter the dialogue context.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

require "PNC/Semantics/PNC_SemanticDiagnostics"

local GiftContext = PNC.Semantics.GiftContext or {}
PNC.Semantics.GiftContext = GiftContext
local Diagnostics = PNC.Semantics.SemanticDiagnostics

GiftContext.VERSION = 1
GiftContext.MAX_ITEMS = 12

local function audit(eventName, data, options)
    if not Diagnostics
        or type(Diagnostics.IsEnabled) ~= "function"
        or Diagnostics.IsEnabled() ~= true
    then
        return false
    end
    return Diagnostics.Record(eventName, data, options)
end

local function requestIDFor(args, pending)
    return tostring(args and (args.requestId or args.requestID)
        or pending and pending.requestID or "")
end

local function contextFailure(reason, view, args, pending)
    local session = view and view.session
    local requestID = requestIDFor(args, pending)
    audit("semantic.gift.context_failed", {
        npcID = args and args.npcId,
        requestID = requestID,
        reason = reason,
        contextAvailable = session
            and type(session.semanticDialogueContext) == "table",
    }, { requestID = requestID })
    return false, reason
end

local function sameType(left, right)
    return tostring(left or "") ~= ""
        and tostring(left or "") == tostring(right or "")
end

local function factsFor(fullType, pending)
    local selection = pending and pending.selection or nil
    if selection and sameType(selection.fullType, fullType)
        and type(selection.facts) == "table"
    then
        return selection.facts
    end
    local foundation = PNC.Gifts and PNC.Gifts.Foundation
    local adapter = foundation and foundation.MarketSenseAdapter
    if adapter and type(adapter.BuildFacts) == "function" then
        local ok, facts = pcall(adapter.BuildFacts, fullType, nil)
        if ok and type(facts) == "table" then return facts end
    end
    return {}
end

local function itemIDAt(args, index)
    local itemIDs = type(args.itemIDs) == "table" and args.itemIDs or {}
    local value = itemIDs[index]
    value = tostring(value or "")
    return value ~= "" and value or nil
end

local function displayNameFor(fullType, pending, facts)
    local selection = pending and pending.selection or nil
    if selection and sameType(selection.fullType, fullType)
        and tostring(selection.displayName or "") ~= ""
    then
        return tostring(selection.displayName)
    end
    return tostring(facts.leaf or facts.subcategory or facts.category
        or fullType or "item")
end

local function typesFor(args, pending)
    local output = {}
    local itemTypes = type(args.itemTypes) == "table" and args.itemTypes or {}
    local index
    for index = 1, math.min(#itemTypes, GiftContext.MAX_ITEMS) do
        if tostring(itemTypes[index] or "") ~= "" then
            output[#output + 1] = tostring(itemTypes[index])
        end
    end
    if #output == 0 then
        local selection = pending and pending.selection or nil
        if selection and tostring(selection.fullType or "") ~= "" then
            output[1] = tostring(selection.fullType)
        end
    end
    return output
end

local function ensureContext(view)
    local session = view and view.session
    if not session then return nil end
    if type(session.semanticDialogueContext) == "table"
        and type(session.semanticDialogueContext.RecordTurn) == "function"
    then
        return session.semanticDialogueContext
    end
    local context = PNC.Semantics.DialogueContextState
    if type(context) ~= "table" then
        local ok, loaded = pcall(require,
            "PNC/Semantics/PNC_SemanticDialogueContextState")
        if ok then context = loaded end
    end
    if type(context) ~= "table" or type(context.New) ~= "function" then
        return nil
    end
    session.semanticDialogueContext = context.New({
        currentTopic = "INVENTORY",
        maxTurns = 12,
        maxMentions = 32,
        maxFocus = 8,
    })
    return session.semanticDialogueContext
end

function GiftContext.RecordTransfer(view, args, pending)
    args = type(args) == "table" and args or {}
    local context = ensureContext(view)
    if not context then
        return contextFailure("context_state_unavailable", view, args, pending)
    end
    local input = PNC.Semantics.DialogueInput
    local internal = input and input.Internal or nil
    local types = typesFor(args, pending)
    if #types == 0 then
        return contextFailure("gift_items_unavailable", view, args, pending)
    end

    local mentions = {}
    local index
    local fullType
    local facts
    local displayName
    local id
    for index = 1, #types do
        fullType = types[index]
        facts = factsFor(fullType, pending)
        displayName = displayNameFor(fullType, pending, facts)
        id = itemIDAt(args, index)
        mentions[#mentions + 1] = {
            id = id,
            itemID = id,
            entityType = "item",
            concept = facts.leaf or facts.subcategory or facts.category
                or fullType,
            category = facts.category or facts.primary,
            text = displayName,
            value = displayName,
            name = displayName,
            fullType = fullType,
            quantity = 1,
            ownerID = args.npcId,
            capabilities = facts.capabilities,
            semanticCapabilities = facts.capabilities,
            tags = facts.tags,
            marketRole = facts.marketRole,
            marketSenseTags = facts.marketSenseTags,
            classification = facts,
            source = "gift_transfer",
        }
    end

    local ir = {
        rawText = "gift received",
        normalizedText = "gift received",
        intent = "INFORM",
        speechAct = "INFORM",
        subject = "INVENTORY",
        confidence = 0.96,
        extensions = {
            topic = "INVENTORY",
            semanticMentions = mentions,
            giftTransfer = {
                source = "authoritative",
                npcID = args.npcId,
            },
        },
    }
    if internal and type(internal.RecordContextTurn) == "function" then
        local ok, recorded, event = pcall(
            internal.RecordContextTurn, view, ir, {
                speaker = "npc",
                source = "gift_transfer",
            }
        )
        if not ok then
            return contextFailure("context_record_failed", view, args, pending)
        end
        audit("semantic.gift.context_recorded", {
            npcID = args.npcId,
            requestID = requestIDFor(args, pending),
            recorded = recorded == true,
            itemCount = #mentions,
            itemIDs = args.itemIDs,
            itemTypes = types,
            contextSequence = context.sequence,
            eventSequence = type(event) == "table" and event.sequence or nil,
        }, { requestID = requestIDFor(args, pending) })
        return recorded, event
    end
    local ok, recorded, event = pcall(context.RecordTurn, context, ir, {
        speaker = "npc",
        source = "gift_transfer",
    })
    if not ok then
        return contextFailure("context_record_failed", view, args, pending)
    end
    audit("semantic.gift.context_recorded", {
        npcID = args.npcId,
        requestID = requestIDFor(args, pending),
        recorded = recorded == true,
        itemCount = #mentions,
        itemIDs = args.itemIDs,
        itemTypes = types,
        contextSequence = context.sequence,
        eventSequence = type(event) == "table" and event.sequence or nil,
    }, { requestID = requestIDFor(args, pending) })
    return recorded, event
end

return GiftContext
