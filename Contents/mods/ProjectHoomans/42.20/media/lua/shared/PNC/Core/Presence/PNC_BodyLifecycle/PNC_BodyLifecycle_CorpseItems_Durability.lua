-- Anti-cheese corpse-drop durability policy for non-owned NPC weapons and clothing.
-- Living NPCs retain normal durability; on death, eligible weapons and clothing
-- on unowned NPCs roll condition in [1, max(1, floor(maxCond * maxPct / 100))].
-- Recruited / player-owned / colony-owned NPCs are exempt so players recover
-- the exact gear they gave them.

PNC = PNC or {}
PNC.BodyLifecycle = PNC.BodyLifecycle or {}
PNC.BodyLifecycle.Internal = PNC.BodyLifecycle.Internal or {}

local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal

local function isOwnedOrRecruited(record)
    if type(record) ~= "table" then return false end
    if record.recruited == true then return true end
    if record.ownerOnlineID ~= nil then return true end
    if record.ownerUsername ~= nil and tostring(record.ownerUsername) ~= "" then
        return true
    end
    local registry = PNC.Registry
    if registry and type(registry.IsColonyOwnedNPC) == "function" then
        local ok, owned = pcall(registry.IsColonyOwnedNPC, record)
        if ok and owned == true then return true end
    end
    return false
end

local function isEligibleWeaponOrClothing(item)
    if not item then return false end
    if type(instanceof) == "function" then
        if instanceof(item, "HandWeapon") or instanceof(item, "Clothing") then
            return true
        end
        return false
    end
    if type(item.IsWeapon) == "function" and item:IsWeapon() == true then
        return true
    end
    if type(item.IsClothing) == "function" and item:IsClothing() == true then
        return true
    end
    if type(item.getCategory) == "function" then
        local cat = tostring(item:getCategory() or "")
        if cat == "Weapon" or cat == "Clothing" then
            return true
        end
    end
    return false
end

local function rollOneToCap(cap)
    cap = math.max(1, math.floor(tonumber(cap) or 1))
    if cap <= 1 then return 1 end
    if type(ZombRand) == "function" then
        return 1 + math.floor(tonumber(ZombRand(cap)) or 0)
    end
    return math.random(1, cap)
end

local function isPolicyEnabled()
    local sandbox = PNC.Sandbox
    if sandbox and type(sandbox.NPCCorpseLowDurabilityLootEnabled) == "function" then
        return sandbox.NPCCorpseLowDurabilityLootEnabled() == true
    end
    return true
end

local function resolveMaxDurabilityPercent()
    local sandbox = PNC.Sandbox
    if sandbox and type(sandbox.NPCCorpseLootMaxDurabilityPercent) == "function" then
        return sandbox.NPCCorpseLootMaxDurabilityPercent()
    end
    return 5
end

function Internal.applyCorpseDropDurability(record, items)
    if type(items) ~= "table" or #items == 0 then return 0 end
    if not isPolicyEnabled() then return 0 end
    if isOwnedOrRecruited(record) then return 0 end

    local maxPct = math.max(1, math.min(100, tonumber(resolveMaxDurabilityPercent()) or 5))
    local adjusted = 0
    local i
    for i = 1, #items do
        local item = items[i]
        if isEligibleWeaponOrClothing(item)
            and type(item.getConditionMax) == "function"
            and type(item.setCondition) == "function"
        then
            local maxCond = math.floor(tonumber(item:getConditionMax()) or 0)
            if maxCond > 0 then
                local capCond = math.max(1, math.floor(maxCond * (maxPct / 100)))
                local rolled = rollOneToCap(capCond)
                local current = type(item.getCondition) == "function"
                    and math.floor(tonumber(item:getCondition()) or maxCond)
                    or maxCond
                local finalCond = math.max(0, math.min(current, rolled))
                pcall(item.setCondition, item, finalCond)
                adjusted = adjusted + 1
            end
        end
    end
    return adjusted
end

Lifecycle.ApplyCorpseDropDurability = Internal.applyCorpseDropDurability

return Lifecycle
