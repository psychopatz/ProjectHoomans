local T = require "tests/support/test"
T.addPackagePaths()

local preparation, completion, queuedSpec
local released
package.preload["PsychopatzCore/Inventory/PsychopatzInventory"] = function()
    return { decodeItem = function(record) return record.native end }
end

local nativeBook = { getFullType = function() return "Base.BookSpear" end }
PNC = {
    ProductionContext = {
        ForPlayer = function()
            return { colony = { id = "c1" }, faction = { id = "f1" },
                base = { id = "b1" }, storage = { id = "s1" } }
        end,
    },
    ColonyStorageService = {
        ReadProductionRecord = function() return {
            record = { native = nativeBook }, fullType = "Base.BookSpear",
        } end,
        ReserveProductionRecord = function()
            return { id = "reservation-1" }
        end,
        ReleaseProductionReservation = function(id)
            released = id; return true
        end,
    },
    RecipeKnowledge = {
        Queries = { BookDetails = function() return {
            relevant = true, recipeKeys = { "Base.MakeWoodenSpear" },
        } end },
        Commands = { ReadBook = function() return true, "BOOK_READ", {
            consumeOnRead = false,
        } end },
        BindLiveBody = function() return true end,
    },
    WorkInputService = {
        Bind = function(payload)
            payload.input = { reservationId = "reservation-1",
                storageId = "s1", committed = false }
            return payload
        end,
        IsReady = function() return true end,
        Cancel = function() return true end,
    },
    WorkRepository = { MarkDirty = function() end },
    Registry = {
        Get = function() return { id = "npc-1" } end,
        GetLiveZombie = function() return nil end,
    },
    WorkService = {
        Commands = { Queue = function(spec)
            queuedSpec = spec
            return { id = "work-1", payload = spec.payload }
        end },
        CancellationHandlers = {},
        RegisterPreparation = function(_, handler) preparation = handler end,
        RegisterCompletion = function(_, handler) completion = handler end,
    },
}

local Service = T.load("ProjectHoomans", "server",
    "PNC/Production/PNC_RecipeBookService.lua")
local order = T.truthy(Service.Commands.QueueRead({}, 1), "book order queued")
T.equal(queuedSpec.operation, "READ_BOOK", "book operation")
T.equal(order.payload.mode, "book", "book payload mode")
T.truthy(preparation(order), "book preparation")

local completed, reason = completion({ id = "work-1", workerId = "npc-1",
    payload = { bookRecord = { native = nativeBook },
        bookFullType = "Base.BookSpear",
        input = { reservationId = "reservation-1", storageId = "s1" } } })
T.truthy(completed, reason or "book completion")
T.equal(released, "reservation-1", "unconsumed book reservation released")

T.finish("pnc_recipe_book_service_smoke")
