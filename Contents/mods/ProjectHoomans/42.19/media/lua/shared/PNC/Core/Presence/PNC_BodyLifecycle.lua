--[[
    PNC Body Lifecycle
    Owns engine-body leases, orphan removal, inert corpses, and lifecycle
    diagnostics. Canonical NPC records remain authoritative across reloads.
]]

PNC = PNC or {}
PNC.BodyLifecycle = PNC.BodyLifecycle or {}

local Lifecycle = PNC.BodyLifecycle
local Core = PNC.Core
local Const = PNC.Const

Lifecycle.PendingCorpses = Lifecycle.PendingCorpses or {}
Lifecycle.NextAuditAt = Lifecycle.NextAuditAt or 0
Lifecycle.NextCorpseAuditAt = Lifecycle.NextCorpseAuditAt or 0
Lifecycle.CorpseAuditCursor = Lifecycle.CorpseAuditCursor or 1
Lifecycle.LastAudit = Lifecycle.LastAudit or {
    scanned = 0,
    removed = 0,
    rebound = 0,
    duplicates = 0,
    corpses = 0,
}

local function registry()
    return PNC.Registry
end

local function ensureRuntime(record)
    local now = Core.Now()
    record.runtime = record.runtime or {}
    record.runtime.lifecycle = record.runtime.lifecycle or {
        phase = record.presenceState or "unknown",
        bodyState = "missing",
        lastReason = "runtime_created",
        lastTransitionAt = now,
        lastAuditAt = 0,
        lastError = nil,
        corpseState = record.alive == false and "unresolved" or "none",
    }
    return record.runtime.lifecycle
end

local function mark(record, phase, bodyState, reason, errorText)
    local state
    if not record then
        return
    end
    state = ensureRuntime(record)
    if phase and state.phase ~= phase then
        state.lastTransitionAt = Core.Now()
    end
    state.phase = phase or state.phase
    state.bodyState = bodyState or state.bodyState
    state.lastReason = reason or state.lastReason
    state.lastError = errorText
end

local function noteCleanup(record, cleanupState, reason)
    local state
    if not record then
        return
    end
    state = ensureRuntime(record)
    state.lastCleanupState = cleanupState
    state.lastCleanupReason = reason
    state.lastCleanupAt = Core.Now()
end

local function worldHour()
    local gameTime = getGameTime and getGameTime() or nil
    return gameTime and gameTime.getWorldAgeHours and tonumber(gameTime:getWorldAgeHours()) or 0
end

local function normalizeOnlineID(zombie)
    local value = zombie and zombie.getOnlineID and tonumber(zombie:getOnlineID()) or nil
    return value and value >= 0 and value or nil
end

local function itemFullType(item)
    return item and item.getFullType and tostring(item:getFullType() or "") or ""
end

local function addItemToContainer(container, item)
    if not container or not item then
        return false
    end
    if item.getContainer and item:getContainer() == container then
        return true
    end
    return container.AddItem and pcall(container.AddItem, container, item) or false
end

local function prepareCorpseItems(record, zombie)
    local equipment = PNC.Equipment
    local profiles = PNC.VisualProfiles
    local container = zombie and zombie.getInventory and zombie:getInventory() or nil
    local pool = {}
    local allItems = {}
    local seen = {}
    local claimed = {}
    local appearanceUsed = {}
    local wornItems = zombie and zombie.getWornItems and zombie:getWornItems() or nil
    local itemVisuals = zombie and zombie.getItemVisuals and zombie:getItemVisuals() or nil
    local inventoryItems = container and container.getItems and container:getItems() or nil
    local appearance = profiles and profiles.RollAppearance and profiles.RollAppearance(record) or nil
    local abstractInventory = PNC.Inventory and PNC.Inventory.EnsureRecordInventory
        and PNC.Inventory.EnsureRecordInventory(record) or record.inventory
    local i
    local descriptor
    local item
    local fullType
    local visualsByType = {}
    local usedVisuals = {}

    if not container or not equipment or not equipment.CreateItem then
        return false
    end

    if itemVisuals and itemVisuals.size then
        for i = 0, itemVisuals:size() - 1 do
            local visual = itemVisuals:get(i)
            local visualType = visual and visual.getItemType and tostring(visual:getItemType() or "") or ""
            if visualType ~= "" then
                visualsByType[visualType] = visualsByType[visualType] or {}
                visualsByType[visualType][#visualsByType[visualType] + 1] = visual
            end
        end
    end

    local function copyLiveVisual(candidate, kind)
        local candidates = visualsByType[tostring(kind or "")] or {}
        local targetVisual = candidate and candidate.getVisual and candidate:getVisual() or nil
        local index
        if not targetVisual or not targetVisual.copyFrom then
            return false
        end
        for index = 1, #candidates do
            if not usedVisuals[candidates[index]] then
                usedVisuals[candidates[index]] = true
                return pcall(targetVisual.copyFrom, targetVisual, candidates[index])
            end
        end
        return false
    end

    local function remember(candidate)
        local kind
        if not candidate or seen[candidate] then
            return candidate
        end
        seen[candidate] = true
        kind = itemFullType(candidate)
        if kind ~= "" then
            pool[kind] = pool[kind] or {}
            pool[kind][#pool[kind] + 1] = candidate
            allItems[#allItems + 1] = candidate
            addItemToContainer(container, candidate)
        end
        return candidate
    end

    local function create(kind)
        local created = equipment.CreateItem(kind)
        if created then
            remember(created)
        end
        return created
    end

    local function takeForInventory(kind)
        local candidates = pool[kind] or {}
        local index
        for index = 1, #candidates do
            if not claimed[candidates[index]] then
                claimed[candidates[index]] = true
                return candidates[index]
            end
        end
        local created = create(kind)
        if created then
            claimed[created] = true
        end
        return created
    end

    local function takeForAppearance(kind)
        local candidates = pool[kind] or {}
        local index
        for index = 1, #candidates do
            if not appearanceUsed[candidates[index]] then
                appearanceUsed[candidates[index]] = true
                return candidates[index]
            end
        end
        local created = create(kind)
        if created then
            appearanceUsed[created] = true
        end
        return created
    end

    if inventoryItems then
        for i = 0, inventoryItems:size() - 1 do
            remember(inventoryItems:get(i))
        end
    end
    if wornItems then
        for i = 0, wornItems:size() - 1 do
            local entry = wornItems:get(i)
            remember(entry and entry.getItem and entry:getItem() or nil)
        end
    end
    remember(zombie.getPrimaryHandItem and zombie:getPrimaryHandItem() or nil)
    remember(zombie.getSecondaryHandItem and zombie:getSecondaryHandItem() or nil)

    -- Materialize the canonical logical inventory first. Live NPC rendering can
    -- use ItemVisuals, but IsoDeadBody only retains real InventoryItem objects.
    if abstractInventory and type(abstractInventory.items) == "table" then
        for _, descriptor in pairs(abstractInventory.items) do
            fullType = descriptor and descriptor.type and tostring(descriptor.type) or ""
            if fullType ~= "" then
                item = takeForInventory(fullType)
                if item and descriptor.cond ~= nil and item.setCondition then
                    pcall(item.setCondition, item, math.max(0, math.floor(tonumber(descriptor.cond) or 0)))
                end
                if item and descriptor.wornSlot and zombie.setWornItem then
                    copyLiveVisual(item, fullType)
                    pcall(zombie.setWornItem, zombie, tostring(descriptor.wornSlot), item)
                elseif item and descriptor.equipSlot == "primary" and zombie.setPrimaryHandItem then
                    pcall(zombie.setPrimaryHandItem, zombie, item)
                elseif item and descriptor.equipSlot == "secondary" and zombie.setSecondaryHandItem then
                    pcall(zombie.setSecondaryHandItem, zombie, item)
                end
            end
        end
    end

    -- Named outfits are often visual-only. Add their real clothing counterparts
    -- and wear them so the corpse preserves both appearance and loot.
    if appearance and type(appearance.outfitItems) == "table" then
        for i = 1, #appearance.outfitItems do
            fullType = tostring(appearance.outfitItems[i] or "")
            if fullType ~= "" then
                item = takeForAppearance(fullType)
                if item and item.getBodyLocation and zombie.setWornItem then
                    local bodyLocation = item:getBodyLocation()
                    if bodyLocation and tostring(bodyLocation) ~= "" then
                        copyLiveVisual(item, fullType)
                        pcall(zombie.setWornItem, zombie, tostring(bodyLocation), item)
                    end
                end
            end
        end
    end

    -- Explicit worn slots take precedence over generated outfit locations.
    if record.equipment and type(record.equipment.worn) == "table" then
        for bodyLocation, kind in pairs(record.equipment.worn) do
            local candidates = pool[tostring(kind)] or {}
            item = candidates[1] or create(tostring(kind))
            if item and zombie.setWornItem then
                copyLiveVisual(item, tostring(kind))
                pcall(zombie.setWornItem, zombie, tostring(bodyLocation), item)
            end
        end
    end
    if wornItems and wornItems.addItemsToItemContainer then
        pcall(wornItems.addItemsToItemContainer, wornItems, container)
    end
    for i = 1, #allItems do
        addItemToContainer(container, allItems[i])
    end
    if PNC.Visuals and PNC.Visuals.RefreshModel then
        PNC.Visuals.RefreshModel(zombie)
    end
    return true
end

Lifecycle.PrepareCorpseItems = prepareCorpseItems

local function clearBodyCombat(zombie)
    if not zombie then
        return
    end
    if PNC.ZombieAggro and PNC.ZombieAggro.ClearForNPCBody then
        pcall(PNC.ZombieAggro.ClearForNPCBody, zombie)
    end
    if zombie.clearAggroList then
        pcall(zombie.clearAggroList, zombie)
    end
    if zombie.setTarget then
        pcall(zombie.setTarget, zombie, nil)
    end
    if zombie.setAttackedBy then
        pcall(zombie.setAttackedBy, zombie, nil)
    end
    if zombie.setUseless then
        pcall(zombie.setUseless, zombie, true)
    end
    if zombie.setRunning then
        pcall(zombie.setRunning, zombie, false)
    end
    if zombie.setReanimate then
        pcall(zombie.setReanimate, zombie, false)
    end
end

local function removeZombie(zombie)
    local ok
    local removed = false
    if not zombie then
        return false
    end
    clearBodyCombat(zombie)
    if VirtualZombieManager and VirtualZombieManager.instance
        and VirtualZombieManager.instance.removeZombieFromWorld
    then
        ok, removed = pcall(
            VirtualZombieManager.instance.removeZombieFromWorld,
            VirtualZombieManager.instance,
            zombie
        )
        removed = ok and removed == true
    end
    if not removed and zombie.removeFromWorld then
        pcall(zombie.removeFromWorld, zombie)
    end
    if not removed and zombie.removeFromSquare then
        pcall(zombie.removeFromSquare, zombie)
    end
    return true
end

local function removeCorpse(corpse)
    local square
    if not corpse then
        return false
    end
    square = corpse.getSquare and corpse:getSquare() or nil
    if square and square.transmitRemoveItemFromSquare then
        pcall(square.transmitRemoveItemFromSquare, square, corpse)
    end
    if corpse.removeFromWorld then
        pcall(corpse.removeFromWorld, corpse)
    end
    if corpse.removeFromSquare then
        pcall(corpse.removeFromSquare, corpse)
    end
    if corpse.setSquare then
        pcall(corpse.setSquare, corpse, nil)
    end
    return true
end

local function forEachCorpse(square, callback)
    local seen = {}
    local list
    local i
    local corpse
    if not square or type(callback) ~= "function" then
        return
    end
    list = square.getDeadBodys and square:getDeadBodys() or nil
    if list then
        for i = list:size() - 1, 0, -1 do
            corpse = list:get(i)
            if corpse and not seen[corpse] then
                seen[corpse] = true
                callback(corpse)
            end
        end
    end
    list = square.getStaticMovingObjects and square:getStaticMovingObjects() or nil
    if list then
        for i = list:size() - 1, 0, -1 do
            corpse = list:get(i)
            if corpse and not seen[corpse]
                and instanceof and instanceof(corpse, "IsoDeadBody")
            then
                seen[corpse] = true
                callback(corpse)
            end
        end
    end
end

local function makeCorpseInert(corpse, createdWorldHour)
    local reanimateAt = (tonumber(createdWorldHour) or worldHour()) + 100000000
    if not corpse then
        return
    end
    if corpse.setFakeDead then
        pcall(corpse.setFakeDead, corpse, false)
    end
    if corpse.setReanimateTime then
        pcall(corpse.setReanimateTime, corpse, reanimateAt)
    end
end

local function stampCorpse(record, corpse, token)
    local modData
    if not record or not corpse or not corpse.getModData then
        return false
    end
    token = tostring(token or Core.GenerateID("corpse"))
    modData = corpse:getModData()
    modData.PNC_NPC = true
    modData.PNC_UUID = tostring(record.id)
    modData.PNC_BodyKind = "corpse"
    modData.PNC_CorpseToken = token
    modData.PNC_TagVersion = Const.BODY_TAG_VERSION
    makeCorpseInert(corpse, record.corpse and record.corpse.createdWorldHour)
    record.corpse = record.corpse or {}
    record.corpse.token = token
    record.corpse.x = corpse.getX and corpse:getX() or record.x
    record.corpse.y = corpse.getY and corpse:getY() or record.y
    record.corpse.z = corpse.getZ and corpse:getZ() or record.z
    record.corpse.createdWorldHour = tonumber(record.corpse.createdWorldHour) or worldHour()
    ensureRuntime(record).corpseState = "inert_loaded"
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "corpse")
    end
    return true
end

function Lifecycle.StampLiveBody(record, zombie)
    local modData
    if not record or not zombie or not zombie.getModData then
        return nil
    end
    record.runtime = record.runtime or {}
    if not record.runtime.bodyLease or tostring(record.runtime.bodyLease) == "" then
        record.runtime.bodyLease = Core.GenerateID("body")
    end
    modData = zombie:getModData()
    modData.PNC_NPC = true
    modData.PNC_UUID = tostring(record.id)
    modData.PNC_BodyKind = "live"
    modData.PNC_BodyLease = tostring(record.runtime.bodyLease)
    modData.PNC_CorpseToken = nil
    modData.PNC_TagVersion = Const.BODY_TAG_VERSION
    mark(record, "live", "bound", "body_stamped")
    return record.runtime.bodyLease
end

local function detachLiveBody(record, reason)
    local reg = registry()
    if record then
        record.runtime = record.runtime or {}
        record.runtime.bodyLease = nil
        if reg and reg.LiveByID then
            reg.LiveByID[record.id] = nil
        end
        record.liveBodyInstanceID = nil
        record.liveBodyOnlineID = nil
        record.presenceRevision = (tonumber(record.presenceRevision) or 0) + 1
        if record.presenceState ~= Const.PRESENCE_CORPSE then
            record.presenceState = Const.PRESENCE_ABSTRACT
            mark(record, "abstract", "missing", reason or "body_removed")
        else
            mark(record, "corpse", "missing", reason or "source_body_removed")
        end
    end
    return true
end

function Lifecycle.RemoveLiveBody(record, zombie, reason)
    if zombie then
        removeZombie(zombie)
    end
    return detachLiveBody(record, reason)
end

local function captureWornEntries(wornItems)
    local entries = {}
    local entry
    local item
    local i
    if not wornItems or not wornItems.size then
        return entries
    end
    for i = 0, wornItems:size() - 1 do
        entry = wornItems:get(i)
        item = entry and entry.getItem and entry:getItem() or nil
        if item then
            entries[#entries + 1] = {
                location = entry.getLocation and tostring(entry:getLocation() or "") or "",
                item = item,
                fullType = itemFullType(item),
            }
        end
    end
    return entries
end

local function applyCorpseWornItems(corpse, wornEntries)
    local targetWornItems
    local container
    local inventoryItems
    local pool = {}
    local claimed = {}
    local applied = 0
    local entry
    local item
    local kind
    local candidates
    local i
    local j
    if not corpse or type(wornEntries) ~= "table" then
        return false
    end
    targetWornItems = corpse.getWornItems and corpse:getWornItems() or nil
    container = corpse.getContainer and corpse:getContainer() or nil
    if not targetWornItems or not targetWornItems.setItem then
        return false
    end
    inventoryItems = container and container.getItems and container:getItems() or nil
    if inventoryItems then
        for i = 0, inventoryItems:size() - 1 do
            item = inventoryItems:get(i)
            kind = itemFullType(item)
            if kind ~= "" then
                pool[kind] = pool[kind] or {}
                pool[kind][#pool[kind] + 1] = item
            end
        end
    end
    if targetWornItems.clear then
        pcall(targetWornItems.clear, targetWornItems)
    end
    for i = 1, #wornEntries do
        entry = wornEntries[i]
        item = nil
        if entry.item and entry.item.getContainer and entry.item:getContainer() == container then
            item = entry.item
        end
        candidates = pool[tostring(entry.fullType or "")] or {}
        if not item then
            for j = 1, #candidates do
                if not claimed[candidates[j]] then
                    item = candidates[j]
                    break
                end
            end
        end
        item = item or entry.item
        if item and entry.location and entry.location ~= "" then
            addItemToContainer(container, item)
            claimed[item] = true
            if pcall(targetWornItems.setItem, targetWornItems, entry.location, item) then
                applied = applied + 1
            end
        end
    end
    if targetWornItems and container and targetWornItems.addItemsToItemContainer then
        pcall(targetWornItems.addItemsToItemContainer, targetWornItems, container)
    end
    return applied > 0 or #wornEntries == 0
end

local function transmitCorpseState(corpse)
    if corpse and isServer and isServer() and corpse.transmitCompleteItemToClients then
        pcall(corpse.transmitCompleteItemToClients, corpse)
    end
end

local function scheduleCorpseFinalize(record, x, y, z, token, reason, wornEntries)
    Lifecycle.PendingCorpses[#Lifecycle.PendingCorpses + 1] = {
        npcId = tostring(record.id),
        x = math.floor(tonumber(x) or 0),
        y = math.floor(tonumber(y) or 0),
        z = math.floor(tonumber(z) or 0),
        token = token,
        reason = reason,
        attempts = 0,
        wornEntries = wornEntries,
    }
end

function Lifecycle.CreateInertCorpse(record, zombie, reason)
    local x
    local y
    local z
    local token
    local createdWorldHour
    local ok
    local corpse
    local converted = false
    local sourceWornItems
    local wornEntries
    if not record or not zombie then
        return false, nil
    end
    x = zombie.getX and zombie:getX() or record.x
    y = zombie.getY and zombie:getY() or record.y
    z = zombie.getZ and zombie:getZ() or record.z
    token = record.corpse and record.corpse.token or Core.GenerateID("corpse")
    createdWorldHour = record.corpse and tonumber(record.corpse.createdWorldHour) or worldHour()
    record.x = x
    record.y = y
    record.z = z
    record.corpse = {
        token = token,
        x = x,
        y = y,
        z = z,
        createdWorldHour = createdWorldHour,
    }
    if zombie.setReanimate then
        pcall(zombie.setReanimate, zombie, false)
    end
    if zombie.setReanim then
        pcall(zombie.setReanim, zombie, false)
    end
    clearBodyCombat(zombie)
    prepareCorpseItems(record, zombie)
    sourceWornItems = zombie.getWornItems and zombie:getWornItems() or nil
    wornEntries = captureWornEntries(sourceWornItems)
    if IsoDeadBody and IsoDeadBody.new then
        ok, corpse = pcall(IsoDeadBody.new, zombie, false, true)
        if not ok or not corpse then
            ok, corpse = pcall(IsoDeadBody.new, zombie, false)
        end
    end
    converted = corpse ~= nil
    if not corpse then
        if zombie.becomeCorpseSilently then
            ok = pcall(zombie.becomeCorpseSilently, zombie)
            converted = ok == true
        end
        if converted then
            scheduleCorpseFinalize(record, x, y, z, token, reason or "death", wornEntries)
            ensureRuntime(record).corpseState = "finalizing"
        else
            removeZombie(zombie)
            ensureRuntime(record).corpseState = "missing"
        end
    end
    record.presenceState = Const.PRESENCE_CORPSE
    detachLiveBody(record, reason or "death")
    mark(record, "corpse", "missing", reason or "death")
    if corpse then
        applyCorpseWornItems(corpse, wornEntries)
        stampCorpse(record, corpse, token)
        transmitCorpseState(corpse)
        ensureRuntime(record).corpseState = "inert_loaded"
    end
    return corpse ~= nil, corpse
end

local function pumpPendingCorpses()
    local cell = getCell and getCell() or nil
    local i
    local pending
    local record
    local square
    local found
    if not cell then
        return
    end
    for i = #Lifecycle.PendingCorpses, 1, -1 do
        pending = Lifecycle.PendingCorpses[i]
        pending.attempts = (tonumber(pending.attempts) or 0) + 1
        record = registry() and registry().Get and registry().Get(pending.npcId) or nil
        square = cell:getGridSquare(pending.x, pending.y, pending.z)
        found = nil
        forEachCorpse(square, function(corpse)
            local modData = corpse.getModData and corpse:getModData() or nil
            if not found and (not modData or not modData.PNC_UUID or tostring(modData.PNC_UUID) == pending.npcId) then
                found = corpse
            end
        end)
        if found and record then
            applyCorpseWornItems(found, pending.wornEntries)
            stampCorpse(record, found, pending.token)
            transmitCorpseState(found)
            table.remove(Lifecycle.PendingCorpses, i)
        elseif pending.attempts >= 8 then
            if record then
                ensureRuntime(record).corpseState = "missing"
                mark(record, "corpse", "missing", "corpse_finalize_timeout", "corpse_not_found")
            end
            table.remove(Lifecycle.PendingCorpses, i)
        end
    end
end

local function auditCorpseRecord(record)
    local cell = getCell and getCell() or nil
    local descriptor = record and record.corpse or nil
    local square
    local accepted
    local token
    local state
    if not cell or not record or record.alive ~= false then
        return
    end
    state = ensureRuntime(record)
    if not descriptor then
        state.corpseState = "missing"
        return
    end
    square = cell:getGridSquare(
        math.floor(tonumber(descriptor.x) or tonumber(record.x) or 0),
        math.floor(tonumber(descriptor.y) or tonumber(record.y) or 0),
        math.floor(tonumber(descriptor.z) or tonumber(record.z) or 0)
    )
    if not square then
        state.corpseState = "unloaded"
        return
    end
    token = descriptor.token and tostring(descriptor.token) or nil
    forEachCorpse(square, function(corpse)
        local modData = corpse.getModData and corpse:getModData() or nil
        local corpseId = modData and modData.PNC_UUID and tostring(modData.PNC_UUID) or nil
        local corpseToken = modData and modData.PNC_CorpseToken and tostring(modData.PNC_CorpseToken) or nil
        if corpseId == tostring(record.id) then
            if not token then
                token = corpseToken or Core.GenerateID("corpse")
                descriptor.token = token
            end
            if corpseToken == token or corpseToken == nil then
                if not accepted then
                    accepted = corpse
                    stampCorpse(record, corpse, token)
                else
                    removeCorpse(corpse)
                end
            else
                removeCorpse(corpse)
            end
        end
    end)
    state.corpseState = accepted and "inert_loaded" or "missing"
end

local function auditCorpseBatch(reg)
    local dead = {}
    local batchSize = math.max(1, tonumber(Const.CORPSE_AUDIT_BATCH_SIZE) or 12)
    local startAt
    local count
    local i
    reg.ForEach(function(candidate)
        if candidate.alive == false then
            dead[#dead + 1] = candidate
        end
    end)
    if #dead <= 0 then
        Lifecycle.CorpseAuditCursor = 1
        return
    end
    table.sort(dead, function(a, b)
        return tostring(a.id or "") < tostring(b.id or "")
    end)
    startAt = math.max(1, math.min(#dead, tonumber(Lifecycle.CorpseAuditCursor) or 1))
    count = math.min(batchSize, #dead)
    for i = 0, count - 1 do
        auditCorpseRecord(dead[((startAt - 1 + i) % #dead) + 1])
    end
    Lifecycle.CorpseAuditCursor = ((startAt - 1 + count) % #dead) + 1
end

function Lifecycle.AuditLoadedBodies(now, force)
    local reg = registry()
    local cell
    local zombieList
    local accepted = {}
    local stats = { scanned = 0, removed = 0, rebound = 0, duplicates = 0, corpses = 0 }
    local i
    local zombie
    local modData
    local npcId
    local kind
    local lease
    local tagVersion
    local record
    local expected
    now = tonumber(now) or Core.Now()
    if not Core.IsAuthority() or not reg or not reg.EnsureLoaded then
        return stats
    end
    if not force and now < (tonumber(Lifecycle.NextAuditAt) or 0) then
        pumpPendingCorpses()
        return Lifecycle.LastAudit
    end
    Lifecycle.NextAuditAt = now + (tonumber(Const.BODY_AUDIT_INTERVAL_MS) or 250)
    reg.EnsureLoaded()
    cell = getCell and getCell() or nil
    zombieList = cell and cell.getZombieList and cell:getZombieList() or nil
    if zombieList then
        for i = zombieList:size() - 1, 0, -1 do
            zombie = zombieList:get(i)
            modData = zombie and zombie.getModData and zombie:getModData() or nil
            if modData and modData.PNC_NPC == true then
                stats.scanned = stats.scanned + 1
                npcId = modData.PNC_UUID and tostring(modData.PNC_UUID) or nil
                kind = tostring(modData.PNC_BodyKind or "live")
                lease = modData.PNC_BodyLease and tostring(modData.PNC_BodyLease) or nil
                tagVersion = tonumber(modData.PNC_TagVersion)
                record = npcId and reg.Get(npcId) or nil
                if kind == "corpse" and record and record.alive == false then
                    stats.corpses = stats.corpses + 1
                    record.runtime = record.runtime or {}
                    record.runtime.corpseRecoveryAttempts = (tonumber(record.runtime.corpseRecoveryAttempts) or 0) + 1
                    if record.runtime.corpseRecoveryAttempts <= (tonumber(Const.CORPSE_REANIMATE_RETRY_MAX) or 3) then
                        Lifecycle.CreateInertCorpse(record, zombie, "corpse_reanimated")
                    else
                        removeZombie(zombie)
                        ensureRuntime(record).corpseState = "missing"
                        mark(record, "corpse", "stale_cleaned", "corpse_recovery_capped", "reanimation_retry_limit")
                    end
                elseif kind == "live"
                    and record
                    and record.alive ~= false
                    and record.presenceState == Const.PRESENCE_LIVE
                    and record.runtime
                    and record.runtime.bodyLease
                    and lease == tostring(record.runtime.bodyLease)
                    and tagVersion == tonumber(Const.BODY_TAG_VERSION)
                then
                    if not accepted[npcId] then
                        accepted[npcId] = zombie
                        expected = reg.LiveByID and reg.LiveByID[npcId] or nil
                        if expected ~= zombie then
                            reg.LiveByID[npcId] = zombie
                            record.liveBodyInstanceID = zombie.getPersistentOutfitID and zombie:getPersistentOutfitID() or nil
                            record.liveBodyOnlineID = normalizeOnlineID(zombie)
                            stats.rebound = stats.rebound + 1
                        end
                        ensureRuntime(record).lastAuditAt = now
                        mark(record, "live", "bound", "body_audit_valid")
                    else
                        stats.duplicates = stats.duplicates + 1
                        stats.removed = stats.removed + 1
                        noteCleanup(record, "duplicate", "duplicate_lease_removed")
                        removeZombie(zombie)
                    end
                else
                    stats.removed = stats.removed + 1
                    if record then
                        noteCleanup(record, "stale_cleaned", "orphan_body_removed")
                        mark(record, record.presenceState, "stale_cleaned", "orphan_body_removed")
                    end
                    removeZombie(zombie)
                end
            end
        end
    end
    if zombieList then
        reg.ForEach(function(candidate)
            local id = tostring(candidate.id)
            local registered = reg.LiveByID and reg.LiveByID[id] or nil
            if candidate.presenceState == Const.PRESENCE_LIVE and not accepted[id] then
                if registered then
                    removeZombie(registered)
                end
                reg.LiveByID[id] = nil
                candidate.runtime = candidate.runtime or {}
                candidate.runtime.bodyLease = nil
                candidate.liveBodyInstanceID = nil
                candidate.liveBodyOnlineID = nil
                candidate.presenceState = Const.PRESENCE_ABSTRACT
                candidate.presenceRevision = (tonumber(candidate.presenceRevision) or 0) + 1
                mark(candidate, "abstract", "missing", registered and "body_invalid" or "body_pruned")
            end
        end)
    end
    pumpPendingCorpses()
    if force or now >= (tonumber(Lifecycle.NextCorpseAuditAt) or 0) then
        Lifecycle.NextCorpseAuditAt = now + (tonumber(Const.CORPSE_AUDIT_INTERVAL_MS) or 1000)
        auditCorpseBatch(reg)
    end
    Lifecycle.LastAudit = stats
    return stats
end

function Lifecycle.BuildDiagnostics(record)
    local state
    local body
    local bite
    local diagnosticBodyState
    if not record then
        return nil
    end
    state = ensureRuntime(record)
    body = registry() and registry().GetLiveZombie and registry().GetLiveZombie(record.id) or nil
    bite = record.runtime and record.runtime.lastZombieBite or nil
    diagnosticBodyState = state.bodyState
    if record.presenceState == Const.PRESENCE_CORPSE then
        diagnosticBodyState = state.corpseState == "inert_loaded" and "corpse-loaded" or "corpse-missing"
    end
    return {
        id = tostring(record.id),
        name = record.name,
        faction = record.faction,
        presenceState = record.presenceState,
        alive = record.alive ~= false,
        phase = state.phase,
        bodyState = diagnosticBodyState,
        bodyLease = record.runtime and record.runtime.bodyLease or nil,
        liveBodyOnlineID = record.liveBodyOnlineID,
        liveBodyInstanceID = record.liveBodyInstanceID,
        x = record.x,
        y = record.y,
        z = record.z,
        lastReason = state.lastReason,
        lastTransitionAt = state.lastTransitionAt,
        lastAuditAt = state.lastAuditAt,
        lastError = state.lastError,
        lastCleanupState = state.lastCleanupState,
        lastCleanupReason = state.lastCleanupReason,
        lastCleanupAt = state.lastCleanupAt,
        corpseState = state.corpseState,
        corpseToken = record.corpse and record.corpse.token or nil,
        bodyActionState = body and body.getActionStateName and body:getActionStateName() or nil,
        activeJob = record.activeJob,
        activeBehavior = record.activeBehavior,
        healthState = record.health and record.health.state or nil,
        hpCurrent = record.health and record.health.current or nil,
        hpMax = record.health and record.health.max or nil,
        targetKind = record.runtime and record.runtime.targetKind or "none",
        combatBlockReason = record.runtime and record.runtime.combatBlockReason or nil,
        bite = bite and Core.DeepCopy(bite) or nil,
    }
end
