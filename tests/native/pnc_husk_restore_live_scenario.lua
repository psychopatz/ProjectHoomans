-- Real graphical-client lifecycle proof for ProjectHoomans body presence.
--
-- The scenario runs in a disposable single-player world, where the player
-- keeps the target square loaded. It uses the production factory and
-- registry, virtualizes the canonical shell through the native population
-- manager, asks that same native manager to realize its queued population
-- record, and then lets the production reaper remove the returned ordinary
-- IsoZombie before Presence.Materialize creates the replacement.

require "ISUI/ISPanel"

local NPC_ID = "client:husk:restore:live-proof"

local function fail(message)
    error("PNC live husk proof: " .. tostring(message))
end

local function requireValue(value, message)
    if value == nil then fail(message) end
    return value
end

local function callMethod(object, name, ...)
    local ok, method = pcall(function() return object and object[name] end)
    if not ok or type(method) ~= "function" then
        return false, "missing_method:" .. tostring(name)
    end
    local results = { pcall(method, object, ...) }
    if results[1] ~= true then
        return false, tostring(results[2])
    end
    return true, results[2], results[3], results[4]
end

local function persistentOutfitID(body)
    local ok, value = callMethod(body, "getPersistentOutfitID")
    if ok and value ~= nil and tostring(value) ~= "0" then
        return tostring(value)
    end
    return nil
end

local function populationID(body)
    local ok, value = pcall(function() return body and body.persistentId end)
    if ok and value ~= nil and tonumber(value) and tonumber(value) ~= 0 then
        return tostring(value)
    end
    if PNC.BodyLifecycle and PNC.BodyLifecycle.GetBodyPopulationID then
        local success, result = pcall(
            PNC.BodyLifecycle.GetBodyPopulationID, body
        )
        if success and result ~= nil then return tostring(result) end
    end
    return nil
end

local function attached(body)
    local ok, square = callMethod(body, "getCurrentSquare")
    return ok and square ~= nil
end

local function bodyCountFor(cell, npcID)
    local ok, list = callMethod(cell, "getZombieList")
    if not ok or not list then return 0 end
    local count = 0
    local i
    for i = 0, list:size() - 1 do
        local body = list:get(i)
        local data = body and body.getModData and body:getModData() or nil
        if data and tostring(data.PNC_UUID or "") == tostring(npcID) then
            count = count + 1
        end
    end
    return count
end

local function findRestoredBody(cell, original, outfitID, x, y)
    local ok, list = callMethod(cell, "getZombieList")
    if not ok or not list then return nil end
    local candidate
    local count = 0
    local i
    for i = 0, list:size() - 1 do
        local body = list:get(i)
        local data = body and body.getModData and body:getModData() or nil
        local bodyOutfit = persistentOutfitID(body)
        local bodyX = body and body.getX and body:getX() or nil
        local bodyY = body and body.getY and body:getY() or nil
        local unmarked = not data or data.PNC_UUID == nil
        if body and body ~= original and attached(body) and unmarked
            and bodyOutfit == tostring(outfitID)
            and bodyX and bodyY
            and math.abs(bodyX - x) <= 2.0
            and math.abs(bodyY - y) <= 2.0
        then
            count = count + 1
            candidate = body
        end
    end
    if count > 1 then
        fail("native population manager restored " .. tostring(count)
            .. " candidate shell(s), expected exactly one")
    end
    return candidate
end

local function makeProofPanel()
    local panel = ISPanel:new(20, 20, 520, 180)
    panel.name = "PNC live husk restore proof"
    panel.backgroundColor = { r = 0.03, g = 0.12, b = 0.05, a = 0.92 }
    panel.borderColor = { r = 0.55, g = 1.0, b = 0.55, a = 1.0 }
    panel:initialise()
    panel:addToUIManager()
    return panel
end

return function()
    local player = requireValue(
        getSpecificPlayer and getSpecificPlayer(0) or nil,
        "single-player target player was not available"
    )
    local square = requireValue(
        player.getCurrentSquare and player:getCurrentSquare() or nil,
        "player square was not loaded"
    )
    local cell = requireValue(getCell and getCell() or nil,
        "IsoCell was not available")
    local lifecycle = requireValue(PNC and PNC.BodyLifecycle,
        "PNC body lifecycle was not loaded in the client")
    local registry = requireValue(PNC.Registry,
        "PNC registry was not loaded in the client")
    local presence = requireValue(PNC.Presence,
        "PNC presence was not loaded in the client")
    local types = requireValue(PNC.Types,
        "PNC record types were not loaded in the client")
    local core = requireValue(PNC.Core,
        "PNC core was not loaded in the client")
    if not core.IsAuthority or core.IsAuthority() ~= true then
        fail("client scenario did not run on the authoritative single-player side")
    end

    local position = {
        x = player:getX(),
        y = player:getY(),
        z = player:getZ(),
    }
    local record = types.NewRecord({
        id = NPC_ID,
        displayName = "Live Husk Restore Proof",
        tacticalClass = "neutral",
        archetypeID = "Scavenger",
        x = position.x,
        y = position.y,
        z = position.z,
        persist = false,
        equipmentSpawnMode = "none",
        equipment = { worn = {}, attached = {} },
        inventory = { items = {}, worn = {}, equipped = {}, attached = {} },
    })
    record.presenceState = PNC.Const.PRESENCE_LIVE
    record.alive = true
    if not registry.AddRecord(record) then
        fail("test record could not be added to the live registry")
    end

    local body, factoryReason = lifecycle.SpawnLiveBody(
        record, position, "client_live_husk_restore"
    )
    if not body then
        fail("production body factory returned no body: " .. tostring(factoryReason))
    end
    if not attached(body) then
        fail("production body factory returned a detached body")
    end
    registry.RegisterLiveZombie(record, body)
    local outfitID = requireValue(record.liveBodyInstanceID,
        "canonical shell had no persistent outfit identity")
    local originalPopulationID = populationID(body)
    print(
        "PNC_LIVE_HUSK_CANONICAL:npc=" .. NPC_ID
            .. " outfitID=" .. tostring(outfitID)
            .. " populationID=" .. tostring(originalPopulationID or "nil")
            .. " factory=" .. tostring(lifecycle.BodyFactory.lastFactory)
    )

    local populationManager = requireValue(
        ZombiePopulationManager and ZombiePopulationManager.instance or nil,
        "ZombiePopulationManager was not available"
    )
    local virtualizedOK, virtualizedError = callMethod(
        populationManager, "virtualizeZombie", body
    )
    if not virtualizedOK then
        fail("native population virtualization failed: " .. tostring(virtualizedError))
    end
    if attached(body) then
        fail("canonical body remained attached after native virtualization")
    end

    if not presence.Abstract(record, "client_native_virtualized_loss") then
        fail("Presence.Abstract rejected the virtualized canonical body")
    end
    local ledgerEntry = lifecycle.FindHuskEntry
        and lifecycle.FindHuskEntry(body) or nil
    if not ledgerEntry then
        fail("virtualized canonical body did not create a husk-ledger entry")
    end

    -- updateMain is the production population-manager realization path. It
    -- consumes the native record queued by virtualizeZombie and internally
    -- calls VirtualZombieManager with the exact persistent population id.
    local updateOK
    local updateError
    local restored
    local attempt
    for attempt = 1, 5 do
        updateOK, updateError = callMethod(populationManager, "updateMain")
        if not updateOK then
            fail("native population realization failed: " .. tostring(updateError))
        end
        restored = findRestoredBody(
            cell, body, outfitID, position.x, position.y
        )
        if restored then break end
    end
    restored = requireValue(restored,
        "native population manager did not restore the exact carrier shell")
    local restoredPopulationID = populationID(restored)
    print(
        "PNC_LIVE_HUSK_RESTORED:npc=" .. NPC_ID
            .. " restoredBody=" .. tostring(restored)
            .. " outfitID=" .. tostring(persistentOutfitID(restored))
            .. " populationID=" .. tostring(restoredPopulationID or "nil")
            .. " attached=true"
    )

    local pumpNow = core.Now() + (tonumber(PNC.Const.HUSK_REAP_PUMP_INTERVAL_MS) or 250)
    local pumpOK, pumpError = pcall(function()
        lifecycle.PumpHuskReaper(pumpNow, true)
    end)
    if not pumpOK then
        fail("husk reaper pump raised an error: " .. tostring(pumpError))
    end
    if attached(restored) then
        fail("exact restored ordinary zombie shell was not removed")
    end
    if bodyCountFor(cell, NPC_ID) ~= 0 then
        fail("reaper left a duplicate managed body before materialization")
    end
    print(
        "PNC_LIVE_HUSK_REAPED:npc=" .. NPC_ID
            .. " restoredDetached=true exactRestoredBody=true"
    )

    if lifecycle.StartupCleanup then
        lifecycle.StartupCleanup.complete = true
        lifecycle.StartupCleanup.active = false
        lifecycle.StartupCleanup.settleUntil = 0
        lifecycle.StartupCleanup.nextMaterializeAt = 0
    end
    record.presenceState = PNC.Const.PRESENCE_ABSTRACT
    local materializeOK, replacementOrError = pcall(function()
        return presence.Materialize(record, "client_nearby_after_husk_reap")
    end)
    if not materializeOK then
        fail("nearby materialization raised an error: " .. tostring(replacementOrError))
    end
    local replacement = requireValue(replacementOrError,
        "nearby abstract NPC did not materialize after exact husk removal")
    if registry.GetLiveZombie(record.id) ~= replacement then
        fail("replacement was not registered as the canonical NPC body")
    end
    if bodyCountFor(cell, NPC_ID) ~= 1 then
        fail("materialization produced a duplicate canonical body")
    end
    if replacement == restored or not attached(replacement) then
        fail("materialization did not create a new attached canonical body")
    end
    print(
        "PNC_LIVE_HUSK_RESTORE_PROOF:npc=" .. NPC_ID
            .. " restoredDetached=true replacementAttached=true"
            .. " replacementCount=" .. tostring(bodyCountFor(cell, NPC_ID))
            .. " restoredOutfitID=" .. tostring(persistentOutfitID(restored))
            .. " restoredPopulationID=" .. tostring(restoredPopulationID or "nil")
    )
    return makeProofPanel()
end
