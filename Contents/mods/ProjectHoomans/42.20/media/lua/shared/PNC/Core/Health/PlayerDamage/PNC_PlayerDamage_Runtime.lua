-- Engine-object access shared by player-hit policy, reports, and application.

PNC = PNC or {}
PNC.PlayerDamage = PNC.PlayerDamage or {}
PNC.PlayerDamage.Internal = PNC.PlayerDamage.Internal or {}

local Runtime = PNC.PlayerDamage.Internal.Runtime
    or {}
PNC.PlayerDamage.Internal.Runtime = Runtime

local Const = PNC.Const

function Runtime.GetModData(character)
    return character and character.getModData
        and character:getModData() or nil
end

function Runtime.GetFullType(item)
    return item and item.getFullType
        and tostring(item:getFullType() or "") or ""
end

function Runtime.IsRangedWeapon(weapon)
    if not weapon then
        return false
    end
    if weapon.isRanged then
        local ok
        local result
        ok, result = pcall(weapon.isRanged, weapon)
        if ok then
            return result == true
        end
    end
    return weapon.getSubCategory
        and tostring(weapon:getSubCategory() or "") == "Firearm"
end

function Runtime.RestoreEngineBuffer(zombie, record)
    local health = record and record.health or nil
    local buffer
    if not zombie or not zombie.setHealth
        or (record and record.alive == false)
    then
        return
    end
    buffer = health and health.state == "incapacitated"
        and Const.INCAPACITATED_ENGINE_BUFFER
        or Const.DEFAULT_ENGINE_BUFFER
    zombie:setHealth(tonumber(buffer) or 1000)
end
