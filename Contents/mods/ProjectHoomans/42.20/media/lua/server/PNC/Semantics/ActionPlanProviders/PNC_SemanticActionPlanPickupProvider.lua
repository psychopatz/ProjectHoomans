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

local function squareMatchesAreaScope(square, actorSquare, areaScope, cell)
    if type(areaScope) ~= "table" or areaScope.kind ~= "room" then return true end
    local sqRoom = call(square, "getRoom")
    if not sqRoom then return false end
    local anchorSq = actorSquare
    if cell and areaScope.roomX ~= nil and areaScope.roomY ~= nil then
        local playerSq = cell:getGridSquare(areaScope.roomX, areaScope.roomY, areaScope.roomZ or 0)
        if playerSq then anchorSq = playerSq end
    end
    local wantedRoom = lower(areaScope.room)
    if wantedRoom == "room" or areaScope.currentOnly == true then
        local anchorRoom = call(anchorSq, "getRoom")
        if anchorRoom and sqRoom == anchorRoom then return true end
        if wantedRoom == "room" then return false end
    end
    local roomName = lower(call(sqRoom, "getName"))
    return roomName ~= "" and string.find(roomName, wantedRoom, 1, true) ~= nil
end

local function addItemToNPC(record, body, item)
    if not item then return false end
    local inv = PNC.Inventory
    local fullType = call(item, "getFullType") or call(item, "getType")
    if inv and type(inv.AddItems) == "function" and fullType then
        local ok = inv.AddItems(record, { { type = tostring(fullType), stack = 1 } }, "root", "script_pickup")
        if ok then return true end
    end
    local bodyInv = call(body, "getInventory")
    if bodyInv and type(bodyInv.AddItem) == "function" then
        local ok = pcall(bodyInv.AddItem, bodyInv, item)
        if ok then return true end
    end
    return false
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

local function takeFromContainer(record, body, container, filter, remaining)
    local items = call(container, "getItems")
    if not items then return 0, false end
    local taken = 0
    for idx = listSize(items) - 1, 0, -1 do
        if taken >= remaining then break end
        if not canCarryMore(record, body) then return taken, true end
        local item = listItem(items, idx)
        if item and Provider.ItemMatchesFilter(item, filter) then
            if addItemToNPC(record, body, item) then
                call(container, "Remove", item)
                taken = taken + 1
            end
        end
    end
    return taken, false
end

-- Unified PICKUP primitive:
-- - If `context.container` is provided (targeted container like "pantry"), takes from it.
-- - Otherwise scans the area / room for matching ground items (and room containers when enabled).
function Provider.ExecutePickup(record, body, step, context)
    context = type(context) == "table" and context or {}
    local allowed, authReason = Compiler.CanExecuteScript(record, context.player)
    if not allowed then return false, authReason, 0 end

    local maxCount = (step.quantity == "one") and 1 or Provider.MAX_ITEMS_PER_STEP
    local filter = step.filter or "all"

    if context.container then
        local container = call(context.container, "getContainer") or context.container
        local taken, full = takeFromContainer(record, body, container, filter, maxCount)
        if full then return taken > 0, "pack_full", taken end
        if taken == 0 then return false, "no_matching_items", 0 end
        return true, "picked_up", taken
    end

    local cell = context.cell or (type(getCell) == "function" and getCell()) or nil
    if not cell or type(cell.getGridSquare) ~= "function" then
        return false, "world_cell_unavailable", 0
    end
    local ax = math.floor(tonumber(
        (step.areaScope and step.areaScope.roomX) or call(body, "getX") or record.x) or 0)
    local ay = math.floor(tonumber(
        (step.areaScope and step.areaScope.roomY) or call(body, "getY") or record.y) or 0)
    local az = math.floor(tonumber(
        (step.areaScope and step.areaScope.roomZ) or call(body, "getZ") or record.z) or 0)
    local actorSq = cell:getGridSquare(ax, ay, az)
    local radius = math.max(1, math.min(16, tonumber(step.radius) or Provider.DEFAULT_AREA_RADIUS))
    local includeGround = step.includeGround ~= false
    local includeContainers = step.includeContainers == true
    local picked = 0

    for dx = -radius, radius do
        for dy = -radius, radius do
            if picked >= maxCount then break end
            if (dx * dx + dy * dy) <= (radius * radius) then
                local sq = cell:getGridSquare(ax + dx, ay + dy, az)
                if sq and squareMatchesAreaScope(sq, actorSq, step.areaScope, cell) then
                    if includeGround then
                        local wObjs = call(sq, "getWorldObjects")
                        for idx = listSize(wObjs) - 1, 0, -1 do
                            if picked >= maxCount then break end
                            if not canCarryMore(record, body) then
                                return picked > 0, "pack_full", picked
                            end
                            local wObj = listItem(wObjs, idx)
                            local invItem = call(wObj, "getItem")
                            if invItem and Provider.ItemMatchesFilter(invItem, filter) then
                                if addItemToNPC(record, body, invItem) then
                                    call(sq, "removeWorldObject", wObj)
                                    picked = picked + 1
                                end
                            end
                        end
                    end
                    if includeContainers and picked < maxCount then
                        local objs = call(sq, "getObjects")
                        for idx = 0, listSize(objs) - 1 do
                            if picked >= maxCount then break end
                            local c = call(listItem(objs, idx), "getContainer")
                            if c then
                                local taken, full = takeFromContainer(record, body, c, filter, maxCount - picked)
                                picked = picked + taken
                                if full then return picked > 0, "pack_full", picked end
                            end
                        end
                    end
                end
            end
        end
        if picked >= maxCount then break end
    end

    if picked == 0 then return false, "no_matching_items", 0 end
    return true, "picked_up", picked
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
