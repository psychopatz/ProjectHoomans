-- L6 workload family D: large player inventory + many compact NPC inventories
-- and ModData/persistence/replication scale.
--
-- Exercises real production seams:
--   PsychopatzCore.Actors.Inventory (SEED_ONLY / BASELINE_DELTA / FULL)
--   PNC.Inventory.ActorInventoryBridge (HydrateRecord / CaptureRecord)
--   PNC.Inventory (AddItems / RemoveItems / BuildSummaryPayload)
--   PNC.PersistenceCoordinator / RuntimeStore / Network replication

local Probe = require "tests/support/lightweight_runtime_workloads/probe"

local InventoryStress = {}

InventoryStress.Scenarios = {
    "PLAYER_INVENTORY_LARGE",
    "NPC_INVENTORY_COMPACT_SCALE",
    "PLAYER_TO_MANY_NPCS",
    "MANY_NPCS_TO_PLAYER",
    "NPC_INVENTORY_MUTATION_STORM",
    "INVENTORY_MATERIALIZE_SUBSET",
    "INVENTORY_SAVE_RELOAD_SCALE",
    "INVENTORY_REPLICATION_SCALE",
}

local ITEM_TIERS = {
    { type = "Base.TinCan", kind = "common" },
    { type = "Base.Bandage", kind = "medical" },
    { type = "Base.BaseballBat", kind = "weapon", condition = 8 },
    { type = "Base.Apple", kind = "food", condition = 6 },
    { type = "Base.Bag_Schoolbag", kind = "container" },
    { type = "Base.WaterBottleFull", kind = "custom", custom = true },
}

local function makeRichItem(ctx, index)
    local tier = ITEM_TIERS[((index - 1) % #ITEM_TIERS) + 1]
    local item = ctx.makeItem(tier.type)
    local md = item:getModData()
    md.l6ItemId = "pitem_" .. tostring(index)
    if tier.condition then item:setCondition(tier.condition) end
    if tier.kind == "weapon" then item.IsWeapon = function() return true end end
    if tier.kind == "container" then item.IsInventoryContainer = function() return true end end
    if tier.custom then md.l6CustomTag = "durable_" .. tostring(index) end
    return item, tier
end

local function makeDurableSpecs(prefix, count)
    local specs = {}
    for i = 1, count do
        local tier = ITEM_TIERS[((i - 1) % #ITEM_TIERS) + 1]
        specs[i] = {
            id = prefix .. ":item:" .. tostring(i),
            type = tier.type,
            stack = 1,
            origin = "world",
            condition = tier.condition,
        }
    end
    return specs
end

local function createCoreActor(actorRegistry, actorId, x, y)
    return actorRegistry:Create({
        actorId = actorId,
        identitySeed = "seed_" .. actorId,
        archetypeID = "General",
        world = { position = { x = x, y = y, z = 0 } },
        extensions = {
            ["PsychopatzCore.SurvivorWorld"] = {
                factionID = "fac_l6_inv",
                communityID = "com_l6_inv",
                role = "member",
            },
        },
    })
end

-- Populate a compact Core actor's personalInventory directly through
-- PsychopatzCore.Actors.Inventory so distant actors stay abstract/bodyless.
local function addCompactItemsToActor(actorRegistry, actorId, count)
    if count <= 0 then return true end
    local ActorInventory = PsychopatzCore.Actors.Inventory
    local actor = actorRegistry:Get(actorId)
    if not actor then return false end
    local ledger = assert(ActorInventory.Decode(actor.personalInventory))
    for i = 1, count do
        local tier = ITEM_TIERS[((i - 1) % #ITEM_TIERS) + 1]
        ledger:Add({
            itemId = actorId .. ":acq:" .. tostring(i),
            fullType = tier.type,
            count = 1,
            condition = tier.condition,
        })
    end
    local encoded = assert(ActorInventory.ToSmallestPayload(ledger))
    actorRegistry:Commit(actorId, { personalInventory = encoded })
    return true
end

local function measureCompactActors(actorRegistry, Json)
    local totalActors, totalItems, totalBytes = 0, 0, 0
    local modes = { SEED_ONLY = 0, BASELINE_DELTA = 0, FULL = 0, OTHER = 0 }
    local bytesPerActor = {}
    local ActorInventory = PsychopatzCore.Actors.Inventory
    for _, actor in ipairs(actorRegistry:List()) do
        if actor and actor.personalInventory then
            totalActors = totalActors + 1
            local mode = tostring(actor.personalInventory.mode or "OTHER")
            modes[mode] = (modes[mode] or 0) + 1
            local enc = Json.Encode(actor.personalInventory) or ""
            local b = #enc
            totalBytes = totalBytes + b
            bytesPerActor[#bytesPerActor + 1] = b
            local ledger = ActorInventory.Decode(actor.personalInventory)
            if ledger then
                totalItems = totalItems + #ledger:List()
            end
        end
    end
    return {
        totalActors = totalActors,
        totalItems = totalItems,
        totalBytes = totalBytes,
        modes = modes,
        bytes = Probe.Percentiles(bytesPerActor),
    }
end

-- options:
--   scenario: one of InventoryStress.Scenarios
--   playerItems: 100 | 500 | 1000 | 2000
--   npcCount: 10 | 50 | 100 | 500
--   itemsPerNpc: 0 | 20 | 100 | 500
--   transferNpcs: 1 | 10 | 50 | 100
--   subsetLive: number of nearby actors to materialize (default 4)
function InventoryStress.New(options)
    local scenario = assert(options.scenario, "inventory scenario required")
    local playerItems = options.playerItems or 500
    local npcCount = options.npcCount or 50
    local itemsPerNpc = options.itemsPerNpc or 20
    local transferNpcs = options.transferNpcs or 10
    local subsetLive = options.subsetLive or 4
    local probe = Probe.New()
    local state = {
        probe = probe,
        actorIds = {},
        opSamples = {},
        tickSamples = {},
        playerListIters = 0,
        uiRowBuilds = 0,
        uiCacheHits = 0,
        itemsTransferred = 0,
        repeatedCaptureGrowthBytes = 0,
        collapsedToSeedOnly = 0,
        reconstructedEqual = true,
        legacyAuthorityCount = 0,
        unrelatedTouched = 0,
        executed = false,
    }
    local wl = { ownsPlayerMotion = true, suppressLegacyMutations = true, state = state }

    function wl.Setup(ctx)
        local Json = require "PsychopatzCore/Serialization/PsychopatzJson"
        state.Json = Json
        local Bridge = PNC.Inventory.ActorInventoryBridge
            or require "PNC/Core/Inventory/PNC_Inventory/Persistence/PNC_Inventory_ActorBridge"
        state.Bridge = Bridge

        probe:AttachDiagnostics(PNC.PerformanceScalingDiagnostics)
        probe:Wrap(Bridge, "HydrateRecord", "Inv.Hydrate")
        probe:Wrap(Bridge, "CaptureRecord", "Inv.Capture")
        probe:Wrap(PNC.Inventory, "AddItems", "Inv.AddItems")
        probe:Wrap(PNC.Inventory, "RemoveItems", "Inv.RemoveItems")
        if PNC.Inventory.BuildSummaryPayload then
            probe:Wrap(PNC.Inventory, "BuildSummaryPayload", "Inv.BuildSummary")
        end
        if PNC.Registry then
            probe:Wrap(PNC.Registry, "MarkDirty", "Registry.MarkDirty")
        end
        if PNC.Network then
            probe:Wrap(PNC.Network, "BroadcastRecord", "Network.BroadcastRecord")
        end
        probe.enabled = true

        local player = ctx.players[1]
        local pInv = player:getInventory()

        if scenario == "PLAYER_INVENTORY_LARGE" then
            -- Populate large simulated player inventory.
            for i = 1, playerItems do
                local item = makeRichItem(ctx, i)
                pInv:getItems():add(item)
            end
            -- Measure scanning + UI row build + stable cache reuse.
            local uiCache = { rev = 1, rows = nil }
            local currentRev = 1
            for pass = 1, 10 do
                local t0 = os.clock()
                if uiCache.rows and uiCache.rev == currentRev then
                    state.uiCacheHits = state.uiCacheHits + 1
                else
                    local list = pInv:getItems()
                    local rows = {}
                    for idx = 0, list:size() - 1 do
                        local it = list:get(idx)
                        state.playerListIters = state.playerListIters + 1
                        rows[#rows + 1] = {
                            id = it:getModData().l6ItemId,
                            fullType = it:getFullType(),
                            cond = it:getCondition(),
                        }
                    end
                    state.uiRowBuilds = state.uiRowBuilds + #rows
                    uiCache.rows = rows
                    uiCache.rev = currentRev
                end
                state.opSamples[#state.opSamples + 1] = (os.clock() - t0) * 1000
            end
            state.executed = true

        elseif scenario == "NPC_INVENTORY_COMPACT_SCALE" then
            -- Create N distant compact Core actors; half keep starter SEED_ONLY,
            -- half acquire durable items (or all if itemsPerNpc == 0).
            for i = 1, npcCount do
                local aid = "l6_inv_actor_" .. tostring(i)
                createCoreActor(ctx.actorRegistry, aid, 15000 + i * 10, 15000)
                state.actorIds[i] = aid
                if itemsPerNpc > 0 and (i % 2 == 0 or npcCount <= 10) then
                    local t0 = os.clock()
                    addCompactItemsToActor(ctx.actorRegistry, aid, itemsPerNpc)
                    state.opSamples[#state.opSamples + 1] = (os.clock() - t0) * 1000
                end
            end
            -- Check repeated capture stability on one actor.
            local sampleActor = ctx.actorRegistry:Get(state.actorIds[#state.actorIds])
            local sampleRec = PNC.Persistence.CoreProvider.PromoteCoreActor(sampleActor.actorId, PsychopatzCore)
            local p1 = Bridge.CaptureRecord(sampleRec, sampleActor)
            local b1 = #(Json.Encode(p1) or "")
            local p2 = Bridge.CaptureRecord(sampleRec, sampleActor)
            local b2 = #(Json.Encode(p2) or "")
            state.repeatedCaptureGrowthBytes = math.max(0, b2 - b1)
            PNC.Persistence.CoreProvider.DemoteCoreActor(sampleRec, PsychopatzCore, { force = true })
            state.executed = true

        elseif scenario == "PLAYER_TO_MANY_NPCS" or scenario == "MANY_NPCS_TO_PLAYER" then
            local batchSize = 5
            local totalPlayerItems = math.max(playerItems, transferNpcs * batchSize)
            for i = 1, totalPlayerItems do
                pInv:getItems():add(makeRichItem(ctx, i))
            end
            local promoted = {}
            for i = 1, transferNpcs do
                local aid = "l6_xfer_" .. tostring(i)
                createCoreActor(ctx.actorRegistry, aid, player:getX() + 2, player:getY() + 2)
                state.actorIds[i] = aid
                local rec = assert(PNC.Persistence.CoreProvider.PromoteCoreActor(aid, PsychopatzCore))
                promoted[i] = rec
            end
            -- Transfer player -> many NPCs via real PNC.Inventory.AddItems + CaptureRecord.
            local addedByNpc = {}
            for i = 1, transferNpcs do
                local t0 = os.clock()
                local specs = makeDurableSpecs("xfer_" .. tostring(i), batchSize)
                local ok = PNC.Inventory.AddItems(promoted[i], specs, "root", "l6_player_transfer")
                assert(ok, "AddItems failed")
                addedByNpc[i] = specs
                state.itemsTransferred = state.itemsTransferred + #specs
                local actor = ctx.actorRegistry:Get(state.actorIds[i])
                local captured = Bridge.CaptureRecord(promoted[i], actor)
                if captured then
                    ctx.actorRegistry:Commit(actor.actorId, { personalInventory = captured })
                end
                state.opSamples[#state.opSamples + 1] = (os.clock() - t0) * 1000
            end
            if scenario == "MANY_NPCS_TO_PLAYER" then
                -- Reverse transfer: remove exact item IDs and verify collapse back to SEED_ONLY.
                for i = 1, transferNpcs do
                    local t0 = os.clock()
                    local ids = {}
                    for j = 1, #addedByNpc[i] do ids[j] = addedByNpc[i][j].id end
                    local ok = PNC.Inventory.RemoveItems(promoted[i], ids, "l6_reverse_transfer")
                    assert(ok, "RemoveItems failed")
                    local actor = ctx.actorRegistry:Get(state.actorIds[i])
                    local captured, mode = Bridge.CaptureRecord(promoted[i], actor)
                    if captured then
                        ctx.actorRegistry:Commit(actor.actorId, { personalInventory = captured })
                        if mode == "SEED_ONLY" then
                            state.collapsedToSeedOnly = state.collapsedToSeedOnly + 1
                        end
                    end
                    state.opSamples[#state.opSamples + 1] = (os.clock() - t0) * 1000
                end
            end
            state.executed = true

        elseif scenario == "NPC_INVENTORY_MUTATION_STORM" then
            local promoted = {}
            for i = 1, 10 do
                local aid = "l6_storm_" .. tostring(i)
                createCoreActor(ctx.actorRegistry, aid, player:getX() + 3, player:getY())
                state.actorIds[i] = aid
                promoted[i] = assert(PNC.Persistence.CoreProvider.PromoteCoreActor(aid, PsychopatzCore))
            end
            -- Clear dirty state before storm so we verify actor-scoped dirtying.
            PNC.Registry.DirtyByID = {}
            local target = promoted[1]
            local actor = ctx.actorRegistry:Get(target.id)
            local prevBytes = nil
            for step = 1, 20 do
                local t0 = os.clock()
                local id = "storm_item_" .. tostring(step)
                assert(PNC.Inventory.AddItems(target, {
                    { id = id, type = "Base.Bandage", stack = 1, origin = "world" },
                }, "root", "l6_storm_add"))
                if step > 5 then
                    assert(PNC.Inventory.RemoveItems(target, { "storm_item_" .. tostring(step - 5) }, "l6_storm_rem"))
                end
                local cap = Bridge.CaptureRecord(target, actor)
                local b = #(Json.Encode(cap) or "")
                if prevBytes and step >= 10 and b > prevBytes + 64 then
                    state.repeatedCaptureGrowthBytes = math.max(state.repeatedCaptureGrowthBytes, b - prevBytes)
                end
                prevBytes = b
                ctx.actorRegistry:Commit(actor.actorId, { personalInventory = cap })
                state.opSamples[#state.opSamples + 1] = (os.clock() - t0) * 1000
            end
            for i = 2, 10 do
                if PNC.Registry.DirtyByID[promoted[i].id] then
                    state.unrelatedTouched = state.unrelatedTouched + 1
                end
            end
            state.executed = true

        elseif scenario == "INVENTORY_MATERIALIZE_SUBSET" then
            -- Create N item-bearing abstract actors; place subsetLive near player,
            -- rest far away.
            for i = 1, npcCount do
                local aid = "l6_sub_" .. tostring(i)
                local near = i <= subsetLive
                createCoreActor(ctx.actorRegistry, aid, near and (player:getX() + 3 + i) or (16000 + i * 20), near and player:getY() or 16000)
                addCompactItemsToActor(ctx.actorRegistry, aid, itemsPerNpc)
                state.actorIds[i] = aid
            end
            state.executed = true

        elseif scenario == "INVENTORY_SAVE_RELOAD_SCALE" then
            for i = 1, npcCount do
                local aid = "l6_sr_" .. tostring(i)
                createCoreActor(ctx.actorRegistry, aid, 15000 + i * 10, 15000)
                if i % 2 == 0 then
                    addCompactItemsToActor(ctx.actorRegistry, aid, itemsPerNpc)
                end
                state.actorIds[i] = aid
            end
            local before = measureCompactActors(ctx.actorRegistry, Json)
            ctx.fire("OnSave")
            assert(ctx.runtimeStore.Load(true))
            local after = measureCompactActors(ctx.actorRegistry, Json)
            state.reconstructedEqual = (before.totalActors == after.totalActors
                and before.totalItems == after.totalItems
                and before.modes.SEED_ONLY == after.modes.SEED_ONLY
                and before.modes.BASELINE_DELTA == after.modes.BASELINE_DELTA)
            -- Verify zero legacy Hoomans inventory authority for Core-backed actors.
            for _, aid in ipairs(state.actorIds) do
                local legacyKey = PNC.Registry.Internal
                    and PNC.Registry.Internal.StorageKeyForID
                    and PNC.Registry.Internal.StorageKeyForID(aid)
                if legacyKey and ModData.get(legacyKey) ~= nil then
                    state.legacyAuthorityCount = state.legacyAuthorityCount + 1
                end
            end
            state.executed = true

        elseif scenario == "INVENTORY_REPLICATION_SCALE" then
            local promoted = {}
            for i = 1, 6 do
                local aid = "l6_rep_" .. tostring(i)
                createCoreActor(ctx.actorRegistry, aid, player:getX() + 2, player:getY() + i)
                state.actorIds[i] = aid
                promoted[i] = assert(PNC.Persistence.CoreProvider.PromoteCoreActor(aid, PsychopatzCore))
            end
            for round = 1, 4 do
                for i = 1, 6 do
                    local t0 = os.clock()
                    assert(PNC.Inventory.AddItems(promoted[i], {
                        { id = "rep_" .. round .. "_" .. i, type = "Base.Bandage", stack = 1, origin = "world" },
                    }, "root", "l6_rep_add"))
                    PNC.Network.BroadcastRecord(promoted[i], "equipment_changed")
                    state.opSamples[#state.opSamples + 1] = (os.clock() - t0) * 1000
                end
            end
            state.executed = true
        end
    end

    function wl.AfterTick(ctx, tick, elapsedMs, tickMs)
        if not probe.enabled then return end
        probe:EndFrame()
        state.tickSamples[#state.tickSamples + 1] = tickMs
    end

    function wl.Finish(ctx)
        probe.enabled = false
        local compact = measureCompactActors(ctx.actorRegistry, state.Json)
        local p = probe
        return {
            Scenario = scenario,
            PlayerItems = playerItems,
            NPCCount = npcCount,
            ItemsPerNPC = itemsPerNpc,
            TotalActors = compact.totalActors,
            TotalLogicalItems = compact.totalItems,
            TotalEncodedBytes = compact.totalBytes,
            BytesP50 = compact.bytes.p50,
            BytesP95 = compact.bytes.p95,
            BytesMax = compact.bytes.max,
            SeedOnlyCount = compact.modes.SEED_ONLY or 0,
            BaselineDeltaCount = compact.modes.BASELINE_DELTA or 0,
            FullModeCount = compact.modes.FULL or 0,
            PlayerListIters = state.playerListIters,
            UIRowBuilds = state.uiRowBuilds,
            UICacheHits = state.uiCacheHits,
            ItemsTransferred = state.itemsTransferred,
            CollapsedToSeedOnly = state.collapsedToSeedOnly,
            RepeatedCaptureGrowthBytes = state.repeatedCaptureGrowthBytes,
            ReconstructedEqual = state.reconstructedEqual,
            LegacyAuthorityCount = state.legacyAuthorityCount,
            UnrelatedTouched = state.unrelatedTouched,
            HydrateCount = p:Get("Inv.Hydrate"),
            CaptureCount = p:Get("Inv.Capture"),
            AddItemsCalls = p:Get("Inv.AddItems"),
            RemoveItemsCalls = p:Get("Inv.RemoveItems"),
            DirtyMarks = p:Get("Registry.MarkDirty"),
            NetworkBroadcasts = p:Get("Network.BroadcastRecord"),
            GlobalSaveCalls = ctx.metrics.globalSaveCalls,
            EquipmentDeltas = ctx.metrics.equipmentDeltas,
            HealthOrWoundDeltas = ctx.metrics.healthOrWoundDeltas,
            FullSnapshots = ctx.metrics.fullSnapshots,
            PromotedAtEnd = ctx.countMap(PNC.Registry and PNC.Registry.Data),
            Op = Probe.Percentiles(state.opSamples),
            Tick = Probe.Percentiles(state.tickSamples),
        }
    end

    return wl
end

function InventoryStress.Format(r)
    return string.format(
        "%s actors=%d items=%d seed=%d delta=%d full=%d bytes=%d(p50=%.0f p95=%.0f max=%.0f) hyd=%d cap=%d dirty=%d gSave=%d eqD=%d hwD=%d fullSnap=%d promEnd=%d legacy=%d opAvg=%.3f opMax=%.3f",
        r.Scenario, r.TotalActors, r.TotalLogicalItems,
        r.SeedOnlyCount, r.BaselineDeltaCount, r.FullModeCount,
        r.TotalEncodedBytes, r.BytesP50, r.BytesP95, r.BytesMax,
        r.HydrateCount, r.CaptureCount, r.DirtyMarks, r.GlobalSaveCalls,
        r.EquipmentDeltas, r.HealthOrWoundDeltas, r.FullSnapshots,
        r.PromotedAtEnd, r.LegacyAuthorityCount, r.Op.avg, r.Op.max)
end

return InventoryStress
