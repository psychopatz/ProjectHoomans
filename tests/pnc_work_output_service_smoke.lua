local T = require "tests/support/test"

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local now = 1000
local serial = 0
local dirtyCount = 0
local recordInventory = {}
local worldObjects = {}
local movedTo, haltedReason, animations, transferred, recordedActivity = nil, nil, {}, 0, 0
local storageRevision, storageWeight, storageMaxWeight = 1, 0, 100
local reservedOwners = {}
local abstractDeposited = {}

local square = {
    getWorldObjects = function() return worldObjects end,
    removeWorldObject = function(_, obj)
        for index = 1, #worldObjects do
            if worldObjects[index] == obj then
                table.remove(worldObjects, index)
                return true
            end
        end
        return false
    end,
}

_G.getCell = function()
    return {
        getGridSquare = function(_, x, y, z)
            if x == 10 and y == 10 and z == 0 then return square end
            return nil
        end,
    }
end

local npcInventory = {
    items = {},
    canAddItem = function() return true end,
    AddItem = function(self, item)
        self.items[#self.items + 1] = item
        local ft = item:getFullType()
        recordInventory[ft] = recordInventory[ft] or {
            id = "inv:" .. ft, type = ft, stack = 0,
        }
        recordInventory[ft].stack = recordInventory[ft].stack + 1
        return true
    end,
    getItems = function(self) return self.items end,
}

local body = {
    x = 10.5, y = 10.5, z = 0,
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
    getZ = function(self) return self.z end,
    getInventory = function() return npcInventory end,
}

local record = {
    id = "npc:1", name = "Alice", x = 10.5, y = 10.5, z = 0,
    affiliation = { communityID = "col:1" },
    runtime = {},
}

local storage = {
    id = "stor:1", revision = storageRevision,
}

PNC = {
    Core = {
        Now = function() return now end,
        GenerateID = function(prefix)
            serial = serial + 1
            return tostring(prefix) .. ":" .. tostring(serial)
        end,
    },
    HomeDutyService = {
        GetBase = function() return { id = "base:1", factionId = "f1", settlementId = "s1" } end,
    },
    StockpileAccessService = {
        FindNearest = function()
            return { id = "node:1", storageId = "stor:1", x = 20, y = 20, z = 0 }
        end,
    },
    ColonyStorageRepository = {
        Get = function(id) return id == "stor:1" and storage or nil end,
    },
    ColonyStorageService = {
        GetStorageRevision = function(s) return s.revision end,
        HasStorageChanged = function(id, obs)
            return id == "stor:1" and storage.revision ~= obs
        end,
        LiveNPCSource = function(_, item, quantity)
            return {
                item = item, quantity = quantity,
                preview = function()
                    return { { type = item.type, stack = quantity, unitWeight = 5 } }
                end,
            }
        end,
        ReserveOutputCapacity = function(_, preview, owner)
            local req = 0
            for _, r in ipairs(preview) do req = req + (r.unitWeight * r.stack) end
            if storageWeight + req > storageMaxWeight then
                return false, "storage_full", { requiredWeight = req }
            end
            reservedOwners[owner] = req
            return true, "reserved", { requiredWeight = req }
        end,
        ReleaseOutputCapacity = function(owner)
            reservedOwners[owner] = nil
            return true
        end,
        TransferIntoStorage = function(_, source, qty)
            if storageWeight + qty * 5 > storageMaxWeight then
                return false, "storage_full"
            end
            storageWeight = storageWeight + qty * 5
            storage.revision = storage.revision + 1
            transferred = transferred + qty
            return true
        end,
        DepositProductionItems = function(_, products)
            if storageWeight + 10 > storageMaxWeight then
                return false, "storage_full"
            end
            for _, p in ipairs(products) do
                abstractDeposited[#abstractDeposited + 1] = p
            end
            storageWeight = storageWeight + 10
            storage.revision = storage.revision + 1
            return true, products
        end,
        RecordActivity = function() recordedActivity = recordedActivity + 1 end,
    },
    Inventory = {
        EnsureRecordInventory = function() return { items = recordInventory } end,
        CaptureLooseInventory = function() return true end,
        AddItems = function(_, specs)
            for _, spec in ipairs(specs) do
                recordInventory[spec.type] = recordInventory[spec.type] or {
                    id = "inv:" .. spec.type, type = spec.type, stack = 0,
                }
                recordInventory[spec.type].stack = recordInventory[spec.type].stack + spec.stack
            end
            return true
        end,
    },
    BehaviorCommon = {
        MoveRecord = function(_, _, x, y, z) movedTo = { x = x, y = y, z = z } end,
        HaltMovement = function(_, _, reason) haltedReason = reason end,
    },
    AnimationScenes = {
        Request = function(r, _, sceneId)
            animations[#animations + 1] = sceneId
            r.runtime.lastAnimationScene = { id = sceneId, reason = "completed" }
            return true
        end,
    },
}

T.load("ProjectHoomans", "server", "PNC/Production/PNC_WorkOutputService.lua")
local Output = PNC.WorkOutputService

-- 1. Ground capture + EnsureOutputEffect
local target = { key = "tree:10:10:0" }
local before = Output.CaptureGroundOutput(square, nil, nil, { snapshotOnly = true })
local modData = {}
local worldItem = {
    getID = function() return "log-101" end,
    getFullType = function() return "Base.Log" end,
    getModData = function() return modData end,
}
worldObjects[1] = {
    getItem = function() return worldItem end,
    transmitModData = function() end,
}

local effect = Output.EnsureOutputEffect(target, "LIVE", {}, {
    ownerKey = target.key, kind = "LUMBER_OUTPUT", x = 10, y = 10, z = 0,
    markDirty = function() dirtyCount = dirtyCount + 1 end,
})
T.truthy(effect, "EnsureOutputEffect creates durable effect")
local captured = Output.CaptureGroundOutput(square, before, effect, {
    markDirty = function() dirtyCount = dirtyCount + 1 end,
})
T.equal(captured, 1, "CaptureGroundOutput captures new world object")
T.equal(effect.itemCount, 1, "effect itemCount updated")
T.equal(modData.PNC_WorkOutputEffectID, effect.id, "world item stamped with effect id")
T.equal(Output.EnsureOutputEffect(target, "LIVE", {}, {}).id, effect.id,
    "EnsureOutputEffect is idempotent")

-- 2. Storage full backoff -> HasStorageChanged invalidates retry -> travel & deposit
storageMaxWeight = 2 -- too small for weight=5
local ctx = { id = "job:1", phase = "OUTPUT_APPROACH", pendingOutput = effect }
local ok, done, reason = Output.TickLiveDelivery(ctx, record, body, effect, now)
T.truthy(ok and not done, "first tick starts grab animation")
T.equal(reason, "grabbing_work_output", "reports grabbing_work_output while anim runs")

ok, done, reason = Output.TickLiveDelivery(ctx, record, body, effect, now)
T.truthy(ok, "second tick finishes grab and enters stockpile check")
T.falsy(done, "blocked when storage full")
T.equal(ctx.phase, "WAITING_FOR_STOCKPILE", "enters WAITING_FOR_STOCKPILE")
T.equal(reason, "storage_full", "reports storage_full")

now = now + 1000 -- still inside retry window
ok, done, reason = Output.TickLiveDelivery(ctx, record, body, effect, now)
T.falsy(done, "stays waiting during retry window")
T.equal(reason, "waiting_for_work_stockpile", "backoff preserves retry timer")

storageMaxWeight = 100
storage.revision = storage.revision + 1 -- storage mutation invalidates backoff
ok, done, reason = Output.TickLiveDelivery(ctx, record, body, effect, now)
T.falsy(done, "resumes travel to stockpile immediately after storage revision change")
T.equal(ctx.phase, "OUTPUT_DESTINATION_APPROACH", "switches to destination approach")
T.equal(movedTo.x, 20, "moves toward stockpile node x")

body.x, body.y = 20, 20
ok, done, reason = Output.TickLiveDelivery(ctx, record, body, effect, now)
T.truthy(ok and not done, "arrival tick starts deposit animation")
T.equal(reason, "depositing_work_output", "reports depositing_work_output while anim runs")

ok, done, reason = Output.TickLiveDelivery(ctx, record, body, effect, now)
T.truthy(ok and done, "deposit completion transfers output to colony storage")
T.equal(transferred, 1, "TransferIntoStorage called for captured log")
T.equal(recordedActivity, 1, "RecordActivity logged store event")
T.equal(effect.state, "APPLIED", "effect marked APPLIED")
T.equal(effect.pickupState, "STOCKPILE", "effect pickupState marked STOCKPILE")
T.equal(next(reservedOwners), nil, "output capacity reservation released")

-- 3. Direct NPC inventory output + TickLiveDelivery (no ground grab)
local cropTarget = { id = "order:farm:1" }
local cropEffect = Output.EnsureOutputEffect(cropTarget, "LIVE", {}, {
    ownerKey = cropTarget.id, kind = "FARMING_OUTPUT", x = 15, y = 15, z = 0,
})
local capOK = Output.CaptureInventoryOutput(cropEffect, {
    { fullType = "Base.Potato", quantity = 2 },
}, { record = record, addToInventory = true })
T.truthy(capOK, "CaptureInventoryOutput adds directly to record inventory")
T.equal(cropEffect.pickupState, "NPC_INVENTORY", "pickupState starts in NPC_INVENTORY")
T.equal(cropEffect.totalQuantity, 2, "totalQuantity reflects stacked harvest")

local farmCtx = { id = "order:farm:1", pendingOutput = cropEffect }
body.x, body.y = 20, 20
ok, done, reason = Output.TickLiveDelivery(farmCtx, record, body, cropEffect, now)
T.truthy(ok and not done, "direct inventory output starts deposit animation")
ok, done, reason = Output.TickLiveDelivery(farmCtx, record, body, cropEffect, now)
T.truthy(ok and done, "direct inventory output deposits cleanly without ground grab")
T.equal(transferred, 3, "transfers both potatoes into colony storage")

-- 4. Abstract direct ColonyStorage delivery
local absTarget = { id = "order:fish:abstract" }
local absEffect = Output.EnsureOutputEffect(absTarget, "ABSTRACT", {
    { fullType = "Base.Pike", quantity = 1 },
}, { ownerKey = absTarget.id, kind = "FISHING_OUTPUT", x = 5, y = 5, z = 0 })
local absCtx = { id = "order:fish:abstract", pendingOutput = absEffect }
local absOK, absReason = Output.FlushAbstractDelivery(absCtx, record, absEffect)
T.truthy(absOK, "FlushAbstractDelivery deposits into ColonyStorage in abstract mode")
T.equal(absReason, "ABSTRACT_STORAGE_ACCEPTED", "abstract storage reason returned")
T.equal(absEffect.state, "APPLIED", "abstract effect marked APPLIED")
T.equal(#abstractDeposited, 1, "DepositProductionItems invoked for abstract output")

T.finish("pnc_work_output_service_smoke")
