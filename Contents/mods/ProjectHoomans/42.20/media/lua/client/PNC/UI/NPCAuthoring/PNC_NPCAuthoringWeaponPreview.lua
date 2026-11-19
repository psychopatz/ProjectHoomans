-- Native weapon animation categories are also used by modded HandWeapons.
local Weapon = {}

function Weapon.Describe(item)
    if not item or not WeaponType or not WeaponType.getWeaponType
        or not instanceof or not instanceof(item, "HandWeapon") then return nil end
    local kind = WeaponType.getWeaponType(item)
    return kind and kind:getType()
end

return Weapon
