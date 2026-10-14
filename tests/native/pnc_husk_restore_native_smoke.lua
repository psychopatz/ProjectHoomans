-- Native Build 42 lifecycle acceptance fixture.
--
-- This drives the real PZ population path: create a PNC shell, hand that
-- shell to ZombiePopulationManager.virtualizeZombie, restore the same
-- population identity through VirtualZombieManager, and let the production
-- OnZombieCreate/reaper path remove it before Presence.Materialize creates the
-- replacement.  The fast Lua tests cannot prove this engine hand-off.

local function firstLoadedSquare()
    local cell = getCell and getCell() or nil
    local square
    local candidates = {
        { 10000, 10000 },
        { 10500, 9500 },
        { 10600, 10000 },
        { 0, 0 },
    }
    local radius
    local dx
    local dy
    if not cell or not cell.getGridSquare then
        return nil
    end
    -- The disposable native server loads the origin cell. Keep the probe
    -- bounded so a missing world chunk is reported rather than scanned.
    for radius = 0, 8 do
        for dx = -radius, radius do
            for dy = -radius, radius do
                square = cell:getGridSquare(dx, dy, 0)
                if square ~= nil then
                    return square
                end
            end
        end
    end
    -- A headless dedicated server has no connected player to keep a map cell
    -- relevant. Build 42 exposes the same engine-backed square creation API
    -- used by server-side object placement, which gives this acceptance test
    -- a real IsoGridSquare without introducing a fake Lua body.
    if cell.getOrCreateGridSquare then
        for _, candidate in ipairs(candidates) do
            square = cell:getOrCreateGridSquare(candidate[1], candidate[2], 0)
            if square ~= nil then
                local ok, water = pcall(square.isWaterSquare, square)
                if not ok or water ~= true then
                    return square
                end
            end
        end
    end
    return nil
end

local function bodyPosition(square)
    return {
        x = square:getX() + 0.5,
        y = square:getY() + 0.5,
        z = square:getZ(),
    }
end

local function zombieCountFor(npcID)
    local cell = getCell and getCell() or nil
    local list = cell and cell.getZombieList and cell:getZombieList() or nil
    local count = 0
    local i
    local body
    local modData
    if not list then
        return 0
    end
    for i = 0, list:size() - 1 do
        body = list:get(i)
        modData = body and body.getModData and body:getModData() or nil
        if modData and tostring(modData.PNC_UUID or "") == tostring(npcID) then
            count = count + 1
        end
    end
    return count
end

local function detached(body)
    return body ~= nil
        and body.getCurrentSquare ~= nil
        and body:getCurrentSquare() == nil
end

local function createRestoredPopulationBody(square, outfitID, populationID)
    local manager = VirtualZombieManager
        and VirtualZombieManager.instance or nil
    local choices = manager and manager.choices or nil
    local direction = IsoDirections and IsoDirections.S or nil
    if not manager or not choices or not direction then
        return nil, "virtual_zombie_manager_api_unavailable"
    end
    choices:clear()
    choices:add(square)
    return manager:createRealZombieAlways(
        direction,
        false,
        tonumber(outfitID) or 0,
        tonumber(populationID) or 0
    )
end

PZHarnessNativeTest = function()
    local square = firstLoadedSquare()
    local position
    local record
    local lifecycle
    local registry
    local original
    local outfitID
    local populationID
    local entry
    local restored
    local replacement
    local virtualizedOK
    local restoredOK
    local pumpOK
    local materializeOK
    local materializeError

    PZHarness.assertTrue(square ~= nil, "native server did not expose a loaded square")
    if not square then return end
    local squareWater = nil
    if square.isWaterSquare then
        local ok, value = pcall(square.isWaterSquare, square)
        if ok then squareWater = value end
    end
    local worldZombiesDisabled = nil
    if IsoWorld and IsoWorld.getZombiesDisabled then
        local ok, value = pcall(IsoWorld.getZombiesDisabled)
        if ok then worldZombiesDisabled = value end
    end
    local systemZombieCreation = nil
    if SystemDisabler then
        local ok, value = pcall(function()
            return SystemDisabler.doZombieCreation
        end)
        if ok then systemZombieCreation = value end
    end
    print(
        "PNC_NATIVE_SQUARE_PROBE:x=" .. tostring(square:getX())
            .. " y=" .. tostring(square:getY())
            .. " z=" .. tostring(square:getZ())
            .. " water=" .. tostring(squareWater)
            .. " worldZombiesDisabled=" .. tostring(worldZombiesDisabled)
            .. " doZombieCreation=" .. tostring(systemZombieCreation)
    )
    local cellProbe = getCell and getCell() or nil
    local resolvedInteger = cellProbe and cellProbe.getGridSquare
        and cellProbe:getGridSquare(square:getX(), square:getY(), square:getZ())
        or nil
    local resolvedPosition = cellProbe and cellProbe.getGridSquare
        and cellProbe:getGridSquare(
            square:getX() + 0.5, square:getY() + 0.5, square:getZ()
        ) or nil
    print(
        "PNC_NATIVE_SQUARE_RESOLVE:integer=" .. tostring(resolvedInteger ~= nil)
            .. " position=" .. tostring(resolvedPosition ~= nil)
    )
    local diagnosticManager = VirtualZombieManager
        and VirtualZombieManager.instance or nil
    local diagnosticChoices = diagnosticManager
        and diagnosticManager.choices or nil
    local diagnosticOK = false
    local diagnosticBody
    local diagnosticError
    if diagnosticManager and diagnosticChoices then
        pcall(function() diagnosticChoices:clear() end)
        pcall(function() diagnosticChoices:add(square) end)
        diagnosticOK, diagnosticBody = pcall(function()
            return diagnosticManager:createRealZombieAlways(
                IsoDirections.S, false, 0, 0
            )
        end)
        if not diagnosticOK then
            diagnosticError = tostring(diagnosticBody)
            diagnosticBody = nil
        end
        pcall(function() diagnosticChoices:clear() end)
        if diagnosticBody then
            pcall(diagnosticBody.removeFromWorld, diagnosticBody)
            pcall(diagnosticBody.removeFromSquare, diagnosticBody)
        end
    end
    print(
        "PNC_NATIVE_DIRECT_CREATE:manager=" .. tostring(diagnosticManager ~= nil)
            .. " choices=" .. tostring(diagnosticChoices ~= nil)
            .. " ok=" .. tostring(diagnosticOK)
            .. " body=" .. tostring(diagnosticBody ~= nil)
            .. " error=" .. tostring(diagnosticError)
    )
    position = bodyPosition(square)
    lifecycle = PNC.BodyLifecycle
    registry = PNC.Registry
    PZHarness.assertTrue(
        lifecycle ~= nil and registry ~= nil,
        "PNC body lifecycle or registry was not loaded"
    )
    if not lifecycle or not registry then return end

    original = PNC.Types.NewRecord({
        id = "native:husk:restore:smoke",
        displayName = "Native Husk Restore Smoke",
        tacticalClass = "neutral",
        archetypeID = "Scavenger",
        x = position.x,
        y = position.y,
        z = position.z,
        equipmentSpawnMode = "none",
        equipment = { worn = {}, attached = {} },
        inventory = { items = {}, worn = {}, equipped = {}, attached = {} },
    })
    original.presenceState = PNC.Const.PRESENCE_LIVE
    original.alive = true
    registry.AddRecord(original)

    local body, factoryReason = lifecycle.SpawnLiveBody(
        original,
        position,
        "native_husk_restore"
    )
    PZHarness.assertTrue(
        body ~= nil,
        "production body factory could not create a native shell: "
            .. tostring(factoryReason)
    )
    if not body then return end
    registry.RegisterLiveZombie(original, body)
    outfitID = original.liveBodyInstanceID
    populationID = original.liveBodyPopulationID
    PZHarness.assertTrue(
        outfitID ~= nil and tonumber(outfitID) ~= 0,
        "live shell did not expose a persistent outfit identity"
    )
    PZHarness.assertTrue(
        original.liveBodyInstanceID == outfitID
            and registry.GetLiveZombie(original.id) == body,
        "canonical body was not registered with its identity"
    )

    virtualizedOK = pcall(function()
        ZombiePopulationManager.instance:virtualizeZombie(body)
    end)
    PZHarness.assertTrue(virtualizedOK, "native population virtualization raised an error")
    PZHarness.assertTrue(detached(body), "virtualized canonical body was not detached")

    local abstracted = PNC.Presence.Abstract(original, "native_virtualized_loss")
    PZHarness.assertTrue(abstracted, "virtualized body did not enter abstract state")
    entry = lifecycle.FindHuskEntry and lifecycle.FindHuskEntry(body) or nil
    PZHarness.assertTrue(
        entry ~= nil and tostring(entry.outfitId) == tostring(outfitID),
        "virtualized body loss did not persist its carrier ledger entry"
    )

    restoredOK, restored = pcall(
        createRestoredPopulationBody,
        square,
        outfitID,
        populationID
    )
    PZHarness.assertTrue(
        restoredOK and restored ~= nil,
        "native population record could not restore the zombie shell"
    )
    if not restoredOK or not restored then return end
    PZHarness.assertEqual(
        restored:getCurrentSquare() ~= nil,
        true,
        "native population restore did not attach the ordinary zombie shell"
    )

    pumpOK = pcall(function()
        lifecycle.PumpHuskReaper(
            PNC.Core.Now() + (tonumber(PNC.Const.HUSK_REAP_PUMP_INTERVAL_MS) or 250),
            true
        )
    end)
    PZHarness.assertTrue(pumpOK, "native husk reaper pump raised an error")
    PZHarness.assertTrue(
        detached(restored),
        "exact restored zombie shell was not detached by the reaper"
    )
    PZHarness.assertEqual(
        zombieCountFor(original.id),
        0,
        "reaper left a duplicate PNC body after removing the restored shell"
    )

    lifecycle.StartupCleanup.complete = true
    lifecycle.StartupCleanup.active = false
    lifecycle.StartupCleanup.settleUntil = 0
    lifecycle.StartupCleanup.nextMaterializeAt = 0
    original.presenceState = PNC.Const.PRESENCE_ABSTRACT
    replacement, materializeError = pcall(function()
        return PNC.Presence.Materialize(original, "native_nearby_restore")
    end)
    materializeOK = replacement
    replacement = materializeError
    PZHarness.assertTrue(
        materializeOK and replacement ~= nil,
        "nearby abstract NPC did not materialize after exact husk removal"
    )
    if not materializeOK or not replacement then return end
    PZHarness.assertEqual(
        registry.GetLiveZombie(original.id),
        replacement,
        "replacement body was not registered as the canonical NPC body"
    )
    PZHarness.assertEqual(
        zombieCountFor(original.id),
        1,
        "materialization created a duplicate canonical body"
    )
    PZHarness.assertTrue(
        replacement ~= restored and not detached(replacement),
        "materialization reused the removed restored shell"
    )
    print(
        "PNC_NATIVE_HUSK_RESTORE_PROOF:npc=" .. tostring(original.id)
            .. " outfitID=" .. tostring(outfitID)
            .. " populationID=" .. tostring(populationID or "nil")
            .. " restoredDetached=true replacementCount="
            .. tostring(zombieCountFor(original.id))
    )
end
