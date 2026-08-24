-- Server-authoritative NPC literature reading.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.RecipeBookService = PNC.RecipeBookService or {}
local Service = PNC.RecipeBookService
Service.Commands = Service.Commands or {}

local CoreInventory = require "PsychopatzCore/Inventory/PsychopatzInventory"

local function nativeFromRecord(record)
    if not record or not CoreInventory.decodeItem then return nil end
    local ok, item = pcall(CoreInventory.decodeItem, record)
    return ok and item or nil
end

local function contextBook(player, recordIndex)
    local context, reason = PNC.ProductionContext.ForPlayer(player)
    if not context then return nil, reason end
    local info
    info, reason = PNC.ColonyStorageService.ReadProductionRecord(
        context.storage.id, recordIndex)
    if not info then return nil, reason end
    local item = nativeFromRecord(info.record)
    local details = PNC.RecipeKnowledge.Queries.BookDetails(
        item, info.fullType)
    if not details.relevant then return nil, "BOOK_NOT_RELEVANT" end
    return { context = context, info = info, details = details }
end

function Service.Commands.QueueRead(player, recordIndex)
    local selected, reason = contextBook(player, recordIndex)
    if not selected then return nil, reason end
    local context, info, details = selected.context,
        selected.info, selected.details
    local reservation
    reservation, reason = PNC.ColonyStorageService.ReserveProductionRecord(
        context.storage.id, recordIndex, 1, "research:book")
    if not reservation then return nil, reason end
    local order
    order, reason = PNC.WorkService.Commands.Queue({
        operation = "READ_BOOK", colonyId = context.colony.id,
        factionId = context.faction.id, baseId = context.base.id,
        requiredWork = math.max(30, 60 + #details.recipeKeys * 15),
        requiredSkills = {},
        payload = PNC.WorkInputService.Bind({ mode = "book",
            storageId = context.storage.id, reservationId = reservation.id,
            bookFullType = info.fullType, bookRecord = info.record },
            context.storage.id, reservation.id, "book_reading")
    })
    if not order then
        PNC.ColonyStorageService.ReleaseProductionReservation(reservation.id)
    end
    return order, reason
end

local function returnBook(order, consumeOnRead)
    local input = order.payload and order.payload.input or nil
    if not input then return true end
    local worker = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(order.workerId) or nil
    if input.staged == true then
        if not consumeOnRead then
            local ok, reason = PNC.ColonyStorageService
                .ReturnCollectedProductionRecords(order.payload.storageId,
                    worker, input.itemIds or {}, input.records or {})
            if not ok then return false, reason end
        end
        PNC.ColonyStorageService.ForgetProductionTransaction(
            order.payload.storageId, order.id)
    elseif input.reservationId and input.reservationId ~= "" then
        local ok, reason
        if consumeOnRead then
            ok, reason = PNC.ColonyStorageService.CommitProductionReservation(
                input.reservationId, order.id, "book_reading",
                order.payload.storageId, order.workerId, "book_consumed")
        else
            ok, reason = PNC.ColonyStorageService
                .ReleaseProductionReservation(input.reservationId)
        end
        if not ok then return false, reason end
    end
    input.committed, input.staged = true, false
    input.reservationId, input.itemIds, input.records = nil, nil, nil
    PNC.WorkRepository.MarkDirty()
    return true
end

local function nativeBook(input, body)
    if not body or not PNC.SupplyInventoryInternal
        or not PNC.SupplyInventoryInternal.NativeCandidates
    then return nil end
    local candidates = PNC.SupplyInventoryInternal.NativeCandidates(
        body, (input.records or {})[1])
    return candidates[1] and candidates[1].item or nil
end

local function complete(order)
    local payload = order.payload or {}
    local input = payload.input or {}
    local worker = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(order.workerId) or nil
    if not worker then return false, "WORKER_UNAVAILABLE" end
    local body = PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(worker.id) or nil
    local item = body and nativeBook(input, body) or nil
    if not item then item = nativeFromRecord(payload.bookRecord) end
    local ok, reason, details = PNC.RecipeKnowledge.Commands.ReadBook(worker, item, {
        fullType = payload.bookFullType, liveBody = body, nativeItem = item,
    })
    if not ok then return false, reason end
    if body then PNC.RecipeKnowledge.BindLiveBody(worker, body) end
    return returnBook(order, reason == "BOOK_READ"
        and details and details.consumeOnRead == true)
end

local function cancel(order)
    return PNC.WorkInputService.Cancel(order)
end

PNC.WorkService.CancellationHandlers = PNC.WorkService.CancellationHandlers or {}
PNC.WorkService.CancellationHandlers.READ_BOOK = cancel
PNC.WorkService.RegisterPreparation("READ_BOOK", function(order)
    return PNC.WorkInputService.IsReady(order)
end)
PNC.WorkService.RegisterCompletion("READ_BOOK", complete)

return Service
