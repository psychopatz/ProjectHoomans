-- On-demand food lifecycle for abstract inventories.
--
-- The shared core performs the time calculation. This adapter supplies PZ
-- item definitions and turns lifecycle results into one authoritative delta,
-- avoiding a per-item OnTick scan.

PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}

local Inventory = PNC.Inventory
local Internal = Inventory.Internal
local Portable = require "PsychopatzCore/Inventory/PsychopatzPortableItemState"

Internal.FoodLifecyclePolicyProvider =
    Internal.FoodLifecyclePolicyProvider or nil

local function finite(value)
    value = tonumber(value)
    if not value or value ~= value or value == math.huge
        or value == -math.huge
    then
        return nil
    end
    return value
end

local function sandboxOptionValue(name)
    local getSandboxOptions = rawget(_G, "getSandboxOptions")
    local sandboxClass = rawget(_G, "SandboxOptions")
    local options
    local option
    local ok
    if type(getSandboxOptions) == "function" then
        ok, options = pcall(getSandboxOptions)
    elseif sandboxClass and type(sandboxClass.getInstance) == "function" then
        ok, options = pcall(sandboxClass.getInstance)
    elseif sandboxClass then
        options = sandboxClass.instance
        ok = options ~= nil
    end
    if not ok or not options then return nil end
    option = options[name]
    if option and type(option.getValue) == "function" then
        ok, option = pcall(option.getValue, option)
        return ok and finite(option) or nil
    end
    return finite(option)
end

function Internal.getFoodRotSpeed()
    local value = sandboxOptionValue("foodRotSpeed")
    if value == 1 then return 1.7 end
    if value == 2 then return 1.4 end
    if value == 4 then return 0.7 end
    if value == 5 then return 0.4 end
    return 1
end

function Internal.getRottenFoodRemovalDays()
    local value = sandboxOptionValue("daysForRottenFoodRemoval")
    return value ~= nil and value or -1
end

function Inventory.RegisterFoodLifecyclePolicyProvider(callback)
    Internal.FoodLifecyclePolicyProvider = type(callback) == "function"
        and callback or nil
end

local function copyPolicy(base, extension)
    local output = {}
    local key
    if type(base) == "table" then
        for key, value in pairs(base) do output[key] = value end
    end
    if type(extension) == "table" then
        for key, value in pairs(extension) do output[key] = value end
    end
    return output
end

local function copyState(state)
    local output = {}
    local key
    local value
    if PNC.Core and type(PNC.Core.DeepCopy) == "function" then
        return PNC.Core.DeepCopy(state or {})
    end
    for key, value in pairs(state or {}) do
        if type(value) == "table" then
            output[key] = copyState(value)
        else
            output[key] = value
        end
    end
    return output
end

local function replacementFullType(itemType, replacement)
    local module
    replacement = tostring(replacement or "")
    if replacement == "" then return nil end
    if string.find(replacement, ".", 1, true) then
        return Internal.normalizeItemType(replacement)
    end
    module = string.match(tostring(itemType or ""), "^([^%.]+)%.")
    return module and Internal.normalizeItemType(module .. "." .. replacement)
        or nil
end

local function lifecyclePolicy(record, item, profile, options)
    local policy = {
        foodRotSpeed = finite(options.foodRotSpeed)
            or finite(profile.foodRotSpeed)
            or Internal.getFoodRotSpeed(),
        rotMultiplier = finite(options.rotMultiplier)
            or finite(profile.rotMultiplier)
            or 1,
    }
    local provider = options.policyProvider
        or Internal.FoodLifecyclePolicyProvider
    if type(provider) == "function" then
        local ok
        local extension
        ok, extension = pcall(provider, record, item, profile, options)
        if ok then policy = copyPolicy(policy, extension) end
    end
    return policy
end

local function updateOperation(item, state)
    return {
        op = "update",
        itemID = item.id,
        itemState = state,
    }
end

function Inventory.AdvanceFoodLifecycle(record, nowHours, options)
    local inv
    local ops = {}
    local now = finite(nowHours)
    local removalDays
    local item
    local profile
    local state
    local sourceState
    local changed
    local status
    local replacement
    local policy
    local index
    options = type(options) == "table" and options or {}
    inv = Inventory.EnsureRecordInventory(record)
    if not inv then return false, "inventory_unavailable", 0 end
    now = now or Portable.GetWorldAgeHours()
    if now == nil then return false, "world_time_unavailable", 0 end
    removalDays = finite(options.removalDays)
    if removalDays == nil then removalDays = Internal.getRottenFoodRemovalDays() end

    for _, candidate in pairs(inv.items or {}) do
        item = candidate
        profile = item and Inventory.GetFoodProfile(item.type) or nil
        if item and profile and profile.food == true then
            sourceState = type(item.itemState) == "table"
                and item.itemState or {}
            state = copyState(sourceState)
            if state.foodLastAgedHours == nil
                and state.foodCreatedAtHours == nil
                and item.templateKey ~= nil
                and inv.template
            then
                state.foodCreatedAtHours = finite(
                    inv.template.createdAtHours)
            end
            policy = lifecyclePolicy(record, item, profile, options)
            changed, status = Portable.AdvanceFoodState(
                state, profile, now, policy
            )
            if changed or status.rotten then
                replacement = status.rotten
                    and replacementFullType(
                        item.type, profile.replaceOnRotten
                    ) or nil
                if replacement and replacement ~= item.type then
                    ops[#ops + 1] = {
                        op = "replace",
                        itemID = item.id,
                        type = replacement,
                        itemState = state,
                    }
                elseif status.rotten
                    and removalDays >= 0
                    and profile.offAgeMax ~= nil
                    and profile.offAgeMax < 1000000000
                    and (finite(state.age) or 0)
                        > profile.offAgeMax + removalDays
                then
                    ops[#ops + 1] = {
                        op = "remove",
                        itemID = item.id,
                    }
                elseif changed then
                    ops[#ops + 1] = updateOperation(item, state)
                end
            end
        end
    end

    if #ops <= 0 then return false, "unchanged", 0 end
    local applied, appliedOps = Inventory.ApplyDelta(
        record, ops, options.reason or "food_lifecycle"
    )
    if not applied then return false, "lifecycle_delta_failed", 0 end
    index = #appliedOps
    return true, "advanced", index
end

return Inventory
