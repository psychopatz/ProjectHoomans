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
local TransferProjection = require
    "PNC/Semantics/PNC_SemanticGiftContext_TransferProjection"

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
    local ir, types, mentions = TransferProjection.Build(
        args, pending, GiftContext.MAX_ITEMS)
    if not ir then
        return contextFailure("gift_items_unavailable", view, args, pending)
    end

    local options = {
        speaker = "npc",
        source = "gift_transfer",
    }
    local ok
    local recorded
    local event
    if internal and type(internal.RecordContextTurn) == "function" then
        ok, recorded, event = pcall(
            internal.RecordContextTurn, view, ir, options
        )
    else
        ok, recorded, event = pcall(
            context.RecordTurn, context, ir, options
        )
    end
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
