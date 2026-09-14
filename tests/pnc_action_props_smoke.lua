local T = require "tests/support/test"

local actionPropsFile = T.path(
    "ProjectHoomans", "shared", "PNC/Core/Visuals/PNC_ActionProps.lua")
local clientActionPropsFile = T.path(
    "ProjectHoomans", "client", "PNC/ActionProps/PNC_ClientActionProps.lua")
local bodyPresentationFile = T.path(
    "ProjectHoomans", "client",
    "PNC/PresenceSync/PresenceVisuals/PNC_ClientPresenceVisuals_BodyPresentation.lua")

local created = {}
local primary = { fullType = "Base.Knife" }
local secondary = { fullType = "Base.Bandage" }
local current = nil
local resetCount = 0

PNC = {
    Equipment = {
        CreateItem = function(fullType)
            if fullType == "Base.Invalid" then
                return nil, "invalid_full_type"
            end
            local item = {
                fullType = fullType,
                requiresBoth = fullType == "Base.HandAxe",
            }
            function item:getFullType() return self.fullType end
            function item:getEatType()
                if self.fullType == "Base.Apple" then return "Food" end
                if self.fullType == "Base.Pot" then return "Pot" end
                return nil
            end
            function item:isRequiresEquippedBothHands()
                return self.requiresBoth
            end
            created[#created + 1] = item
            return item, "test_item"
        end,
        Internal = {},
    },
}
Events = nil
require = nil

T.load(actionPropsFile)

local function newJavaAction(owner)
    local action = {
        owner = owner,
        primary = nil,
        secondary = nil,
        overrideHandModels = false,
    }
    function action:setCustomRemoteTimedActionSync(value)
        self.customRemote = value
    end
    function action:setOverrideHandModelsObject(primaryItem, secondaryItem)
        self.primary = primaryItem
        self.secondary = secondaryItem
        self.overrideHandModels = true
        if owner.character.resetEquippedHandsModels then
            owner.character:resetEquippedHandsModels()
        end
    end
    function action:getPrimaryHandItem() return self.primary end
    function action:getSecondaryHandItem() return self.secondary end
    function action:getMetaType() return "PNCActionPropHostAction" end
    function action:stopTimedActionAnim()
        self.stopTimedActionAnimCalled = true
        self.overrideHandModels = false
    end
    function action:forceStop() self.forceStopped = true end
    return action
end

ISBaseTimedAction = {
    derive = function(base, name)
        local class = { Type = name }
        setmetatable(class, { __index = base })
        return class
    end,
    new = function(self, character)
        local object = { character = character, maxTime = -1 }
        setmetatable(object, self)
        self.__index = self
        return object
    end,
    create = function(self)
        self.action = newJavaAction(self)
    end,
}

T.load(clientActionPropsFile)

local body = {
    variables = {},
    modData = {},
}
function body:getCharacterActions()
    return {
        isEmpty = function() return current == nil end,
        get = function(_, index) return index == 0 and current or nil end,
        removeElement = function(_, action)
            if current == action then current = nil end
        end,
    }
end
function body:StartAction(action) current = action end
function body:resetEquippedHandsModels() resetCount = resetCount + 1 end
function body:getPrimaryHandItem() return primary end
function body:getSecondaryHandItem() return secondary end
function body:setPrimaryHandItem(item) primary = item end
function body:setSecondaryHandItem(item) secondary = item end

local food = PNC.ActionProps.Resolve({
    actionInformation = {
        capability = "food.dine",
        activityItemID = "food-1",
        activityItemFullType = "Base.Apple",
    },
    visualState = {
        sceneId = "survival.eat.inventory",
        sceneStartedAt = 10,
    },
})
T.equal(food.source, "food", "food action-prop source")
T.equal(food.primaryFullType, nil, "food does not force primary")
T.equal(food.secondaryFullType, "Base.Apple",
    "food follows vanilla secondary action hand")
T.equal(food.secondaryItemID, "food-1", "food item identity is retained")

local ok, reason, state = PNC.ClientActionProps.Attach(body, food)
T.truthy(ok, reason)
T.equal(primary.fullType, "Base.Knife",
    "action prop does not mutate persistent primary")
T.equal(secondary.fullType, "Base.Bandage",
    "action prop does not mutate persistent secondary")
T.equal(state.hand, "secondary", "food host reports secondary hand")
T.equal(state.javaAction:getPrimaryHandItem(), nil,
    "food host primary override is empty")
T.equal(state.javaAction:getSecondaryHandItem().fullType, "Base.Apple",
    "food host secondary override contains the food")
T.truthy(state.javaAction.overrideHandModels,
    "engine action override is enabled")
T.truthy(state.javaAction.customRemote,
    "host action is excluded from remote timed-action sync")

local createdCount = #created
ok, reason, state = PNC.ClientActionProps.Attach(body, food)
T.truthy(ok, reason)
T.equal(#created, createdCount, "unchanged descriptor is latched")

local drink = PNC.ActionProps.Resolve({
    actionInformation = {
        capability = "survival.drink.inventory",
        activityItemFullType = "Base.WaterBottle",
    },
    visualState = { sceneId = "survival.drink.inventory" },
})
T.equal(drink.secondaryFullType, "Base.WaterBottle",
    "drink uses the secondary action hand")

ok, reason = PNC.ClientActionProps.Attach(body, drink)
T.truthy(ok, reason)
T.equal(primary.fullType, "Base.Knife",
    "changing action props still preserves persistent primary")
T.equal(current:getSecondaryHandItem().fullType, "Base.WaterBottle",
    "drink replaces only the owned action override")

local pot = PNC.ActionProps.Resolve({
    actionInformation = {
        capability = "food.dine",
        activityItemFullType = "Base.Pot",
    },
    visualState = { sceneId = "survival.eat.inventory" },
})
ok, reason, state = PNC.ClientActionProps.Attach(body, pot)
T.truthy(ok, reason)
T.equal(state.hand, "primary", "pot hand is resolved from the item rule")
T.equal(state.javaAction:getPrimaryHandItem().fullType, "Base.Pot",
    "pot follows vanilla primary-hand special case")
T.equal(state.javaAction:getSecondaryHandItem(), nil,
    "pot clears the secondary action hand")

local lumber = PNC.ActionProps.Resolve({
    actionInformation = {
        operation = "LUMBER",
        activityItemFullType = "Base.HandAxe",
    },
    visualState = { sceneId = "lumber.chop", sceneStartedAt = 20 },
})
T.equal(lumber.primaryFullType, "Base.HandAxe",
    "lumber tool uses the primary action hand")
T.equal(lumber.secondaryFullType, nil,
    "single-handed lumber tool does not invent a second item")
ok, reason, state = PNC.ClientActionProps.Attach(body, lumber)
T.truthy(ok, reason)
T.equal(state.javaAction:getPrimaryHandItem().fullType, "Base.HandAxe",
    "lumber tool reaches the action primary hand")
T.equal(state.javaAction:getSecondaryHandItem().fullType, "Base.HandAxe",
    "two-handed item metadata fills the secondary action hand")

local workInput = PNC.ActionProps.Resolve({
    actionInformation = {
        operation = "CRAFT",
        capability = "farm.work",
        activityItemFullType = "Base.Plank",
    },
    visualState = { sceneId = "production.craft" },
})
T.equal(workInput, nil,
    "unverified work inputs are not mistaken for held action props")

local medical = PNC.ActionProps.Resolve({
    actionInformation = { kind = "treatment", phase = "bandaging",
        activityItemFullType = "Base.Bandage" },
    treatmentState = { phase = "bandaging" },
})
T.equal(medical, nil, "bandaging keeps vanilla empty action hands")

local detachedJavaAction = current
ok, reason = PNC.ClientActionProps.Detach(body)
T.truthy(ok, reason)
T.equal(primary.fullType, "Base.Knife",
    "detaching action props leaves native equipment untouched")
T.equal(secondary.fullType, "Base.Bandage",
    "detaching action props restores the underlying secondary")
T.equal(current, nil, "owned host action is removed")
T.truthy(resetCount > 0, "detaching refreshes hand models")
T.truthy(detachedJavaAction.stopTimedActionAnimCalled,
    "detaching uses NPC-safe action animation teardown")

current = {}
ok, reason = PNC.ClientActionProps.Attach(body, food)
T.falsy(ok, "an unrelated action is not replaced")
T.equal(reason, "npc_busy_action", "busy action is reported")
T.equal(current.owner, nil, "unrelated action remains current")
current = nil

PNC.ClientPresenceSync = { Internal = {} }
PNC.Const = { PRESENCE_LIVE = "live" }
PNC.Animation = {}
PNC.Visuals = {}
PNC.AnimationTrace = {}
PNC.NPCVoice = {}
T.load(bodyPresentationFile)
local resolve = PNC.ClientPresenceSync.Internal.ResolveActionProps
local resolved = resolve({
    actionInformation = {
        capability = "survival.drink.inventory",
        activityItemID = "bottle-1",
        activityItemFullType = "Base.WaterBottle",
    },
    visualState = { sceneId = "survival.drink.inventory" },
})
T.equal(resolved.secondaryFullType, "Base.WaterBottle",
    "body presentation uses the shared action-prop resolver")

T.finish("pnc_action_props_smoke")
