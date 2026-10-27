-- Compatibility entry point for tool-result speech.
--
-- Tool handlers own execution facts. Semantic ResponseCatalog owns the
-- meaning/variant choice. This module keeps the historical Build API for
-- PBrainZ and older callers, but it no longer reads or selects from the
-- former first-party ToolReply wording table.

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Semantics = PNC.Semantics or {}
PNC.Conversation.ToolReplies = PNC.Conversation.ToolReplies or {}

local Replies = PNC.Conversation.ToolReplies
local Catalog = PNC.Semantics.ResponseCatalog
if type(Catalog) ~= "table" or type(Catalog.Get) ~= "function" then
    Catalog = require "PNC/Semantics/PNC_SemanticDialogueResponseCatalog"
end
local Authority = PNC.Semantics.RealizationAuthority
if type(Authority) ~= "table" or type(Authority.Resolve) ~= "function" then
    Authority = require "PNC/Semantics/PNC_SemanticDialogueRealizationAuthority"
end
local SpeechRealization = PNC.Semantics.SpeechRealization
if type(SpeechRealization) ~= "table"
    or type(SpeechRealization.Apply) ~= "function"
then
    SpeechRealization = require "PNC/Semantics/PNC_SpeechRealization"
end
local unpackValues = table.unpack or unpack

Replies.VERSION = 3
Replies.MAX_LAST_VARIANTS = 256
Replies.SELECTION_SOURCE = "semantic_response_catalog"
Replies.CATALOG = nil

local lastVariant = Replies.lastVariant or {}
Replies.lastVariant = lastVariant
local lastVariantOrder = Replies.lastVariantOrder or {}
Replies.lastVariantOrder = lastVariantOrder

local function normalized(value)
    value = string.lower(tostring(value or ""))
    value = string.gsub(value, "[%s%-]", "_")
    return value
end

local function cleanName(context)
    context = type(context) == "table" and context or {}
    local name = context.npc_name or context.npcName
    name = tostring(name or "")
    name = string.gsub(name, "[\r\n]", " ")
    name = string.gsub(name, "^%s+", "")
    name = string.gsub(name, "%s+$", "")
    if name == "" or name == "unknown-npc" or name == "the NPC" then
        return nil
    end
    return name
end

local function resultSalt(result, context)
    context = type(context) == "table" and context or {}
    local replyContext = result and type(result.replyContext) == "table"
        and result.replyContext or {}
    return table.concat({
        tostring(context.request_id or context.requestID or ""),
        tostring(result and result.id or ""),
        tostring(result and result.reaction or result and result.name or ""),
        tostring(result and result.subtype or replyContext.subtype or ""),
    }, ":")
end

local function rememberSelection(key, realizationID)
    key = tostring(key or "")
    if key == "" then return end
    if lastVariant[key] == nil then
        while #lastVariantOrder >= Replies.MAX_LAST_VARIANTS do
            local oldest = table.remove(lastVariantOrder, 1)
            lastVariant[oldest] = nil
        end
        lastVariantOrder[#lastVariantOrder + 1] = key
    end
    lastVariant[key] = realizationID
end

local function copiedContext(context)
    local output = {}
    for key, value in pairs(type(context) == "table" and context or {}) do
        if type(key) == "string" and type(value) ~= "function" then
            output[key] = value
        end
    end
    return output
end

local function statusFor(result)
    if result and result.accepted == true then
        if result.authoritative == false
            and normalized(result.reason) == "network_queued"
        then
            return "queued"
        end
        return "accepted"
    end
    return "rejected"
end

local function socialPool(result)
    local status = statusFor(result)
    local reason = normalized(result and result.reason)
    local reaction = normalized(result and (result.reaction or result.kind))
    local replyContext = result and type(result.replyContext) == "table"
        and result.replyContext or {}
    local subtype = normalized(result and result.subtype
        or replyContext.subtype)
    local key
    local candidate
    if status == "rejected" then
        key = reason == "positive_cooldown_active"
            and reason or subtype ~= "" and subtype or reason
        candidate = "semantic.tool_reply.social.rejected."
            .. (key ~= "" and key or "generic")
        if Catalog.Get(candidate) then return candidate end
        return "semantic.tool_reply.social.rejected.generic"
    end
    if subtype ~= "" then
        candidate = "semantic.tool_reply.social." .. status .. "." .. subtype
        if Catalog.Get(candidate) then return candidate end
    end
    if reaction ~= "" then
        candidate = "semantic.tool_reply.social." .. status .. "." .. reaction
        if Catalog.Get(candidate) then return candidate end
    end
    return "semantic.tool_reply.social." .. status .. ".generic"
end

local function askNamePool(result, context)
    local replyContext = result and type(result.replyContext) == "table"
        and result.replyContext or {}
    if replyContext.outcome == "identity_exchange_prompt" then
        return "semantic.tool_reply.ask_name.prompt"
    end
    if not result or result.accepted ~= true then
        return "semantic.tool_reply.ask_name.rejected"
    end
    return cleanName(context) ~= nil
        and "semantic.tool_reply.ask_name.named"
        or "semantic.tool_reply.ask_name.unnamed"
end

local function orderPool(result)
    if not result or result.accepted ~= true then
        return "semantic.tool_reply.order.rejected"
    end
    local command = normalized(result.commandID or result.command_id)
    command = string.gsub(command, "^order_", "")
    if command == "follow" or command == "stay" or command == "camp" then
        return "semantic.tool_reply.order." .. command
    end
    return "semantic.tool_reply.order.accepted.generic"
end

local function semanticContext(result, context)
    local output = copiedContext(context)
    local replyContext = result and type(result.replyContext) == "table"
        and result.replyContext or {}
    output.toolStatus = statusFor(result)
    output.toolReason = normalized(result and result.reason)
    output.toolReaction = normalized(result and (result.reaction or result.kind))
    output.toolSubtype = normalized(result and result.subtype
        or replyContext.subtype)
    output.toolOutcome = normalized(replyContext.outcome)
    output.commandID = result and (result.commandID or result.command_id)
    output.commandReason = result and (result.reason or result.commandReason)
    return output
end

local function priority(results, name)
    for _, result in ipairs(results or {}) do
        if tostring(result and result.name or "") == name then
            return result
        end
    end
    return nil
end

local function formatText(realization, args)
    if type(realization) ~= "table" then return nil end
    local fallback = tostring(realization.fallback or "")
    local translation = PNC.Translation
    if translation and type(translation.TrFormat) == "function" then
        local ok, value = pcall(translation.TrFormat,
            realization.templateID, fallback, unpackValues(args or {}))
        if ok and type(value) == "string" and value ~= "" then
            return value
        end
    end
    if args and args[1] ~= nil then
        local ok, value = pcall(string.format, fallback, unpackValues(args))
        if ok then return value end
    end
    return fallback
end

local function buildDetailed(result, context)
    local name = tostring(result and result.name or "")
    local poolID
    local args = {}
    if name == "social_react" then
        poolID = socialPool(result)
    elseif name == "ask_name" then
        poolID = askNamePool(result, context)
        local npcName = cleanName(context)
        if npcName then args[1] = npcName end
    elseif string.sub(name, 1, 6) == "order_" then
        poolID = orderPool(result)
    else
        return nil, "tool_reply_not_supported"
    end

    local semantic = Authority.Resolve({
        poolID = poolID,
        responsePlanID = poolID,
        realizationFamily = poolID,
        act = "REPLY",
        topic = "tool_reply",
        context = semanticContext(result, context),
        salt = resultSalt(result, context),
    })
    if not semantic then return nil, "semantic_tool_reply_unavailable" end
    local rendered = SpeechRealization.Apply({
        selectionID = semantic.realizationID,
        templateID = semantic.templateID,
        fallback = semantic.fallback,
        args = args,
        plan = semantic.responsePlan,
    }, semanticContext(result, context))
    if type(rendered) == "table" then
        local renderedTurn = type(rendered.renderPlan) == "table"
            and rendered.renderPlan.turns
            and rendered.renderPlan.turns[1] or nil
        local renderedSegment = type(renderedTurn) == "table"
            and renderedTurn.segments and renderedTurn.segments[1] or nil
        semantic.templateID = type(renderedSegment) == "table"
            and (renderedSegment.templateID or rendered.renderTemplateID)
            or rendered.renderTemplateID or rendered.templateID
            or semantic.templateID
        semantic.fallback = type(renderedSegment) == "table"
            and (renderedSegment.fallback or rendered.fallback)
            or rendered.fallback or semantic.fallback
        semantic.responsePlan = rendered.plan or semantic.responsePlan
        semantic.args = rendered.args or args
        semantic.realizationFamily = rendered.realizationFamily
            or semantic.realizationFamily
    end
    local text = formatText(semantic, semantic.args or args)
    if not text or text == "" then
        return nil, "semantic_tool_reply_text_unavailable"
    end

    -- Keep the historical bounded diagnostic history keyed by result, while
    -- the catalog remains the only semantic anti-repeat selector.
    rememberSelection(poolID .. ":" .. resultSalt(result, context),
        semantic.realizationID)
    return {
        text = text,
        semanticOwned = true,
        selectionSource = semantic.selectionSource,
        contentOwner = semantic.contentOwner,
        responsePlanID = semantic.responsePlanID,
        realizationFamily = semantic.realizationFamily,
        realizationID = semantic.realizationID,
        templateID = semantic.templateID,
        responsePlan = semantic.responsePlan,
        poolID = poolID,
    }
end

function Replies.BuildDetailed(results, context)
    if type(results) ~= "table" or #results == 0 then return nil end
    context = type(context) == "table" and context or {}
    local result = priority(results, "ask_name")
    if result then return buildDetailed(result, context) end
    result = priority(results, "social_react")
    if result then return buildDetailed(result, context) end
    for _, candidate in ipairs(results) do
        if string.sub(tostring(candidate and candidate.name or ""), 1, 6)
            == "order_"
        then
            return buildDetailed(candidate, context)
        end
    end
    return nil, "tool_reply_not_supported"
end

function Replies.Build(results, context)
    local detailed = Replies.BuildDetailed(results, context)
    return detailed and detailed.text or nil
end

function Replies.Reset()
    for key, _ in pairs(lastVariant) do lastVariant[key] = nil end
    for index = #lastVariantOrder, 1, -1 do
        lastVariantOrder[index] = nil
    end
end

return Replies
