-- Fast, result-aware presentation for tool-only NPC turns.
--
-- Gameplay tools remain authoritative elsewhere.  This module only chooses a
-- short NPC line after the client has received the local execution result. It
-- is deterministic, avoids immediate repetition, and does not require a
-- second provider request.

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.ToolReplies = PNC.Conversation.ToolReplies or {}

require "PNC/Conversation/PNC_ConversationToolReplyCatalog"

local Replies = PNC.Conversation.ToolReplies
local CATALOG = PNC.Conversation.ToolReplyCatalog or {}

Replies.VERSION = 1

local lastVariant = Replies.lastVariant or {}
Replies.lastVariant = lastVariant

Replies.CATALOG = CATALOG

local function normalized(value)
    value = string.lower(tostring(value or ""))
    value = string.gsub(value, "[%s%-]", "_")
    return value
end

local function hash(value)
    local output = 0
    value = tostring(value or "")
    for index = 1, #value do
        output = (output * 31 + string.byte(value, index)) % 2147483647
    end
    return output
end

local function choose(key, values, salt)
    if type(values) ~= "table" or #values == 0 then return nil end
    local count = #values
    local index = (hash(tostring(salt or "") .. ":" .. key) % count) + 1
    local previous = lastVariant[key]
    if count > 1 and previous == index then
        index = index % count + 1
    end
    lastVariant[key] = index
    return values[index]
end

local function formatName(line, name)
    local ok, formatted = pcall(string.format, line, name)
    return ok and formatted or line
end

local function contextName(context)
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

local function resultReason(result)
    return normalized(result and result.reason or "")
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

local function socialReply(result, context)
    local reaction = normalized(result and (result.reaction or result.kind))
    local reason = resultReason(result)
    local replyContext = result and type(result.replyContext) == "table"
        and result.replyContext or {}
    local subtype = normalized(result and result.subtype
        or replyContext.subtype)
    local status
    local pool
    local line
    if result and result.accepted == true then
        status = result.authoritative == false
            and reason == "network_queued" and "queued" or "accepted"
    else
        status = "rejected"
    end
    pool = CATALOG.social_react[status]
    if status == "rejected" then
        -- Cooldown text is more useful than a subtype boundary because it
        -- tells the player exactly why the action cannot apply today.
        pool = reason == "positive_cooldown_active" and pool[reason]
            or pool[subtype] or pool[reason] or pool.generic
    else
        pool = pool[subtype] or pool[reaction] or pool.generic
    end
    line = choose(
        "social_react:" .. reaction .. ":" .. subtype .. ":"
            .. status .. ":" .. reason,
        pool,
        resultSalt(result, context)
    )
    return line
end

local function nameReply(result, context)
    local line
    if not result or result.accepted ~= true then
        line = choose("ask_name:rejected", CATALOG.ask_name.rejected,
            resultSalt(result, context))
        return line
    end
    local name = contextName(context)
    if name then
        line = choose("ask_name:named", CATALOG.ask_name.named,
            resultSalt(result, context))
        return formatName(line, name)
    end
    return choose("ask_name:unnamed", CATALOG.ask_name.unnamed,
        resultSalt(result, context))
end

local function orderReply(result, context)
    local command = normalized(result and (result.commandID or result.command_id))
    command = string.gsub(command, "^order_", "")
    local group = result and result.accepted == true and "accepted" or "rejected"
    local pool
    if group == "accepted" then
        pool = CATALOG.orders.accepted[command]
            or CATALOG.orders.accepted.generic
    else
        pool = CATALOG.orders.rejected
    end
    return choose(
        "order:" .. command .. ":" .. group,
        pool,
        resultSalt(result, context)
    )
end

local function priority(results, name)
    for _, result in ipairs(results or {}) do
        if tostring(result and result.name or "") == name then
            return result
        end
    end
    return nil
end

function Replies.Build(results, context)
    if type(results) ~= "table" or #results == 0 then return nil end
    context = type(context) == "table" and context or {}
    local result = priority(results, "ask_name")
    if result then return nameReply(result, context) end
    result = priority(results, "social_react")
    if result then return socialReply(result, context) end
    for _, candidate in ipairs(results) do
        if string.sub(tostring(candidate and candidate.name or ""), 1, 6)
            == "order_"
        then
            return orderReply(candidate, context)
        end
    end
    return nil
end

function Replies.Reset()
    for key, _ in pairs(lastVariant) do lastVariant[key] = nil end
end

return Replies
