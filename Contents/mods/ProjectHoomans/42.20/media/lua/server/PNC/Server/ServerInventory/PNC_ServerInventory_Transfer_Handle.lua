-- Server inventory transfer authority transaction.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.ServerInventory = PNC.ServerInventory or {}
PNC.ServerInventory.Internal = PNC.ServerInventory.Internal or {}

local Service = PNC.ServerInventory
local Internal = Service.Internal
local H = Internal.Transfer
if type(H) ~= "table" then return Service end

local Registry = H.Registry
local Network = H.Network
local canGift = H.canGift
local canManage = H.canManage
local notify = H.notify
local checkRevision = H.checkRevision
local transferPlayerToNPC = H.transferPlayerToNPC
local transferNPCToPlayer = H.transferNPCToPlayer
local applyGiftEffect = H.applyGiftEffect
local auditInventoryRequest = H.auditInventoryRequest
local medicalSupplyGiftTask = H.medicalSupplyGiftTask
local processedGiftCache = H.processedGiftCache
local rememberGift = H.rememberGift

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
    local medicalTask
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
    if args.medicalSupplyTaskID ~= nil
        or args.medicalSupplyRequestID ~= nil
    then
        local supplyValid
        local supplyResult
        if giftMode and args.direction == "player_to_npc" then
            supplyValid, supplyResult = medicalSupplyGiftTask(
                player, record, args)
        else
            supplyValid, supplyResult = false,
                "medical_supply_request_invalid"
        end
        if not supplyValid then
            local failed, failedReason, failedPayload = notify(
                player, false, supplyResult, args)
            if giftMode and requestID ~= "" then
                rememberGift(lease, requestID, {
                    success = failed,
                    reason = failedReason,
                })
            end
            if auditInventoryRequest then
                auditInventoryRequest(
                    "server_transfer", "medical_supply_rejected", record,
                    args, "allowed", authorityReason, "not_run", failed,
                    failedReason, sinceRevision
                )
            end
            return failed, failedReason, failedPayload
        end
        medicalTask = supplyResult
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
    if success and medicalTask then
        local medicalExecutor = PNC.MedicalCareExecutor
        if medicalExecutor
            and type(medicalExecutor.FulfillBandageSupport) == "function"
        then
            medicalExecutor.FulfillBandageSupport(medicalTask.id)
        end
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

return Service

