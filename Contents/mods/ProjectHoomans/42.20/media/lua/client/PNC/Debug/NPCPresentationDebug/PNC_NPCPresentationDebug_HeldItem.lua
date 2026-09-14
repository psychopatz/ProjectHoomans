--[[
    Project Hoomans NPC presentation-debug held-item controller.

    This is deliberately independent from AnimationDebugPlayer. An animation
    preview may be replaced, stopped, or held while this controller keeps one
    temporary presentation item in the selected NPC's hand.
]]

PNC = PNC or {}
PNC.NPCPresentationHeldItem = PNC.NPCPresentationHeldItem or {}

local Controller = PNC.NPCPresentationHeldItem

if require then
    require "PNC/ActionProps/PNC_ClientActionProps"
    require "PNC/Core/Equipment/PNC_Equipment_Items"
    require "PNC/Core/Equipment/PNC_Equipment/PNC_Equipment_Hands"
end

local DEFAULT_ITEM = "Base.DoubleBarrelShotgun"
local MODES = { "auto", "action_prop", "equipment" }
local HANDS = { "auto", "primary", "secondary", "both" }
local ClientActionProps = PNC.ClientActionProps

Controller.requestedType = Controller.requestedType
    or DEFAULT_ITEM
Controller.requestedMode = Controller.requestedMode or "auto"
Controller.requestedHand = Controller.requestedHand or "auto"
Controller.active = Controller.active
Controller.lastResult = Controller.lastResult
Controller.target = Controller.target

local function readMethod(target, methodName, ...)
    local method
    if not target then return nil end
    method = target[methodName]
    if type(method) ~= "function" then return nil end
    local ok, value = pcall(method, target, ...)
    return ok and value or nil
end

local function itemFullType(item)
    local value = readMethod(item, "getFullType")
    if value == nil and item then value = item.fullType end
    return value and tostring(value) or nil
end

local function bodyID(body)
    local modData = readMethod(body, "getModData")
    return modData and modData.PNC_UUID and tostring(modData.PNC_UUID) or nil
end

local function resolvedID(body, id)
    local value = id ~= nil and tostring(id) or ""
    return value ~= "" and value or bodyID(body)
end

local function setVariable(body, name, value)
    if body and type(body.setVariable) == "function" then
        pcall(body.setVariable, body, name, tostring(value or ""))
    end
end

local function saveVariable(body, variables, name)
    if not body or type(body.getVariableString) ~= "function" then return end
    variables[name] = readMethod(body, "getVariableString", name)
end

local function primaryTypeFor(item)
    local equipment = PNC.Equipment
    local internal = equipment and equipment.Internal or nil
    local resolved
    local lowerType = string.lower(itemFullType(item) or "")
    if internal and type(internal.resolvePrimaryType) == "function" then
        resolved = readMethod(internal, "resolvePrimaryType", item)
        if resolved and resolved ~= "barehand" then return tostring(resolved) end
    end
    if string.find(lowerType, "pistol", 1, true)
        or string.find(lowerType, "revolver", 1, true)
    then
        return "handgun"
    end
    if readMethod(item, "isRanged") == true
        or string.find(lowerType, "shotgun", 1, true)
        or string.find(lowerType, "rifle", 1, true)
    then
        return "rifle"
    end
    -- Non-weapons such as Base.Apple do not have a WeaponType. onehanded is
    -- the useful debug presentation selector, so the item is still visible
    -- in a hand instead of being routed to barehand animation branches.
    return "onehanded"
end

local function resolveMode(item, requestedMode)
    return ClientActionProps.ResolveDebugMode(item, requestedMode)
end

local function currentAction(body)
    return ClientActionProps.CurrentAction(body)
end

local function staticModel(item)
    return tostring(readMethod(item, "getStaticModel") or "")
end

local function startActionProp(active, item)
    local descriptor = ClientActionProps.BuildDebugDescriptor(
        item,
        Controller.GetRequestedHand()
    )
    local ok
    local reason
    local state
    if not descriptor then return false, "action_prop_descriptor_missing" end
    ok, reason, state = ClientActionProps.Attach(
        active.body,
        descriptor,
        active
    )
    if not ok then return false, reason end
    active.actionDescriptor = descriptor
    active.actionState = state
    active.actionHost = state.host
    active.javaAction = state.javaAction
    active.actionHand = state.hand
    return true, "temporary_action_prop"
end

local function stopActionProp(active)
    if not active then return true end
    ClientActionProps.Detach(active.body, active)
    active.actionHost = nil
    active.javaAction = nil
    return true
end

local function createItem(fullType)
    local equipment = PNC.Equipment
    if equipment and type(equipment.CreateItem) == "function" then
        return equipment.CreateItem(fullType)
    end
    return nil, "equipment_item_factory_unavailable"
end

local function handMatches(body, methodName, expected)
    local actual = readMethod(body, methodName)
    return actual == expected
end

local function restore(active)
    local body = active and active.body or nil
    if not body then return false end
    if type(body.setPrimaryHandItem) == "function" then
        pcall(body.setPrimaryHandItem, body, active.primary)
    end
    if type(body.setSecondaryHandItem) == "function" then
        pcall(body.setSecondaryHandItem, body, active.secondary)
    end
    for name, value in pairs(active.variables or {}) do
        if value ~= nil then
            setVariable(body, name, value)
        elseif type(body.clearVariable) == "function" then
            pcall(body.clearVariable, body, name)
        end
    end
    if type(body.resetEquippedHandsModels) == "function" then
        pcall(body.resetEquippedHandsModels, body)
    end
    return true
end

local function apply(active, item)
    local body = active.body
    local primaryType = primaryTypeFor(item)
    local requiresBoth = readMethod(item, "isRequiresEquippedBothHands") == true
    local ok
    if not body or type(body.setPrimaryHandItem) ~= "function" then
        return false, "hand_setter_unavailable"
    end
    ok = pcall(body.setPrimaryHandItem, body, item)
    if not ok or (type(body.getPrimaryHandItem) == "function"
        and not handMatches(body, "getPrimaryHandItem", item))
    then
        return false, "temporary_primary_equip_failed"
    end
    if type(body.setSecondaryHandItem) == "function" then
        if requiresBoth then
            pcall(body.setSecondaryHandItem, body, item)
        else
            pcall(body.setSecondaryHandItem, body, nil)
        end
    end
    setVariable(body, "PNCPrimary", itemFullType(item))
    setVariable(body, "PNCSecondary", requiresBoth and itemFullType(item) or "")
    setVariable(body, "PNCPrimaryType", primaryType)
    if type(body.resetEquippedHandsModels) == "function" then
        pcall(body.resetEquippedHandsModels, body)
    end
    active.item = item
    active.fullType = itemFullType(item)
    active.primaryType = primaryType
    active.requiresBoth = requiresBoth
    return true, "temporary_item_equipped"
end

function Controller.DefaultItem()
    return DEFAULT_ITEM
end

function Controller.SetRequestedType(fullType)
    local value = tostring(fullType or "")
    Controller.requestedType = value ~= "" and value or DEFAULT_ITEM
    return Controller.requestedType
end

function Controller.GetRequestedType()
    return Controller.requestedType or DEFAULT_ITEM
end

function Controller.SetMode(mode)
    mode = tostring(mode or "auto")
    for _, value in ipairs(MODES) do
        if value == mode then
            Controller.requestedMode = value
            return value
        end
    end
    Controller.requestedMode = "auto"
    return Controller.requestedMode
end

function Controller.GetRequestedMode()
    return Controller.requestedMode or "auto"
end

function Controller.CycleMode()
    local current = Controller.GetRequestedMode()
    for index, value in ipairs(MODES) do
        if value == current then
            return Controller.SetMode(
                MODES[index % #MODES + 1]
            )
        end
    end
    return Controller.SetMode("auto")
end

function Controller.SetHand(hand)
    hand = tostring(hand or "auto")
    for _, value in ipairs(HANDS) do
        if value == hand then
            Controller.requestedHand = value
            return value
        end
    end
    Controller.requestedHand = "auto"
    return Controller.requestedHand
end

function Controller.GetRequestedHand()
    return Controller.requestedHand or "auto"
end

function Controller.CycleHand()
    local current = Controller.GetRequestedHand()
    for index, value in ipairs(HANDS) do
        if value == current then
            return Controller.SetHand(
                HANDS[index % #HANDS + 1]
            )
        end
    end
    return Controller.SetHand("auto")
end

function Controller.SetTarget(body, id, playerIndex)
    local nextID = resolvedID(body, id)
    local target = Controller.target
    if target and (target.body ~= body or target.id ~= nextID) then
        Controller.Disable("target_changed")
    end
    Controller.target = body and {
        body = body,
        id = nextID,
        playerIndex = tonumber(playerIndex) or 0,
    } or nil
    return Controller.target ~= nil
end

function Controller.Enable(body, id, playerIndex, fullType)
    local item
    local reason
    local active
    local mode
    local ok
    local applyReason
    if not body then return false, "body_missing" end
    Controller.SetRequestedType(fullType or Controller.GetRequestedType())
    if Controller.active then Controller.Disable("replaced") end
    item, reason = createItem(Controller.GetRequestedType())
    if not item then
        Controller.lastResult = {
            ok = false,
            reason = tostring(reason or "item_create_failed"),
            fullType = Controller.GetRequestedType(),
        }
        return false, Controller.lastResult.reason
    end
    mode = resolveMode(item, Controller.GetRequestedMode())
    active = {
        body = body,
        id = resolvedID(body, id),
        playerIndex = tonumber(playerIndex) or 0,
        mode = mode,
        primary = readMethod(body, "getPrimaryHandItem"),
        secondary = readMethod(body, "getSecondaryHandItem"),
        variables = {},
    }
    for _, name in ipairs({ "PNCPrimary", "PNCSecondary", "PNCPrimaryType" }) do
        saveVariable(body, active.variables, name)
    end
    if mode == "action_prop" then
        Controller.active = active
        ok, applyReason = startActionProp(active, item)
    else
        ok, applyReason = apply(active, item)
    end
    if not ok then
        if mode == "action_prop" then
            stopActionProp(active)
            Controller.active = nil
        else
            restore(active)
        end
        Controller.lastResult = { ok = false, reason = applyReason }
        return false, applyReason
    end
    active.item = item
    active.fullType = itemFullType(item)
    if mode == "action_prop" then
        active.primaryType = "action_prop"
        active.requiresBoth = active.actionHand == "both"
    else
        Controller.active = active
    end
    Controller.target = {
        body = body,
        id = active.id,
        playerIndex = active.playerIndex,
    }
    Controller.lastResult = {
        ok = true,
        reason = applyReason,
        fullType = active.fullType,
        primaryType = active.primaryType,
        mode = active.mode,
        hand = active.actionHand,
    }
    return true, applyReason
end

function Controller.Disable(reason)
    local active = Controller.active
    if not active then return false, "not_active" end
    if active.mode == "action_prop" then
        stopActionProp(active)
    else
        restore(active)
    end
    Controller.lastResult = {
        ok = true,
        reason = tostring(reason or "restored"),
        fullType = active.fullType,
        mode = active.mode,
    }
    Controller.active = nil
    return false, Controller.lastResult.reason
end

function Controller.Toggle(body, id, playerIndex, fullType)
    local active = Controller.active
    local nextID = resolvedID(body, id)
    if active and active.body == body and active.id == nextID then
        return Controller.Disable("toggle_off")
    end
    return Controller.Enable(body, id, playerIndex, fullType)
end

function Controller.Reapply()
    local active = Controller.active
    if not active then return false, "not_active" end
    if active.mode == "action_prop" then
        local body = active.body
        local id = active.id
        local playerIndex = active.playerIndex
        Controller.Disable("reapply")
        return Controller.Enable(body, id, playerIndex,
            Controller.GetRequestedType())
    end
    local item, reason = createItem(Controller.GetRequestedType())
    if not item then return false, reason end
    restore(active)
    active.primary = readMethod(active.body, "getPrimaryHandItem")
    active.secondary = readMethod(active.body, "getSecondaryHandItem")
    return apply(active, item)
end

function Controller.Maintain(body, id)
    local active = Controller.active
    local nextID = resolvedID(body, id)
    if not active then return false end
    if active.body ~= body or active.id ~= nextID then
        Controller.Disable("target_lost")
        return false
    end
    if active.mode == "action_prop" then
        if currentAction(body) ~= active.javaAction then
            Controller.Disable("action_owner_lost")
            return false
        end
        return true
    end
    if readMethod(body, "getPrimaryHandItem") ~= active.item then
        apply(active, active.item)
    end
    return true
end

function Controller.IsActive(body, id)
    local active = Controller.active
    if not active then return false end
    if not body and id == nil then return true end
    return active.body == body and active.id == resolvedID(body, id)
end

function Controller.GetState(body, id)
    local active = Controller.active
    local action = active and active.javaAction or nil
    local persistentPrimary = body
        and itemFullType(readMethod(body, "getPrimaryHandItem"))
        or nil
    local persistentSecondary = body
        and itemFullType(readMethod(body, "getSecondaryHandItem"))
        or nil
    local state = {
        enabled = false,
        requestedType = Controller.GetRequestedType(),
        requestedMode = Controller.GetRequestedMode(),
        requestedHand = Controller.GetRequestedHand(),
        status = "OFF",
        lastResult = Controller.lastResult,
        persistentPrimary = persistentPrimary,
        persistentSecondary = persistentSecondary,
    }
    if active then
        state.enabled = (not body and id == nil)
            or (active.body == body and active.id == resolvedID(body, id))
        state.status = state.enabled and "ON" or "OTHER TARGET"
        state.mode = active.mode
        state.fullType = active.fullType
        state.primaryType = active.primaryType
        state.actionHand = active.actionHand
        state.id = active.id
        state.actionClass = action
            and tostring(readMethod(action, "getMetaType") or "")
            or nil
        -- The controller only reports this while its own action is still the
        -- character's current action. BaseAction clears the override before
        -- the action is removed, so this avoids indexing Java fields from UI.
        state.actionOverride = active.mode == "action_prop"
            and action ~= nil
            and currentAction(active.body) == action
            or false
        state.actionPrimary = action
            and itemFullType(readMethod(action, "getPrimaryHandItem"))
            or nil
        state.actionSecondary = action
            and itemFullType(readMethod(action, "getSecondaryHandItem"))
            or nil
        state.staticModel = active.item
            and staticModel(active.item)
            or nil
    end
    return state
end

function Controller.Reset()
    Controller.Disable("lua_reset")
    Controller.active = nil
    Controller.target = nil
end

if Events and Events.OnResetLua then
    Events.OnResetLua.Add(Controller.Reset)
end

return Controller
