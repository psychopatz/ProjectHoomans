local T = require "tests/support/test"
T.addPackagePaths()

local originalPNC = PNC
local originalRequire = require
local primaryMessages = {}
local targetMessages = {}
local transferRecorded = false

local primarySession = {
    currentNodeID = "block:gift",
    queue = {},
    append = function(_, speaker, value, metadata)
        primaryMessages[#primaryMessages + 1] = {
            speaker = speaker, value = value, metadata = metadata,
        }
    end,
}
local targetSession = {
    append = function(_, speaker, value, metadata)
        targetMessages[#targetMessages + 1] = {
            speaker = speaker, value = value, metadata = metadata,
        }
    end,
}
local group = {
    closed = false,
    PrimarySession = function() return primarySession end,
}
local targetView = {
    spec = { npcID = "npc-alice", context = {} },
    session = targetSession,
    groupConversation = group,
}

PNC = {
    Conversation = {
        Composer = {
            Internal = {
                NEEDS_FALLBACK_SOURCE = {},
                GIFT_OFFER_KEYS = { "gift.offer" },
                ActiveView = function(npcID)
                    return npcID == "npc-alice" and targetView or nil
                end,
                AppendDiary = function() return true end,
                DialoguePayload = function(_, key, _, args)
                    return { key = key, args = args, fallback = key }
                end,
                FormatGiftOffer = function()
                    return {
                        itemName = "Apple",
                        itemSummary = "1 Apple",
                        count = 1,
                    }
                end,
                GiftOfferKey = function() return "gift.offer" end,
                ReceiveRelationshipAfter = function() return true end,
                ResolvedDialogue = function(value)
                    return type(value) == "table" and value.fallback
                        or tostring(value or "")
                end,
            },
        },
        Registry = { GetBlock = function() return nil end },
        TextLoader = { EnsureSource = function() return true end },
    },
    Semantics = {
        GiftLifecycle = {
            IsHandled = function() return false end,
            Get = function() return nil end,
            MarkHandled = function() return true end,
        },
        GiftContext = {
            RecordTransfer = function()
                transferRecorded = true
                return true
            end,
        },
    },
}

-- Isolate this composer spoke from UI and conversation-definition loading.
require = function() return true end
local Composer = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Conversation/Blocks/ConversationComposer/PNC_ConversationComposer_Gifts.lua"
)
require = originalRequire

T.truthy(Composer.ReceiveGiftResult({
    success = true,
    npcId = "npc-alice",
    itemTypes = { "Base.Apple" },
    itemIDs = { "npc-item-apple" },
    requestId = "group-gift-result",
}), "group gift result is accepted")
T.truthy(transferRecorded,
    "the target NPC keeps its transfer context and lifecycle")
T.equal(#targetMessages, 0,
    "the secondary NPC's private session does not split the group dialogue")
T.equal(#primaryMessages, 2,
    "the authoritative gift offer and reaction enter the shared session")
T.equal(primaryMessages[1].speaker, "player",
    "the shared gift history preserves the player's offer")
T.equal(primaryMessages[2].speaker, "npc",
    "the shared gift history preserves the recipient's reaction")

PNC = originalPNC
T.finish("pnc_semantic_gift_result_routing_smoke")
