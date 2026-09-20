-- Shared runtime registry for seed-derived backstories and compact gossip IDs.
require "PNC/Conversation/Blocks/PNC_ConversationTextLoader"

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Memory = PNC.Conversation.Memory or {}
PNC.Conversation.Memory = Memory

Memory.BACKSTORY_SOURCE = Memory.BACKSTORY_SOURCE or {
    modID = "ProjectHoomans",
    pathPattern = "media/conversation/backstory/shared/{language}/facts.json",
    domain = "pnc.backstory.shared.facts",
}
Memory.GOSSIP_SOURCE = Memory.GOSSIP_SOURCE or {
    modID = "ProjectHoomans",
    pathPattern = "media/conversation/gossip/shared/{language}/templates.json",
    domain = "pnc.gossip.shared.templates",
}

Memory._registry = Memory._registry or {
    backstoryByID = {},
    backstoryKinds = {},
    backstoryKindSet = {},
    backstoryBuckets = {
        shared = {},
        colonist = {},
        neutral = {},
        hostile = {},
    },
    profileCache = {},
    profileOrder = {},
    profileCount = 0,
    profileNext = 1,
    gossipByID = {},
    gossipByCode = {},
    gossipByEvent = {},
    gossipList = {},
    textSources = {},
    textSourceByKey = {},
    textCache = {},
    textValidation = nil,
}

-- Conversation memory may be required before common definitions run. Initialize
-- its registry buckets independently so reloads or partial module ordering do
-- not leave the event registrator with missing tables.
Memory._registry.eventByID = Memory._registry.eventByID or {}
Memory._registry.eventByCode = Memory._registry.eventByCode or {}
Memory._registry.eventBySource = Memory._registry.eventBySource or {}
Memory._registry.dynamicEventBySource =
    Memory._registry.dynamicEventBySource or {}
Memory._registry.eventSourceByCode =
    Memory._registry.eventSourceByCode or {}
Memory._registry.dynamicEventCount =
    tonumber(Memory._registry.dynamicEventCount) or 0

require "PNC/Conversation/Memory/PNC_ConversationMemory_Text"
require "PNC/Conversation/Memory/PNC_ConversationMemory_Backstories"
require "PNC/Conversation/Memory/PNC_ConversationMemory_BackstoryContext"
require "PNC/Conversation/Memory/PNC_ConversationMemory_Gossip"
require "PNC/Conversation/Memory/PNC_ConversationMemory_Events"

return Memory
