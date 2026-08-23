local Firearms = PNC.Firearms
local Internal = PNC.Combat.Internal
local Settings = PNC.Sandbox

function Firearms.IsPlayerOwned(record)
    if type(record) ~= "table" then return false end
    return record.recruited == true
        or record.ownerOnlineID ~= nil
        or (record.ownerUsername ~= nil and tostring(record.ownerUsername) ~= "")
end

function Firearms.UsesInventoryAmmo(record)
    local enabled = Settings and Settings.CompanionAmmoRealismEnabled
        and Settings.CompanionAmmoRealismEnabled()
        or (Settings and Settings.GetBoolean
            and Settings.GetBoolean("NPCAmmoConsumption", false)
            or false)
    return enabled == true and Firearms.IsPlayerOwned(record)
end

function Firearms.HasUnlimitedReserve(record)
    return not Firearms.UsesInventoryAmmo(record)
end

function Firearms.Describe(record, weaponItem)
    local fullType = Internal.FullTypeOf(record, weaponItem)
    local scriptItem = Internal.ScriptItemFor(fullType)
    local weaponFamily
    local reloadFamily
    local ammoType
    local manuallyRemoveSpentRounds
    if not fullType then return nil end
    weaponFamily, reloadFamily = Internal.ResolveFamily(fullType, scriptItem)
    ammoType = Internal.SafeMethod(weaponItem, "getAmmoType")
        or Internal.SafeMethod(scriptItem, "getAmmoType")
    manuallyRemoveSpentRounds = Internal.SafeMethod(weaponItem, "isManuallyRemoveSpentRounds")
    if manuallyRemoveSpentRounds == nil then
        manuallyRemoveSpentRounds = Internal.SafeMethod(scriptItem, "isManuallyRemoveSpentRounds")
    end
    return {
        fullType = fullType,
        -- Build 42 returns an ItemKey here, while older/modded weapons may
        -- return a full-type string. Canonicalizing through getItemKey keeps
        -- inventory matching and replicated shot metadata compatible with both.
        ammoType = Internal.ItemKeyString(ammoType),
        capacity = Internal.ResolveCapacity(weaponItem, scriptItem, reloadFamily),
        ammoPerShot = Internal.PositiveInteger(Internal.SafeMethod(weaponItem, "getAmmoPerShoot"))
            or Internal.PositiveInteger(Internal.SafeMethod(scriptItem, "getAmmoPerShoot"))
            or 1,
        weaponFamily = weaponFamily,
        reloadFamily = reloadFamily,
        reloadAnim = Internal.ReloadAnims[reloadFamily] or Internal.ReloadAnims.pistol,
        reloadDurationMs = Internal.ResolveReloadDuration(record, scriptItem, reloadFamily),
        shotSound = Internal.SafeMethod(weaponItem, "getSwingSound")
            or Internal.SafeMethod(scriptItem, "getSwingSound"),
        soundRadius = Internal.NonNegativeInteger(Internal.SafeMethod(weaponItem, "getSoundRadius"))
            or Internal.NonNegativeInteger(Internal.SafeMethod(scriptItem, "getSoundRadius"))
            or 30,
        soundVolume = Internal.NonNegativeInteger(Internal.SafeMethod(weaponItem, "getSoundVolume"))
            or Internal.NonNegativeInteger(Internal.SafeMethod(scriptItem, "getSoundVolume"))
            or 10,
        soundGain = tonumber(Internal.SafeMethod(weaponItem, "getSoundGain"))
            or tonumber(Internal.SafeMethod(scriptItem, "getSoundGain"))
            or 1,
        projectileCount = Internal.PositiveInteger(Internal.SafeMethod(weaponItem, "getProjectileCount"))
            or Internal.PositiveInteger(Internal.SafeMethod(scriptItem, "getProjectileCount"))
            or 1,
        projectileSpread = tonumber(Internal.SafeMethod(weaponItem, "getProjectileSpread"))
            or tonumber(Internal.SafeMethod(scriptItem, "getProjectileSpread"))
            or 0,
        maxRange = tonumber(Internal.SafeMethod(weaponItem, "getMaxRange"))
            or tonumber(Internal.SafeMethod(scriptItem, "getMaxRange")),
        piercing = Internal.SafeMethod(weaponItem, "isPiercingBullets") == true
            or Internal.SafeMethod(scriptItem, "isPiercingBullets") == true,
        impactSound = Internal.SafeMethod(weaponItem, "getImpactSound")
            or Internal.SafeMethod(scriptItem, "getImpactSound"),
        shellFallSound = Internal.SafeMethod(weaponItem, "getShellFallSound")
            or Internal.SafeMethod(scriptItem, "getShellFallSound"),
        ejectsShell = manuallyRemoveSpentRounds ~= true,
        rackAfterShoot = Internal.SafeMethod(weaponItem, "isRackAfterShoot") == true
            or Internal.SafeMethod(scriptItem, "isRackAfterShoot") == true,
    }
end

function Firearms.GetMagazineState(record, weaponItem)
    local descriptor
    local state
    local reason
    descriptor = Firearms.Describe(record, weaponItem)
    if not descriptor or not descriptor.ammoType or descriptor.ammoType == "" then
        return {
            ammoNotRequired = true,
            unlimitedReserve = true,
            count = nil,
            capacity = descriptor and descriptor.capacity or nil,
        }, "ammo_not_required"
    end
    state, reason = Internal.EnsureMagazine(record, descriptor, weaponItem)
    if not state then return nil, reason end
    return {
        ammoNotRequired = false,
        unlimitedReserve = Firearms.HasUnlimitedReserve(record),
        count = state.count,
        capacity = descriptor.capacity,
        ammoType = descriptor.ammoType,
        itemID = state.itemID,
        looseAmmo = Internal.CountLooseAmmo(state.inventory, descriptor.ammoType, state.itemID),
        descriptor = descriptor,
    }, "magazine_ready"
end
