-- Gossip selection, rendering and compact network projection.
require "PNC/Conversation/Memory/PNC_ConversationMemory_GossipCatalog"
local Memory = PNC.Conversation.Memory
local Data = Memory._registry

local function matchesSpeaker(entry, speakerClass)
    if not speakerClass or not entry.speakerClasses then
        return true
    end
    for i = 1, #entry.speakerClasses do
        if entry.speakerClasses[i] == speakerClass then
            return true
        end
    end
    return false
end

function Memory.GetGossipTemplates(criteria)
    if type(criteria) == "string" then
        criteria = { event = criteria }
    end
    criteria = type(criteria) == "table" and criteria or {}
    local candidates = Data.gossipList
    if criteria.event ~= nil then
        candidates = Data.gossipByEvent[tostring(criteria.event)] or {}
    end
    local results = {}
    local speakerClass = criteria.speakerClass
        and string.lower(tostring(criteria.speakerClass)) or nil
    local sentiment = criteria.sentiment
        and string.lower(tostring(criteria.sentiment)) or nil
    local tone = criteria.tone and string.lower(tostring(criteria.tone)) or nil
    for i = 1, #candidates do
        local entry = candidates[i]
        if (not sentiment or entry.sentiment == sentiment)
            and (not tone or entry.tone == tone)
            and matchesSpeaker(entry, speakerClass)
        then
            results[#results + 1] = entry
        end
    end
    return results
end

function Memory.SelectGossipTemplate(event, seed, salt, filters)
    filters = type(filters) == "table" and filters or {}
    local candidates = Memory.GetGossipTemplates({
        event = event,
        sentiment = filters.sentiment,
        tone = filters.tone,
        speakerClass = filters.speakerClass,
    })
    local totalWeight = 0
    for i = 1, #candidates do
        totalWeight = totalWeight + candidates[i].weight
    end
    if totalWeight <= 0 then
        return nil
    end
    local identityAPI = PNC.Identity
    local roll
    if identityAPI and type(identityAPI.Range) == "function" then
        roll = identityAPI.Range(
            seed,
            "pnc:gossip:" .. tostring(event) .. ":" .. tostring(salt or ""),
            1,
            totalWeight
        )
    else
        roll = (math.floor(tonumber(seed) or 1) % totalWeight) + 1
    end
    for i = 1, #candidates do
        local entry = candidates[i]
        if roll <= entry.weight then
            return entry
        end
        roll = roll - entry.weight
    end
    return candidates[#candidates]
end

function Memory.GetGossipText(template, language)
    local entry = type(template) == "table"
        and template or Memory.GetGossipTemplate(template)
    if not entry then
        return nil, "unknown_gossip_template"
    end
    return Memory.GetText(entry.textSource, entry.textKey, language)
end

function Memory.RenderGossipTemplate(template, arguments, language)
    local text, reason = Memory.GetGossipText(template, language)
    if not text then
        return nil, reason
    end
    return Memory.RenderText(text, arguments)
end

function Memory.BuildGossipPacket(template, arguments)
    local entry = type(template) == "table"
        and template or Memory.GetGossipTemplate(template)
    if not entry then
        return nil, "unknown_gossip_template"
    end
    if #entry.arguments == 0 then
        return { c = entry.code }
    end
    arguments = type(arguments) == "table" and arguments or {}
    local packedArguments = {}
    for i = 1, #entry.arguments do
        local name = entry.arguments[i]
        local value = arguments[name]
        if value == nil then
            value = arguments[i]
        end
        packedArguments[i] = value == nil and "" or value
    end
    return { c = entry.code, a = packedArguments }
end

function Memory.RenderGossipPacket(packet, language)
    if type(packet) ~= "table" then
        return nil, "gossip_packet_required"
    end
    local entry = Memory.GetGossipTemplateByCode(packet.c)
    if not entry then
        return nil, "unknown_gossip_code"
    end
    local arguments = {}
    local packedArguments = type(packet.a) == "table" and packet.a or {}
    for i = 1, #entry.arguments do
        arguments[entry.arguments[i]] = packedArguments[i]
    end
    return Memory.RenderGossipTemplate(entry, arguments, language)
end
