local T = require "tests/support/test"
T.addPackagePaths()

PNC = {
    Registry = {},
    Network = {},
    ServerInventory = { Internal = {} },
}

local lease = { token = "lease-token" }
local record = {
    id = "npc-alice",
    runtime = { conversationLease = lease },
}
local transferCount = 0
local authorizationCount = 0

PNC.Registry.Get = function(id)
    return tostring(id) == record.id and record or nil
end
PNC.ServerInventory.Internal.canGift = function()
    authorizationCount = authorizationCount + 1
    return true, "gift_authorized", lease
end
PNC.ServerInventory.Internal.canManage = function()
    return true, "authorized"
end
PNC.ServerInventory.Internal.notify = function(_, success, reason, args, details)
    return success == true, reason, {
        success = success == true,
        reason = reason,
        npcId = args.id,
        requestId = args.requestId,
        gift = args.gift == true,
        details = details,
    }
end
PNC.ServerInventory.Internal.checkRevision = function()
    return true, 7
end
PNC.ServerInventory.Internal.transferPlayerToNPC = function()
    transferCount = transferCount + 1
    return true, "transferred_to_npc", {
        itemTypes = { "Base.Apple" },
        itemIDs = { "npc-item-1" },
    }
end
PNC.ServerInventory.Internal.transferNPCToPlayer = function()
    return false, "unused"
end
PNC.ServerInventory.Internal.applyGiftEffect = function(_, _, _, details)
    details.giftEffect = { kind = "food", disposition = "liked" }
    return details
end

T.load(
    "ProjectHoomans",
    "server",
    "PNC/Server/ServerInventory/PNC_ServerInventory_Transfer.lua"
)
local Service = PNC.ServerInventory
local player = {}
local request = {
    id = record.id,
    direction = "player_to_npc",
    itemIDs = { "player-item-1" },
    inventoryRevision = 7,
    gift = true,
    conversationToken = "lease-token",
    requestId = "gift-request-1",
}

local first, firstReason, firstPayload = Service.Transfer(player, request)
T.equal(first, true, "first gift transfer succeeds")
T.equal(firstReason, "transferred_to_npc", "first gift reason is preserved")
T.equal(firstPayload.gift, true, "gift result is marked for client routing")
T.truthy(lease.processedGiftRequests["gift-request-1"],
    "gift result is cached in the transient lease")
local replayEligible = true and player and record
    and request.direction == "player_to_npc"
    and lease and tostring(lease.token or "")
        == tostring(request.conversationToken or "")
    and not (PNC.Const and PNC.Const.TACTICAL_CLASS_HOSTILE ~= nil
        and tostring(record.tacticalClass or "")
            == tostring(PNC.Const.TACTICAL_CLASS_HOSTILE))
T.equal(replayEligible, true, "test request is eligible for replay")

local second, secondReason, secondPayload = Service.Transfer(player, request)
T.equal(second, true, "duplicate gift returns the original success")
T.equal(secondReason, firstReason,
    "duplicate gift returns the original reason")
T.equal(transferCount, 1,
    "duplicate gift request does not transfer the item twice")
T.equal(authorizationCount, 1,
    "duplicate gift is replayed before reauthorizing the lease")
T.equal(secondPayload.details.itemIDs[1], "npc-item-1",
    "duplicate gift replays authoritative item identity")

request.requestId = "gift-request-2"
local third = Service.Transfer(player, request)
T.equal(third, true, "a new gift request remains available")
T.equal(transferCount, 2, "a new request performs a new transfer")

T.finish("pnc_semantic_gift_idempotency_smoke")
