--[[
    Project Hoomans client action-prop host.

    The base game renders transient non-weapon items through the current
    BaseAction overrideHandModels path.  This module owns that one engine
    action per body.  It never writes native persistent hand slots and never
    puts a visual-only item into an inventory or ModData.
]]

PNC = PNC or {}
PNC.ActionProps = PNC.ActionProps or {}
PNC.ClientActionProps = PNC.ClientActionProps or {}

local ActionProps = PNC.ActionProps
local Client = PNC.ClientActionProps
local ActiveByBody = Client.ActiveByBody or {}
local LiveOwnerByBody = Client.LiveOwnerByBody or {}
Client.ActiveByBody = ActiveByBody
Client.LiveOwnerByBody = LiveOwnerByBody

if require then
    require "PNC/Core/Equipment/PNC_Equipment_Items"
end

local function itemFullType(item)
    if not item then return nil end
    if type(item.getFullType) == "function" then
        return tostring(item:getFullType() or "")
    end
    return item.fullType and tostring(item.fullType) or nil
end

local function readItem(item, methodName)
    if item and type(item[methodName]) == "function" then
        return item[methodName](item)
    end
    return nil
end

local function currentAction(body)
    local actions
    if not body or type(body.getCharacterActions) ~= "function" then
        return nil
    end
    actions = body:getCharacterActions()
    if not actions then return nil end
    if type(actions.isEmpty) == "function" and actions:isEmpty() then
        return nil
    end
    if type(actions.get) == "function" then
        return actions:get(0)
    end
    return nil
end

local function applyItemVisualState(item, visual)
    local equipment = PNC.Equipment
    local internal = equipment and equipment.Internal or nil
    if item and visual and internal
        and type(internal.applyItemVisualState) == "function"
    then
        internal.applyItemVisualState(item, visual)
    end
end

local function applyItemState(item, state)
    local maximum
    local condition
    if not item or type(state) ~= "table" then return end
    condition = tonumber(state.cond)
    maximum = type(item.getConditionMax) == "function"
        and tonumber(item:getConditionMax()) or 0
    if condition ~= nil and type(item.setCondition) == "function" then
        item:setCondition(math.max(0, math.min(
            maximum > 0 and maximum or condition,
            condition
        )))
    end
    if state.uses ~= nil and type(item.setUses) == "function" then
        item:setUses(math.max(0, tonumber(state.uses) or 0))
    end
end

local function createItem(fullType, visual, state)
    local equipment = PNC.Equipment
    local item
    local reason
    if not fullType or fullType == "" then return nil end
    if not equipment or type(equipment.CreateItem) ~= "function" then
        return nil, "equipment_item_factory_unavailable"
    end
    item, reason = equipment.CreateItem(fullType)
    if not item then return nil, reason or "action_prop_item_create_failed" end
    applyItemVisualState(item, visual)
    applyItemState(item, state)
    return item
end

local function createDescriptorItems(descriptor)
    local primaryType = descriptor and descriptor.primaryFullType or nil
    local secondaryType = descriptor and descriptor.secondaryFullType or nil
    local primary
    local secondary
    local reason
    if primaryType and secondaryType and primaryType == secondaryType then
        primary, reason = createItem(
            primaryType,
            descriptor.primaryVisual or descriptor.secondaryVisual,
            descriptor.primaryState or descriptor.secondaryState
        )
        if not primary then return nil, nil, reason end
        secondary = primary
    else
        if primaryType then
            primary, reason = createItem(
                primaryType,
                descriptor.primaryVisual,
                descriptor.primaryState
            )
            if not primary then return nil, nil, reason end
        end
        if secondaryType then
            secondary, reason = createItem(
                secondaryType,
                descriptor.secondaryVisual,
                descriptor.secondaryState
            )
            if not secondary then return nil, nil, reason end
        end
    end

    -- A descriptor normally specifies both slots for a known two-handed
    -- prop.  This fallback also covers real tools such as a chainsaw whose
    -- item script declares RequiresEquippedBothHands.
    if primary and not secondary
        and readItem(primary, "isRequiresEquippedBothHands") == true
    then
        secondary = primary
    end
    -- ISEatFoodAction and ISDrinkFluidAction special-case pots: the pot is
    -- held in primary and the secondary override is empty.  The shared
    -- snapshot only carries the full type, so resolve this script-level rule
    -- after the client creates the transient item.
    if not primary and secondary then
        local eatType = tostring(readItem(secondary, "getEatType") or "")
        if eatType == "Pot" or eatType == "PotForged" then
            primary = secondary
            secondary = nil
        end
    end
    return primary, secondary
end

local HostAction
if ISBaseTimedAction
    and type(ISBaseTimedAction.derive) == "function"
then
    HostAction = ISBaseTimedAction:derive("PNCActionPropHostAction")

    function HostAction:new(character, owner, primary, secondary)
        local object = ISBaseTimedAction.new(self, character)
        object.owner = owner
        object.primaryItem = primary
        object.secondaryItem = secondary
        object.maxTime = -1
        object.stopOnWalk = false
        object.stopOnRun = false
        object.stopOnAim = false
        object.useProgressBar = false
        return object
    end

    function HostAction:begin()
        self:create()
        if not self.action then
            self.beginFailure = "timed_action_create_failed"
            return
        end
        if type(self.action.setCustomRemoteTimedActionSync) == "function" then
            self.action:setCustomRemoteTimedActionSync(true)
        end
        if type(self.action.setOverrideHandModelsObject) ~= "function" then
            self.beginFailure = "hand_model_override_api_unavailable"
            return
        end
        self.action:setOverrideHandModelsObject(
            self.primaryItem,
            self.secondaryItem,
            true
        )
        self.character:StartAction(self.action)
    end

    function HostAction:isValidStart()
        return self.owner ~= nil and self.owner.actionPropActive == true
    end

    function HostAction:isValid()
        return self.owner ~= nil and self.owner.actionPropActive == true
    end

    function HostAction:waitToStart()
        -- Keep LuaTimedActionNew in its waiting state.  BaseAction.stop()
        -- contains an unconditional IsoPlayer cast in this game build, while
        -- NPC presentation bodies are IsoZombies.  A waiting action is safely
        -- cleared by the engine without entering that player-only stop path.
        return true
    end

    function HostAction:start()
    end

    function HostAction:stop()
    end

    function HostAction:perform()
    end

    function HostAction:complete()
    end
end

local function removeHostAction(body, javaAction)
    local actions
    if not body or not javaAction then return false end

    -- BaseAction.stop() calls UIManager with an unconditional IsoPlayer cast
    -- in this game build.  NPC replicas are IsoZombies, so use the safe part
    -- of the same teardown directly, then remove only our action from the
    -- character stack without invoking BaseAction.stop().
    if type(javaAction.stopTimedActionAnim) == "function" then
        javaAction:stopTimedActionAnim()
    elseif type(body.resetEquippedHandsModels) == "function" then
        body:resetEquippedHandsModels()
    end

    if type(body.getCharacterActions) ~= "function" then return false end
    actions = body:getCharacterActions()
    if not actions then return false end
    if type(actions.removeElement) == "function" then
        actions:removeElement(javaAction)
        return true
    end
    if type(actions.clear) == "function" then
        actions:clear()
        return true
    end
    return false
end

local function detachActive(body, active)
    if not active then return true, "action_prop_idle" end
    if body and active.javaAction then
        removeHostAction(body, active.javaAction)
    end
    if active.owner then active.owner.actionPropActive = false end
    if ActiveByBody[body] == active then
        ActiveByBody[body] = nil
    end
    return true, "action_prop_detached"
end

local function resolvedHand(primary, secondary)
    if primary and secondary then return "both" end
    if primary then return "primary" end
    if secondary then return "secondary" end
    return "none"
end

local function resolveOwner(body, owner)
    if owner ~= nil then return owner end
    if not LiveOwnerByBody[body] then
        LiveOwnerByBody[body] = {}
    end
    return LiveOwnerByBody[body]
end

function Client.CurrentAction(body)
    return currentAction(body)
end

function Client.Attach(body, descriptor, owner)
    local key
    local existing
    local primary
    local secondary
    local reason
    local host
    local active
    if not body then return false, "missing_body" end
    owner = resolveOwner(body, owner)
    if not descriptor then
        return Client.Detach(body, owner)
    end
    if not HostAction or type(HostAction.new) ~= "function" then
        return false, "timed_action_api_unavailable"
    end
    key = ActionProps.BuildKey(descriptor)
    existing = ActiveByBody[body]
    if existing
        and existing.owner == owner
        and existing.key == key
        and currentAction(body) == existing.javaAction
    then
        return true, "action_prop_current", existing
    end
    if existing and existing.owner ~= owner then
        return false, "action_prop_owned"
    end
    if existing then
        detachActive(body, existing)
    end
    if currentAction(body) ~= nil then
        return false, "npc_busy_action"
    end
    primary, secondary, reason = createDescriptorItems(descriptor)
    if not primary and not secondary then
        return false, reason or "action_prop_item_missing"
    end
    owner.actionPropActive = true
    host = HostAction:new(body, owner, primary, secondary)
    host:begin()
    if host.beginFailure then
        owner.actionPropActive = false
        return false, host.beginFailure
    end
    if currentAction(body) ~= host.action then
        owner.actionPropActive = false
        return false, "action_start_not_owned"
    end
    active = {
        body = body,
        owner = owner,
        descriptor = descriptor,
        key = key,
        host = host,
        javaAction = host.action,
        primaryItem = primary,
        secondaryItem = secondary,
        hand = resolvedHand(primary, secondary),
    }
    ActiveByBody[body] = active
    return true, "action_prop_attached", active
end

function Client.Detach(body, owner)
    local active = body and ActiveByBody[body] or nil
    if not active then return true, "action_prop_idle" end
    owner = resolveOwner(body, owner)
    if owner ~= nil and active.owner ~= owner then
        return false, "action_prop_not_owner"
    end
    return detachActive(body, active)
end

function Client.Maintain(body, owner)
    if not body then return false end
    local active = body and ActiveByBody[body] or nil
    owner = resolveOwner(body, owner)
    if not active or active.owner ~= owner then
        return false
    end
    if currentAction(body) ~= active.javaAction then
        detachActive(body, active)
        return false
    end
    return true
end

function Client.GetActive(body)
    return body and ActiveByBody[body] or nil
end

local function isWeaponLike(item)
    local subCategory
    if not item then return false end
    if type(item.IsWeapon) == "function" and item:IsWeapon() == true then
        return true
    end
    if readItem(item, "isRanged") == true then return true end
    subCategory = readItem(item, "getSubCategory")
    return tostring(subCategory or "") == "Firearm"
end

local function defaultsToSecondary(item)
    local fullType = string.lower(itemFullType(item) or "")
    local eatType = tostring(readItem(item, "getEatType") or "")
    if eatType == "Pot" or eatType == "PotForged" then
        return false
    end
    return eatType ~= ""
        or readItem(item, "getPillType") ~= nil
        or string.find(fullType, "pill", 1, true) ~= nil
        or string.find(fullType, "book", 1, true) ~= nil
        or string.find(fullType, "newspaper", 1, true) ~= nil
        or string.find(fullType, "map", 1, true) ~= nil
end

function Client.ResolveDebugMode(item, requestedMode)
    requestedMode = tostring(requestedMode or "auto")
    if requestedMode == "equipment" or requestedMode == "action_prop" then
        return requestedMode
    end
    return isWeaponLike(item) and "equipment" or "action_prop"
end

function Client.BuildDebugDescriptor(item, requestedHand)
    local fullType = itemFullType(item)
    local hand = tostring(requestedHand or "auto")
    local requiresBoth = readItem(item, "isRequiresEquippedBothHands") == true
    if not fullType or fullType == "" then return nil end
    if requiresBoth or hand == "both" then
        hand = "both"
    elseif hand ~= "primary" and hand ~= "secondary" then
        hand = defaultsToSecondary(item) and "secondary" or "primary"
    end
    return {
        source = "debug",
        primaryFullType = (hand == "primary" or hand == "both")
            and fullType or nil,
        secondaryFullType = (hand == "secondary" or hand == "both")
            and fullType or nil,
        hand = hand,
        revision = 0,
    }
end

function Client.Reset()
    local activeByBody = {}
    for body, active in pairs(ActiveByBody) do
        activeByBody[#activeByBody + 1] = { body = body, active = active }
    end
    for i = 1, #activeByBody do
        detachActive(activeByBody[i].body, activeByBody[i].active)
    end
    Client.ActiveByBody = {}
    ActiveByBody = Client.ActiveByBody
    Client.LiveOwnerByBody = {}
    LiveOwnerByBody = Client.LiveOwnerByBody
end

if Events and Events.OnResetLua then
    Events.OnResetLua.Add(Client.Reset)
end

return Client
