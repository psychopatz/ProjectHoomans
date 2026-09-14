local T = require "tests/support/test"

local FILE = T.path(
    "ProjectHoomans",
    "client",
    "PNC/Debug/NPCPresentationDebug/PNC_NPCPresentationDebug_HeldItem.lua"
)
local ACTION_PROPS = T.path(
    "ProjectHoomans", "shared", "PNC/Core/Visuals/PNC_ActionProps.lua")
local CLIENT_ACTION_PROPS = T.path(
    "ProjectHoomans", "client", "PNC/ActionProps/PNC_ClientActionProps.lua")

local primary = { id = "original_primary" }
local secondary = { id = "original_secondary" }
local variables = {
    PNCPrimary = "Base.Knife",
    PNCSecondary = "Base.Bandage",
    PNCPrimaryType = "onehanded",
}
local created = {}
local resetModels = 0

PNC = {
    Equipment = {
        CreateItem = function(fullType)
            if fullType ~= "Base.Apple"
                and fullType ~= "Base.DoubleBarrelShotgun"
            then
                return nil, "invalid_full_type"
            end
            local item = {
                fullType = fullType,
                requiresBoth = fullType == "Base.DoubleBarrelShotgun",
            }
            function item:getFullType() return self.fullType end
            function item:IsWeapon()
                return self.fullType == "Base.DoubleBarrelShotgun"
            end
            function item:getEatType()
                return self.fullType == "Base.Apple" and "Food" or nil
            end
            function item:isRequiresEquippedBothHands()
                return self.requiresBoth
            end
            created[#created + 1] = item
            return item, "test_item"
        end,
    },
}
Events = nil
require = nil

local currentAction = nil
local actionStack = {
    isEmpty = function() return currentAction == nil end,
    get = function(_, index)
        return index == 0 and currentAction or nil
    end,
    removeElement = function(_, action)
        if currentAction == action then currentAction = nil end
    end,
}

local function newJavaAction(owner)
    local action = {
        owner = owner,
        overrideHandModels = false,
        primary = nil,
        secondary = nil,
    }
    function action:setCustomRemoteTimedActionSync(value)
        self.customRemote = value
    end
    function action:setOverrideHandModelsObject(primaryItem, secondaryItem, reset)
        self.primary = primaryItem
        self.secondary = secondaryItem
        self.overrideHandModels = true
        if reset ~= false and owner.character.resetEquippedHandsModels then
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
        local object = {
            character = character,
            maxTime = -1,
        }
        setmetatable(object, self)
        self.__index = self
        return object
    end,
    create = function(self)
        self.action = newJavaAction(self)
    end,
}
function ISBaseTimedAction:adjustMaxTime(value) return value end

local body = {
    getModData = function() return { PNC_UUID = "held-npc" } end,
    getPrimaryHandItem = function() return primary end,
    getSecondaryHandItem = function() return secondary end,
    setPrimaryHandItem = function(_, item) primary = item end,
    setSecondaryHandItem = function(_, item) secondary = item end,
    getCharacterActions = function() return actionStack end,
    StartAction = function(_, action) currentAction = action end,
    getVariableString = function(_, name) return variables[name] or "" end,
    setVariable = function(_, name, value) variables[name] = value end,
    clearVariable = function(_, name) variables[name] = nil end,
    resetEquippedHandsModels = function() resetModels = resetModels + 1 end,
}

T.load(ACTION_PROPS)
T.load(CLIENT_ACTION_PROPS)
T.load(FILE)

local Holder = PNC.NPCPresentationHeldItem
T.equal(Holder.DefaultItem(), "Base.DoubleBarrelShotgun",
    "held-item debugger defaults to the Project Hoomans shotgun")
Holder.SetRequestedType("Base.Apple")
local ok, reason = Holder.Toggle(body, "held-npc", 0)
T.truthy(ok and reason == "temporary_action_prop",
    "arbitrary item action-prop toggle enabled: " .. tostring(reason))
T.equal(primary.id, "original_primary",
    "action-prop mode preserves persistent primary hand")
T.equal(secondary.id, "original_secondary",
    "action-prop mode preserves persistent secondary hand")
local actionState = Holder.GetState(body, "held-npc")
T.equal(actionState.mode, "action_prop", "non-weapon selected action-prop mode")
T.equal(actionState.actionPrimary, nil,
    "food prop follows vanilla secondary-hand placement")
T.equal(actionState.actionSecondary, "Base.Apple",
    "food prop was installed in the action secondary slot")
T.truthy(actionState.actionOverride,
    "engine hand-model override is active")
T.truthy(currentAction ~= nil, "debug action owns the character action slot")
T.truthy(Holder.IsActive(body, "held-npc"), "held-item target is active")
T.truthy(resetModels > 0, "action-prop model refresh was requested")

ok, reason = Holder.Toggle(body, "held-npc", 0)
T.falsy(ok, "second toggle disables held-item mode")
T.equal(variables.PNCPrimary, "Base.Knife",
    "action-prop mode leaves primary descriptor unchanged")
T.equal(variables.PNCSecondary, "Base.Bandage",
    "action-prop mode leaves secondary descriptor unchanged")
T.equal(variables.PNCPrimaryType, "onehanded",
    "action-prop mode leaves primary type unchanged")
T.equal(primary.id, "original_primary", "original primary item was restored")
T.equal(secondary.id, "original_secondary", "original secondary item was restored")
T.falsy(currentAction, "debug action was removed")
T.falsy(Holder.IsActive(body, "held-npc"), "held-item mode is inactive")

local unrelatedAction = {}
currentAction = unrelatedAction
Holder.SetRequestedType("Base.Apple")
ok, reason = Holder.Enable(body, "held-npc", 0)
T.falsy(ok, "action-prop mode does not replace an unrelated action")
T.equal(reason, "npc_busy_action", "busy action reason is explicit")
T.equal(currentAction, unrelatedAction, "unrelated action remains current")
currentAction = nil

Holder.SetHand("primary")
ok, reason = Holder.Enable(body, "held-npc", 0)
T.truthy(ok, "explicit primary action-prop placement enabled")
actionState = Holder.GetState(body, "held-npc")
T.equal(actionState.actionPrimary, "Base.Apple",
    "explicit primary placement reaches the action primary slot")
T.equal(actionState.actionSecondary, nil,
    "explicit primary placement clears the action secondary slot")
T.truthy(currentAction.customRemote,
    "debug action is marked local-only for remote timed-action sync")
Holder.Disable("primary_prop_test_done")
Holder.SetHand("auto")

Holder.SetMode("action_prop")
Holder.SetRequestedType(Holder.DefaultItem())
ok, reason = Holder.Enable(body, "held-npc", 0)
T.truthy(ok, "explicit action-prop mode accepts a weapon visual")
actionState = Holder.GetState(body, "held-npc")
T.equal(actionState.mode, "action_prop", "explicit action-prop mode is reported")
T.equal(actionState.actionPrimary, Holder.DefaultItem(),
    "two-handed prop occupies action primary")
T.equal(actionState.actionSecondary, Holder.DefaultItem(),
    "two-handed prop occupies action secondary")
T.equal(primary.id, "original_primary",
    "action-prop weapon visual does not mutate persistent primary")
Holder.Disable("weapon_prop_test_done")
Holder.SetMode("auto")

Holder.SetRequestedType(Holder.DefaultItem())
ok, reason = Holder.Enable(body, "held-npc", 0)
T.truthy(ok and reason == "temporary_item_equipped",
    "default shotgun can be equipped")
T.equal(primary.fullType, "Base.DoubleBarrelShotgun",
    "default shotgun is in the primary hand")
T.equal(secondary.fullType, "Base.DoubleBarrelShotgun",
    "default shotgun occupies both hands")
Holder.Disable("shotgun_test_done")

Holder.SetRequestedType("Base.NotAnItem")
ok, reason = Holder.Enable(body, "held-npc", 0)
T.falsy(ok, "invalid full type is rejected")
T.equal(reason, "invalid_full_type", "invalid item reason is reported")
T.equal(primary.id, "original_primary", "invalid item does not alter hands")

T.finish("pnc_npc_presentation_held_item_smoke")
