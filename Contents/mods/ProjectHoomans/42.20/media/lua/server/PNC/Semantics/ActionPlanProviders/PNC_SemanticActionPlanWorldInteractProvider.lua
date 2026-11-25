-- Modular ActionPlan provider for the remaining orthogonal Behavior Script ISA
-- primitives: INTERACT (doors, curtains, TVs, lights, windows), EQUIP, POSTURE,
-- EMOTE, ENGAGE, USE_ITEM, GIVE, and DROP.
-- Strictly enforces colonist-only server authority via BehaviorScriptCompiler.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.Semantics.ActionPlanProviders = PNC.Semantics.ActionPlanProviders or {}

local Compiler = PNC.ConvoEngine and PNC.ConvoEngine.BehaviorScriptCompiler
    or require "PNC/ConvoEngine/BehaviorScriptCompiler"
local PickupProvider = PNC.Semantics.ActionPlanProviders.Pickup
    or require "PNC/Semantics/ActionPlanProviders/PNC_SemanticActionPlanPickupProvider"

local Provider = PNC.Semantics.ActionPlanProviders.Actions or {}
PNC.Semantics.ActionPlanProviders.Actions = Provider

Provider.VERSION = 1
Provider.MAX_INTERACT_PER_STEP = 8

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

local function objectMatchesTarget(obj, targetText)
    if not obj then return false end
    local t = lower(targetText)
    if t == "" then return true end
    local candidates = {
        call(obj, "getObjectName"),
        call(obj, "getName"),
        call(obj, "getSpriteName"),
    }
    for i = 1, #candidates do
        if candidates[i] and string.find(lower(candidates[i]), t, 1, true) then
            return true
        end
    end
    return false
end

local function applyObjectOp(obj, body, op)
    if not obj then return false end
    -- Doors / Curtains / Windows
    if op == "close" or op == "open" or op == "toggle" then
        local isOpen = call(obj, "IsOpen")
        if isOpen ~= nil then
            if (op == "close" and isOpen == false) or (op == "open" and isOpen == true) then
                return false -- already in desired state
            end
            if type(obj.ToggleDoor) == "function" then
                return pcall(obj.ToggleDoor, obj, body) == true
            elseif type(obj.ToggleWindow) == "function" then
                return pcall(obj.ToggleWindow, obj, body) == true
            end
        end
    end
    -- Locks
    if op == "lock" or op == "unlock" then
        if type(obj.setLockedByKey) == "function" then
            return pcall(obj.setLockedByKey, obj, op == "lock") == true
        end
    end
    -- Light switches / TVs / Radios / Appliances
    if op == "turn_off" or op == "turn_on" or op == "toggle" then
        local wantOn = (op == "turn_on")
        if type(obj.setActive) == "function" then
            if op == "toggle" then wantOn = not (call(obj, "isActivated") == true) end
            return pcall(obj.setActive, obj, wantOn) == true
        end
        local dd = call(obj, "getDeviceData")
        if dd and type(dd.setIsTurnedOn) == "function" then
            if op == "toggle" then wantOn = not (call(dd, "getIsTurnedOn") == true) end
            return pcall(dd.setIsTurnedOn, dd, wantOn) == true
        end
    end
    return false
end

-- INTERACT primitive: opens/closes doors & curtains, toggles TVs/lights, locks.
function Provider.ExecuteInteract(record, body, step, context)
    context = type(context) == "table" and context or {}
    local allowed, authReason = Compiler.CanExecuteScript(record, context.player)
    if not allowed then return false, authReason, 0 end

    local op = tostring(step.op or "toggle")
    if context.targetObject then
        local ok = applyObjectOp(context.targetObject, body, op)
        return ok, ok and "interacted" or "interact_no_change", ok and 1 or 0
    end

    local cell = context.cell or (type(getCell) == "function" and getCell()) or nil
    if not cell or type(cell.getGridSquare) ~= "function" then
        return false, "world_cell_unavailable", 0
    end
    local ax = math.floor(tonumber(call(body, "getX") or record.x) or 0)
    local ay = math.floor(tonumber(call(body, "getY") or record.y) or 0)
    local az = math.floor(tonumber(call(body, "getZ") or record.z) or 0)
    local actorRoom = call(cell:getGridSquare(ax, ay, az), "getRoom")
    local radius = math.max(1, math.min(12, tonumber(step.radius) or 8))
    local targetText = step.target and step.target.text or ""
    local acted = 0

    for dx = -radius, radius do
        for dy = -radius, radius do
            if acted >= Provider.MAX_INTERACT_PER_STEP then break end
            local sq = cell:getGridSquare(ax + dx, ay + dy, az)
            if sq then
                local roomOk = true
                if step.areaScope and step.areaScope.kind == "room" and actorRoom then
                    roomOk = (call(sq, "getRoom") == actorRoom)
                end
                if roomOk then
                    local objs = call(sq, "getObjects")
                    for i = 0, listSize(objs) - 1 do
                        if acted >= Provider.MAX_INTERACT_PER_STEP then break end
                        local obj = listItem(objs, i)
                        if objectMatchesTarget(obj, targetText) and applyObjectOp(obj, body, op) then
                            acted = acted + 1
                        end
                    end
                end
            end
        end
        if acted >= Provider.MAX_INTERACT_PER_STEP then break end
    end
    if acted == 0 then return false, "no_matching_interactable", 0 end
    return true, "interacted", acted
end

-- EQUIP primitive: equips/holsters a matching item from NPC inventory.
function Provider.ExecuteEquip(record, body, step, context)
    context = type(context) == "table" and context or {}
    local allowed, authReason = Compiler.CanExecuteScript(record, context.player)
    if not allowed then return false, authReason end

    if step.unequip == true then
        if type(body and body.setPrimaryHandItem) == "function" then
            pcall(body.setPrimaryHandItem, body, nil)
        end
        return true, "unequipped"
    end
    local bodyInv = call(body, "getInventory")
    local items = call(bodyInv, "getItems")
    if not items then return false, "inventory_unavailable" end
    local filter = step.filter or "weapon"
    for i = 0, listSize(items) - 1 do
        local item = listItem(items, i)
        if item and PickupProvider.ItemMatchesFilter(item, filter) then
            if type(body.setPrimaryHandItem) == "function" then
                pcall(body.setPrimaryHandItem, body, item)
                return true, "equipped", item
            end
        end
    end
    return false, "equip_item_not_found"
end

-- POSTURE primitive: sit / stand / sneak / sleep (reuses MirrorSit & Stealth).
function Provider.ExecutePosture(record, body, step, context)
    context = type(context) == "table" and context or {}
    local allowed, authReason = Compiler.CanExecuteScript(record, context.player)
    if not allowed then return false, authReason end

    local pose = lower(step.pose or "sit")
    local now = PNC.Core and type(PNC.Core.Now) == "function" and PNC.Core.Now() or 0
    record.runtime = record.runtime or {}
    local mirrorSit = PNC.BehaviorCompanion and PNC.BehaviorCompanion.Internal
        and PNC.BehaviorCompanion.Internal.MirrorSit or nil

    if pose == "sit" then
        record.runtime.companionBreakSitUntil = now + 60000
        if mirrorSit and type(mirrorSit.TryStart) == "function" then
            mirrorSit.TryStart(record, body, nil, 0, nil, nil, false, nil, now)
        end
        return true, "sitting"
    elseif pose == "stand" then
        record.runtime.companionBreakSitUntil = nil
        if mirrorSit and type(mirrorSit.Stop) == "function" then
            mirrorSit.Stop(record, body, "script_stand")
        end
        record.runtime.stealthActive = false
        return true, "standing"
    elseif pose == "sneak" then
        record.runtime.stealthActive = true
        return true, "sneaking"
    elseif pose == "sleep" then
        record.runtime.scriptSleepRequestedAt = now
        return true, "sleep_requested"
    end
    return false, "unsupported_posture"
end

-- ENGAGE primitive: hold_fire vs attack/weapons_free.
function Provider.ExecuteEngage(record, body, step, context)
    context = type(context) == "table" and context or {}
    local allowed, authReason = Compiler.CanExecuteScript(record, context.player)
    if not allowed then return false, authReason end

    local mode = lower(step.mode or "hold_fire")
    record.runtime = record.runtime or {}
    if mode == "hold_fire" then
        record.runtime.holdFire = true
        record.runtime.target = nil
        record.runtime.combatTarget = nil
        return true, "holding_fire"
    end
    record.runtime.holdFire = false
    return true, "weapons_free"
end

-- EMOTE primitive: plays a social emote (dance, wave, salute, clap, cheer).
function Provider.ExecuteEmote(record, body, step, context)
    context = type(context) == "table" and context or {}
    local allowed, authReason = Compiler.CanExecuteScript(record, context.player)
    if not allowed then return false, authReason end

    local emote = lower(step.emote or "dance")
    record.runtime = record.runtime or {}
    record.runtime.scriptEmote = {
        name = emote,
        startedAt = PNC.Core and type(PNC.Core.Now) == "function" and PNC.Core.Now() or 0,
    }
    if body and PNC.Animation and type(PNC.Animation.PlayBump) == "function" then
        pcall(PNC.Animation.PlayBump, body, record, emote)
    end
    return true, "emoting:" .. emote
end

-- DROP primitive: drops matching items from NPC inventory onto current square.
function Provider.ExecuteDrop(record, body, step, context)
    context = type(context) == "table" and context or {}
    local allowed, authReason = Compiler.CanExecuteScript(record, context.player)
    if not allowed then return false, authReason, 0 end

    local bodyInv = call(body, "getInventory")
    local items = call(bodyInv, "getItems")
    local sq = context.square or call(body, "getSquare")
    if not items or not sq then return false, "drop_unavailable", 0 end

    local filter = step.filter or "all"
    local dropped = 0
    for i = listSize(items) - 1, 0, -1 do
        if dropped >= 12 then break end
        local item = listItem(items, i)
        if item and PickupProvider.ItemMatchesFilter(item, filter) then
            if type(sq.AddWorldInventoryItem) == "function" then
                pcall(sq.AddWorldInventoryItem, sq, item, 0.5, 0.5, 0)
            end
            call(bodyInv, "Remove", item)
            dropped = dropped + 1
        end
    end
    if dropped == 0 then return false, "no_matching_items_to_drop", 0 end
    return true, "dropped", dropped
end

-- GIVE primitive: transfers matching item(s) from NPC inventory to recipient inventory.
function Provider.ExecuteGive(record, body, step, context)
    context = type(context) == "table" and context or {}
    local allowed, authReason = Compiler.CanExecuteScript(record, context.player)
    if not allowed then return false, authReason, 0 end

    local bodyInv = call(body, "getInventory")
    local items = call(bodyInv, "getItems")
    local targetBody = context.recipientBody or context.player
    local targetInv = call(targetBody, "getInventory")
    if not items or not targetInv then return false, "give_unavailable", 0 end

    local filter = step.filter or "all"
    local maxCount = (step.quantity == "all") and 12 or 1
    local given = 0
    for i = listSize(items) - 1, 0, -1 do
        if given >= maxCount then break end
        local item = listItem(items, i)
        if item and PickupProvider.ItemMatchesFilter(item, filter) then
            if pcall(targetInv.AddItem, targetInv, item) then
                call(bodyInv, "Remove", item)
                given = given + 1
            end
        end
    end
    if given == 0 then return false, "no_matching_items_to_give", 0 end
    return true, "given", given
end

local Service = PNC.Semantics and PNC.Semantics.ActionPlanService or nil
if Service and type(Service.RegisterProvider) == "function" then
    Service.RegisterProvider("INTERACT", Provider)
    Service.RegisterProvider("EQUIP", Provider)
    Service.RegisterProvider("POSTURE", Provider)
    Service.RegisterProvider("ENGAGE", Provider)
    Service.RegisterProvider("EMOTE", Provider)
    Service.RegisterProvider("DROP", Provider)
    Service.RegisterProvider("GIVE", Provider)
end

return Provider
