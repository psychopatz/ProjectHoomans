if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ServerInventory = PNC.ServerInventory or {}
PNC.ServerInventory.Internal = PNC.ServerInventory.Internal or {}

local Service = PNC.ServerInventory
local Internal = Service.Internal
local Registry = PNC.Registry
local Network = PNC.Network
local canGift = Internal.canGift
local canManage = Internal.canManage
local notify = Internal.notify
local checkRevision = Internal.checkRevision
local transferPlayerToNPC = Internal.transferPlayerToNPC
local transferNPCToPlayer = Internal.transferNPCToPlayer
local applyGiftEffect = Internal.applyGiftEffect
local auditInventoryRequest = Internal.auditInventoryRequest

local MAX_PROCESSED_GIFTS = 32

local function processedGiftCache(lease)
    if type(lease) ~= "table" then return nil end
    lease.processedGiftRequests = lease.processedGiftRequests or {}
    lease.processedGiftRequestOrder = lease.processedGiftRequestOrder or {}
    return lease.processedGiftRequests
end

local function rememberGift(lease, requestID, response)
    local cache = processedGiftCache(lease)
    if not cache or requestID == "" then return end
    if cache[requestID] == nil then
        lease.processedGiftRequestOrder[#lease.processedGiftRequestOrder + 1] =
            requestID
    end
    cache[requestID] = response
    while #lease.processedGiftRequestOrder > MAX_PROCESSED_GIFTS do
        local old = table.remove(lease.processedGiftRequestOrder, 1)
        cache[old] = nil
    end
end

function Service.Transfer(player, args)
    args = args or {}
    local record = args.id and Registry.Get(tostring(args.id)) or nil
    local giftMode = args.gift == true
    local requestID = tostring(args.requestId or "")
    local lease = record and record.runtime
        and record.runtime.conversationLease or nil
    local processed = giftMode and processedGiftCache(lease) or nil
    local tacticalClass = tostring(record and record.tacticalClass or "")
    local hostileClass = Const and Const.TACTICAL_CLASS_HOSTILE
    local replayEligible = giftMode and player and record
        and args.direction == "player_to_npc"
        and lease and tostring(lease.token or "")
            == tostring(args.conversationToken or "")
        and not (hostileClass ~= nil
            and tacticalClass == tostring(hostileClass))
    if replayEligible and processed and requestID ~= ""
        and processed[requestID]
    then
        local cached = processed[requestID]
        local success, reason, payload = notify(
            player, cached.success, cached.reason, args, cached.details
        )
        if auditInventoryRequest then
            auditInventoryRequest(
                "server_transfer", "replay", record, args,
                "previously_allowed", "duplicate_request", "cached",
                success, reason
            )
        end
        return success, reason, payload
    end
    local allowed, reason
    if giftMode then
        allowed, reason, lease = canGift(player, record, args)
    else
        allowed, reason = canManage(player, record)
    end
    local authorityReason = reason
    if not allowed then
        local failed, failedReason, payload = notify(
            player, false, reason, args
        )
        if auditInventoryRequest then
            auditInventoryRequest(
                "server_transfer", "rejected", record, args,
                "denied", reason, "not_run", failed, failedReason
            )
        end
        return failed, failedReason, payload
    end
    processed = giftMode and processedGiftCache(lease) or nil
    if processed and requestID ~= "" and processed[requestID] then
        local cached = processed[requestID]
        local success, cachedReason, payload = notify(
            player, cached.success, cached.reason, args, cached.details
        )
        if auditInventoryRequest then
            auditInventoryRequest(
                "server_transfer", "replay", record, args,
                "allowed", authorityReason, "cached", success, cachedReason
            )
        end
        return success, cachedReason, payload
    end
    local revisionOK, sinceRevision, revisionDetails = checkRevision(record, args)
    if not revisionOK then
        if Network and Network.SendCharacterPayload then
            Network.SendCharacterPayload(player, record)
        end
        local failed, failedReason, failedPayload = notify(
            player, false, sinceRevision, args, revisionDetails)
        if giftMode and requestID ~= "" then
            rememberGift(lease, requestID, {
                success = failed,
                reason = failedReason,
                details = revisionDetails,
            })
        end
        if auditInventoryRequest then
            auditInventoryRequest(
                "server_transfer", "stale_revision", record, args,
                "allowed", authorityReason, "not_run", failed, failedReason,
                revisionDetails and revisionDetails.currentInventoryRevision
            )
        end
        return failed, failedReason, failedPayload
    end
    local success
    local details
    if args.direction == "player_to_npc" then
        success, reason, details = transferPlayerToNPC(
            player, record, args, sinceRevision
        )
    elseif args.direction == "npc_to_player" then
        success, reason = transferNPCToPlayer(player, record, args, sinceRevision)
    else
        success, reason = false, "invalid_direction"
    end
    if success and giftMode then
        details = applyGiftEffect(player, record, args, details)
    end
    local resultSuccess, resultReason, resultPayload = notify(
        player, success, reason, args, details)
    if giftMode and requestID ~= "" then
        rememberGift(lease, requestID, {
            success = resultSuccess,
            reason = resultReason,
            details = details,
        })
    end
    if auditInventoryRequest then
        local adapterResult = success == true and "committed"
            or (args.direction == "player_to_npc"
                or args.direction == "npc_to_player") and "failed"
            or "not_run"
        auditInventoryRequest(
            "server_transfer",
            resultSuccess and "completed" or "rejected",
            record,
            args,
            "allowed",
            authorityReason,
            adapterResult,
            resultSuccess,
            resultReason,
            sinceRevision
        )
    end
    return resultSuccess, resultReason, resultPayload
end
