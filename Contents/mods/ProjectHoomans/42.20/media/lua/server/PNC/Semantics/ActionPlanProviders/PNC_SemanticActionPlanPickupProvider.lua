-- Unified ActionPlan provider for PICKUP (ground items, room containers, or
-- named container) and STORE (deposit into container).
-- Strictly enforces colonist-only server authority via BehaviorScriptCompiler.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.Semantics.ActionPlanProviders = PNC.Semantics.ActionPlanProviders or {}

local Compiler = PNC.ConvoEngine and PNC.ConvoEngine.BehaviorScriptCompiler
    or require "PNC/ConvoEngine/BehaviorScriptCompiler"

local Provider = PNC.Semantics.ActionPlanProviders.Pickup or {}
PNC.Semantics.ActionPlanProviders.Pickup = Provider

Provider.VERSION = 1
Provider.MAX_ITEMS_PER_STEP = 12
Provider.DEFAULT_AREA_RADIUS = 10

local CATEGORY_KEYWORDS = {
    food    = { "food", "canned", "bread", "chips", "apple", "soup", "beans", "meat", "pasta", "rice", "cereal", "snack" },
    water   = { "water", "bottle", "canteen", "flask", "jug", "drink", "soda", "juice" },
    medical = { "bandage", "bandaid", "firstaid", "disinfectant", "alcohol", "antibiotic", "painkiller", "suture", "splint", "gauze", "med" },
    ammo    = { "ammo", "bullet", "shells", "cartridge", "box", "magazine", "clip" },
    weapon  = { "axe", "bat", "knife", "crowbar", "hammer", "pistol", "rifle", "shotgun", "machete", "katana", "spear" },
    tool    = { "hammer", "saw", "screwdriver", "wrench", "torch", "welder", "shovel", "trowel", "rope" },
}

local function call(obj, method, ...)
    local fn = obj and obj[method]
    if type(fn) ~= "function" then return nil end
    local ok, v = pcall(fn, obj, ...)
    return ok and v or nil
end

local function lower(v)
    return string.lower(tostring(v or ""))
end

local function listSize(list)
    local sz = call(list, "size")
    if sz ~= nil then return math.max(0, math.floor(tonumber(sz) or 0)) end
    return type(list) == "table" and #list or 0
end

local function listItem(list, idx)
    local it = call(list, "get", idx)
    if it ~= nil then return it end
    return type(list) == "table" and list[idx + 1] or nil
end

function Provider.ItemMatchesFilter(item, filter)
    if not item then return false end
    local f = lower(filter)
    if f == "" or f == "all" or f == "everything" or f == "items" then
        return true
    end
    local ms = PNC.Semantics and PNC.Semantics.MarketSenseAdapter or nil
    if ms and type(ms.MatchesCategory) == "function" then
        local ok, matched = pcall(ms.MatchesCategory, item, f)
        if ok and matched == true then return true end
    end
    local cat = lower(call(item, "getCategory"))
    local dispCat = lower(call(item, "getDisplayCategory"))
    local name = lower(call(item, "getDisplayName") or call(item, "getName"))
    local fType = lower(call(item, "getFullType") or call(item, "getType"))
    if f == "food" and (call(item, "IsFood") == true or cat == "food" or dispCat == "food") then
        return true
    end
    if f == "medical" and (cat == "firstaid" or dispCat == "firstaid" or string.find(dispCat, "med", 1, true) ~= nil) then
        return true
    end
    if f == "weapon" and (call(item, "IsWeapon") == true or cat == "weapon") then
        return true
    end
    if string.find(name, f, 1, true) or string.find(fType, f, 1, true)
        or string.find(cat, f, 1, true) or string.find(dispCat, f, 1, true)
    then
        return true
    end
    local kws = CATEGORY_KEYWORDS[f]
    if kws then
        for i = 1, #kws do
            if string.find(name, kws[i], 1, true) or string.find(fType, kws[i], 1, true) then
                return true
            end
        end
    end
    return false
end

-- Ephemeral per-boot tile claims so multiple colonists fanning out across a
-- room/building naturally pick distinct containers/spots without colliding.
Provider.ClaimedTiles = Provider.ClaimedTiles or {}
Provider.CLAIM_TTL_MS = 8000

local function tileKey(x, y, z)
    return tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z or 0)
end

function Provider.ClaimTile(x, y, z, npcId, now)
    if npcId == nil then return end
    local k = tileKey(x, y, z)
    Provider.ClaimedTiles[k] = {
        npcId = tostring(npcId),
        expiresAt = (tonumber(now) or 0) + Provider.CLAIM_TTL_MS,
    }
end

function Provider.ReleaseClaimsFor(npcId)
    if npcId == nil then return end
    local target = tostring(npcId)
    local toClear = {}
    for k, entry in pairs(Provider.ClaimedTiles) do
        if type(entry) == "table" and entry.npcId == target then
            toClear[#toClear + 1] = k
        end
    end
    for i = 1, #toClear do
        Provider.ClaimedTiles[toClear[i]] = nil
    end
end

function Provider.IsTileClaimedByOther(x, y, z, npcId, now)
    local k = tileKey(x, y, z)
    local entry = Provider.ClaimedTiles[k]
    if type(entry) ~= "table" then return false end
    local t = tonumber(now) or 0
    if t > 0 and t >= (tonumber(entry.expiresAt) or 0) then
        Provider.ClaimedTiles[k] = nil
        return false
    end
    return entry.npcId ~= tostring(npcId or "")
end

local function squareMatchesAreaScope(square, actorSquare, areaScope, cell)
    if type(areaScope) ~= "table" then return true end
    local anchorSq = actorSquare
    if cell and areaScope.roomX ~= nil and areaScope.roomY ~= nil then
        local playerSq = cell:getGridSquare(areaScope.roomX, areaScope.roomY, areaScope.roomZ or 0)
        if playerSq then anchorSq = playerSq end
    end
    if areaScope.kind == "building" then
        local anchorBldg = call(anchorSq, "getBuilding")
        local sqBldg = call(square, "getBuilding")
        if anchorBldg and sqBldg then
            return sqBldg == anchorBldg
        end
        -- Fallback if mock/outdoor square has no getBuilding(): match any indoor room
        -- when anchor is indoors, or any square when outdoors.
        if call(anchorSq, "getRoom") ~= nil then
            return call(square, "getRoom") ~= nil
        end
        return true
    end
    if areaScope.kind ~= "room" then return true end
    local sqRoom = call(square, "getRoom")
    if not sqRoom then return false end
    local wantedRoom = lower(areaScope.room)
    if wantedRoom == "room" or areaScope.currentOnly == true then
        local anchorRoom = call(anchorSq, "getRoom")
        if anchorRoom and sqRoom == anchorRoom then return true end
        if wantedRoom == "room" then return false end
    end
    local roomName = lower(call(sqRoom, "getName"))
    return roomName ~= "" and string.find(roomName, wantedRoom, 1, true) ~= nil
end

-- Iterates all containers on a world IsoObject (supporting multi-container
-- furniture like fridge + freezer via getContainerCount/getContainerByIndex)
-- and populates unexplored PZ containers via ItemPicker.fillContainer.
local function forEachObjectContainer(obj, player, fn)
    if not obj then return end
    local cCount = tonumber(call(obj, "getContainerCount")) or 0
    if cCount > 0 and type(obj.getContainerByIndex) == "function" then
        for ci = 0, cCount - 1 do
            local c = call(obj, "getContainerByIndex", ci)
            if c then
                if call(c, "isExplored") == false and ItemPicker and type(ItemPicker.fillContainer) == "function" then
                    pcall(ItemPicker.fillContainer, c, player)
                    call(c, "setExplored", true)
                end
                if fn(c) == true then return end
            end
        end
        return
    end
    local c = call(obj, "getContainer")
    if c then
        if call(c, "isExplored") == false and ItemPicker and type(ItemPicker.fillContainer) == "function" then
            pcall(ItemPicker.fillContainer, c, player)
            call(c, "setExplored", true)
        end
        fn(c)
    end
end

local function addItemToNPC(record, body, item)
    if not item then return false, nil end
    local inv = PNC.Inventory
    if inv and type(inv.CommitLiveItem) == "function" then
        local ok, reason = inv.CommitLiveItem(record, body, item, "script_pickup")
        return ok == true, ok and nil or reason
    end
    local fullType = call(item, "getFullType") or call(item, "getType")
    if inv and type(inv.AddItemsAndSync) == "function" and fullType then
        local ok, reason = inv.AddItemsAndSync(
            record, body, { { type = tostring(fullType), stack = 1 } }, "root", "script_pickup"
        )
        return ok == true, ok and nil or reason
    end
    if inv and type(inv.AddItems) == "function" and fullType then
        local specs = { { type = tostring(fullType), stack = 1 } }
        local ok, addReason, addedIds = inv.AddItems(record, specs, "root", "script_pickup")
        if ok then
            if body and type(addedIds) == "table" and type(inv.MaterializeItem) == "function" then
                for i = 1, #addedIds do
                    pcall(inv.MaterializeItem, record, body, addedIds[i])
                end
            end
            if PNC.Registry and type(PNC.Registry.MarkDirty) == "function" then
                pcall(PNC.Registry.MarkDirty, record, "inventory")
            end
            return true, nil
        end
        return false, addReason or "inventory_add_failed"
    end
    local bodyInv = call(body, "getInventory")
    if bodyInv and type(bodyInv.AddItem) == "function" then
        local ok = pcall(bodyInv.AddItem, bodyInv, item)
        if ok then return true, nil end
    end
    return false, "inventory_unavailable"
end

local function canCarryMore(record, body)
    local bodyInv = call(body, "getInventory")
    if bodyInv and type(bodyInv.getCapacityWeight) == "function" and type(bodyInv.getEffectiveCapacity) == "function" then
        local cur = tonumber(call(bodyInv, "getCapacityWeight")) or 0
        local cap = tonumber(call(bodyInv, "getEffectiveCapacity", body)) or 50
        if cap > 0 and cur >= (cap * 0.92) then return false end
    end
    return true
end

local function itemDisplayName(item)
    local n = call(item, "getDisplayName") or call(item, "getName")
    if type(n) == "string" and n ~= "" then return n end
    return "supplies"
end

local function itemCategoryName(item)
    local ms = PNC.Semantics and PNC.Semantics.MarketSenseAdapter or nil
    if ms and type(ms.GetSummaryCategory) == "function" then
        local ok, msCat = pcall(ms.GetSummaryCategory, item)
        if ok and type(msCat) == "string" and msCat ~= "" then
            return msCat
        end
    end
    if call(item, "IsFood") == true then return "food" end
    if call(item, "IsWeapon") == true then return "weapon" end
    local dc = call(item, "getDisplayCategory")
    if type(dc) == "string" and dc ~= "" then return lower(dc) end
    local c = call(item, "getCategory")
    if type(c) == "string" and c ~= "" then return lower(c) end
    return "item"
end

local function takeFromContainer(record, body, container, filter, remaining, pickedNames, pickedDetails)
    local items = call(container, "getItems")
    if not items then return 0, false end
    local taken = 0
    for idx = listSize(items) - 1, 0, -1 do
        if taken >= remaining then break end
        if not canCarryMore(record, body) then return taken, true end
        local item = listItem(items, idx)
        if item and Provider.ItemMatchesFilter(item, filter) then
            local name = itemDisplayName(item)
            local cat = itemCategoryName(item)
            local added, addErr = addItemToNPC(record, body, item)
            if added then
                call(container, "Remove", item)
                if type(isServer) == "function" and isServer() == true and type(sendRemoveItemFromContainer) == "function" then
                    pcall(sendRemoveItemFromContainer, container, item)
                end
                taken = taken + 1
                if pickedNames then pickedNames[#pickedNames + 1] = name end
                if pickedDetails then pickedDetails[#pickedDetails + 1] = { name = name, category = cat } end
            elseif addErr == "pack_full" or addErr == "no_capacity" or addErr == "capacity_exceeded" then
                return taken, true
            end
        end
    end
    return taken, false
end

local function containerMatchesTarget(obj, container, targetText)
    if not targetText or targetText == "" then return true end
    local wanted = lower(targetText)
    local cType = lower(call(container, "getType"))
    local oName = lower(call(obj, "getObjectName"))
    local name = lower(call(obj, "getName"))
    local sprite = lower(call(obj, "getSpriteName") or call(call(obj, "getSprite"), "getName"))
    local combined = cType .. " " .. oName .. " " .. name .. " " .. sprite
    if wanted == "fridge" or wanted == "refrigerator" or wanted == "freezer" then
        return string.find(combined, "fridge", 1, true) ~= nil
            or string.find(combined, "freezer", 1, true) ~= nil
            or string.find(combined, "refrigerator", 1, true) ~= nil
    end
    if wanted == "pantry" or wanted == "cupboard" or wanted == "cabinet" or wanted == "cabinets" or wanted == "counter" or wanted == "counters" then
        return string.find(combined, "counter", 1, true) ~= nil
            or string.find(combined, "cupboard", 1, true) ~= nil
            or string.find(combined, "cabinet", 1, true) ~= nil
            or string.find(combined, "pantry", 1, true) ~= nil
            or string.find(combined, "shelves", 1, true) ~= nil
    end
    return string.find(combined, wanted, 1, true) ~= nil
end

local function containerFindMatchingItem(container, filter)
    local items = call(container, "getItems")
    if not items then return nil end
    for idx = 0, listSize(items) - 1 do
        local item = listItem(items, idx)
        if item and Provider.ItemMatchesFilter(item, filter) then
            return item
        end
    end
    return nil
end

-- Finds the closest tile in `areaScope` that contains at least one matching
-- ground item, container item, or corpse item so the NPC physically walks to
-- each loot spot instead of teleport-vacuuming across the room.
function Provider.FindNextLootSpot(record, body, step, context)
    context = type(context) == "table" and context or {}
    local cell = context.cell or (type(getCell) == "function" and getCell()) or nil
    if not cell or type(cell.getGridSquare) ~= "function" then return nil end

    local ax = math.floor(tonumber(
        (step.areaScope and step.areaScope.roomX) or call(body, "getX") or record.x) or 0)
    local ay = math.floor(tonumber(
        (step.areaScope and step.areaScope.roomY) or call(body, "getY") or record.y) or 0)
    local az = math.floor(tonumber(
        (step.areaScope and step.areaScope.roomZ) or call(body, "getZ") or record.z) or 0)
    local bx = tonumber(call(body, "getX") or record.x) or ax
    local by = tonumber(call(body, "getY") or record.y) or ay
    local actorSq = cell:getGridSquare(ax, ay, az)
    local radius = math.max(1, math.min(16, tonumber(step.radius) or Provider.DEFAULT_AREA_RADIUS))
    local includeGround = step.includeGround ~= false
    local includeContainers = step.includeContainers == true
    local filter = step.filter or "all"
    local targetText = type(step.target) == "table" and step.target.text or nil
    local wantCorpse = targetText == "corpse" or targetText == "body"
    local npcId = record and record.id or nil
    local now = tonumber(context.now) or (PNC.Core and type(PNC.Core.Now) == "function" and tonumber(PNC.Core.Now()) or 0)

    local best = nil
    for dx = -radius, radius do
        for dy = -radius, radius do
            if (dx * dx + dy * dy) <= (radius * radius) then
                local sx, sy = ax + dx, ay + dy
                if not (npcId and Provider.IsTileClaimedByOther(sx, sy, az, npcId, now)) then
                    local sq = cell:getGridSquare(sx, sy, az)
                    if sq and squareMatchesAreaScope(sq, actorSq, step.areaScope, cell) then
                        local sourceKind = nil
                        local matchedItemName = nil
                        if includeGround and not targetText then
                            local wObjs = call(sq, "getWorldObjects")
                            for idx = 0, listSize(wObjs) - 1 do
                                local invItem = call(listItem(wObjs, idx), "getItem")
                                if invItem and Provider.ItemMatchesFilter(invItem, filter) then
                                    sourceKind = "ground"
                                    matchedItemName = itemDisplayName(invItem)
                                    break
                                end
                            end
                        end
                        if not sourceKind and includeContainers and not wantCorpse then
                            local objs = call(sq, "getObjects")
                            for idx = 0, listSize(objs) - 1 do
                                local obj = listItem(objs, idx)
                                forEachObjectContainer(obj, context.player, function(c)
                                    if containerMatchesTarget(obj, c, targetText) then
                                        local foundItem = containerFindMatchingItem(c, filter)
                                        if foundItem then
                                            sourceKind = "container"
                                            matchedItemName = itemDisplayName(foundItem)
                                            return true
                                        end
                                    end
                                    return false
                                end)
                                if sourceKind then break end
                            end
                        end
                        if not sourceKind and includeContainers and (not targetText or wantCorpse) then
                            local bodies = call(sq, "getDeadBodys")
                            for idx = 0, listSize(bodies) - 1 do
                                local c = call(listItem(bodies, idx), "getContainer")
                                if c then
                                    local foundItem = containerFindMatchingItem(c, filter)
                                    if foundItem then
                                        sourceKind = "corpse"
                                        matchedItemName = itemDisplayName(foundItem)
                                        break
                                    end
                                end
                            end
                        end
                        if sourceKind then
                            local distSq = (sx + 0.5 - bx) * (sx + 0.5 - bx) + (sy + 0.5 - by) * (sy + 0.5 - by)
                            if not best or distSq < best.distSq then
                                best = {
                                    x = sx,
                                    y = sy,
                                    z = az,
                                    distSq = distSq,
                                    sourceKind = sourceKind,
                                    itemName = matchedItemName,
                                }
                            end
                        end
                    end
                end
            end
        end
    end
    if best and npcId then
        Provider.ClaimTile(best.x, best.y, best.z, npcId, now)
    end
    return best
end

-- Unified PICKUP primitive:
-- - If `context.container` is provided (targeted container like "pantry"), takes from it.
-- - Otherwise scans the area / room for matching ground items (and room containers when enabled).
function Provider.ExecutePickup(record, body, step, context)
    context = type(context) == "table" and context or {}
    local allowed, authReason = Compiler.CanExecuteScript(record, context.player)
    if not allowed then return false, authReason, 0, {} end

    local maxCount = tonumber(context.maxCount)
        or ((step.quantity == "one") and 1 or Provider.MAX_ITEMS_PER_STEP)
    local filter = step.filter or "all"
    local pickedNames = {}
    local pickedDetails = {}

    if context.container then
        local container = call(context.container, "getContainer") or context.container
        local taken, full = takeFromContainer(record, body, container, filter, maxCount, pickedNames, pickedDetails)
        if full then return taken > 0, "pack_full", taken, pickedNames, pickedDetails end
        if taken == 0 then return false, "no_matching_items", 0, pickedNames, pickedDetails end
        return true, "picked_up", taken, pickedNames, pickedDetails
    end

    local cell = context.cell or (type(getCell) == "function" and getCell()) or nil
    if not cell or type(cell.getGridSquare) ~= "function" then
        return false, "world_cell_unavailable", 0, pickedNames, pickedDetails
    end
    local ax = math.floor(tonumber(
        context.originX or (step.areaScope and step.areaScope.roomX) or call(body, "getX") or record.x) or 0)
    local ay = math.floor(tonumber(
        context.originY or (step.areaScope and step.areaScope.roomY) or call(body, "getY") or record.y) or 0)
    local az = math.floor(tonumber(
        context.originZ or (step.areaScope and step.areaScope.roomZ) or call(body, "getZ") or record.z) or 0)
    local actorSq = cell:getGridSquare(ax, ay, az)
    local radius = math.max(0, math.min(16, tonumber(context.radius) or tonumber(step.radius) or Provider.DEFAULT_AREA_RADIUS))
    local includeGround = step.includeGround ~= false
    local includeContainers = step.includeContainers == true
    local targetText = type(step.target) == "table" and step.target.text or nil
    local wantCorpse = targetText == "corpse" or targetText == "body"
    local picked = 0

    for dx = -radius, radius do
        for dy = -radius, radius do
            if picked >= maxCount then break end
            if (dx * dx + dy * dy) <= (radius * radius) then
                local sq = cell:getGridSquare(ax + dx, ay + dy, az)
                if sq and squareMatchesAreaScope(sq, actorSq, step.areaScope, cell) then
                    if includeGround and not targetText then
                        local wObjs = call(sq, "getWorldObjects")
                        for idx = listSize(wObjs) - 1, 0, -1 do
                            if picked >= maxCount then break end
                            if not canCarryMore(record, body) then
                                return picked > 0, "pack_full", picked, pickedNames
                            end
                            local wObj = listItem(wObjs, idx)
                            local invItem = call(wObj, "getItem")
                            if invItem and Provider.ItemMatchesFilter(invItem, filter) then
                                local name = itemDisplayName(invItem)
                                local cat = itemCategoryName(invItem)
                                if addItemToNPC(record, body, invItem) then
                                    call(sq, "removeWorldObject", wObj)
                                    picked = picked + 1
                                    pickedNames[#pickedNames + 1] = name
                                    pickedDetails[#pickedDetails + 1] = { name = name, category = cat }
                                end
                            end
                        end
                    end
                    if includeContainers and not wantCorpse and picked < maxCount then
                        local objs = call(sq, "getObjects")
                        local hitFull = false
                        for idx = 0, listSize(objs) - 1 do
                            if picked >= maxCount or hitFull then break end
                            local obj = listItem(objs, idx)
                            forEachObjectContainer(obj, context.player, function(c)
                                if picked >= maxCount then return true end
                                if containerMatchesTarget(obj, c, targetText) then
                                    local taken, full = takeFromContainer(record, body, c, filter, maxCount - picked, pickedNames, pickedDetails)
                                    picked = picked + taken
                                    if full then
                                        hitFull = true
                                        return true
                                    end
                                end
                                return false
                            end)
                        end
                        if hitFull then return picked > 0, "pack_full", picked, pickedNames, pickedDetails end
                    end
                    if includeContainers and (not targetText or wantCorpse) and picked < maxCount then
                        local bodies = call(sq, "getDeadBodys")
                        for idx = 0, listSize(bodies) - 1 do
                            if picked >= maxCount then break end
                            local c = call(listItem(bodies, idx), "getContainer")
                            if c then
                                local taken, full = takeFromContainer(record, body, c, filter, maxCount - picked, pickedNames, pickedDetails)
                                picked = picked + taken
                                if full then return picked > 0, "pack_full", picked, pickedNames, pickedDetails end
                            end
                        end
                    end
                end
            end
        end
        if picked >= maxCount then break end
    end

    if picked == 0 then return false, "no_matching_items", 0, pickedNames, pickedDetails end
    return true, "picked_up", picked, pickedNames, pickedDetails
end

-- Unified STORE primitive: deposits matching items from NPC inventory into container.
function Provider.ExecuteStore(record, body, step, context)
    context = type(context) == "table" and context or {}
    local allowed, authReason = Compiler.CanExecuteScript(record, context.player)
    if not allowed then return false, authReason, 0 end

    local container = call(context.container, "getContainer") or context.container
    local bodyInv = call(body, "getInventory")
    local items = call(bodyInv, "getItems")
    if not container or not items then return false, "inventory_or_container_unavailable", 0 end

    local maxCount = (step.quantity == "one") and 1 or Provider.MAX_ITEMS_PER_STEP
    local filter = step.filter or "all"
    local stored = 0

    for idx = listSize(items) - 1, 0, -1 do
        if stored >= maxCount then break end
        local item = listItem(items, idx)
        if item and Provider.ItemMatchesFilter(item, filter) then
            local okAdd = pcall(container.AddItem, container, item)
            if okAdd then
                call(bodyInv, "Remove", item)
                stored = stored + 1
            end
        end
    end

    if stored == 0 then return false, "no_matching_items_to_store", 0 end
    return true, "stored", stored
end

local Service = PNC.Semantics and PNC.Semantics.ActionPlanService or nil
if Service and type(Service.RegisterProvider) == "function" then
    Service.RegisterProvider("PICKUP", Provider)
    Service.RegisterProvider("STORE", Provider)
end

return Provider
