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

local function listContainsMode(list, needle)
    if not list then return false end
    local sizeFn = list.size
    local getFn = list.get
    if type(sizeFn) == "function" and type(getFn) == "function" then
        local count = tonumber(sizeFn(list)) or 0
        for i = 0, count - 1 do
            if string.lower(tostring(getFn(list, i) or "")) == needle then
                return true
            end
        end
    elseif type(list) == "table" then
        for i = 1, #list do
            if string.lower(tostring(list[i] or "")) == needle then
                return true
            end
        end
    end
    return false
end

local CADENCE_DEFAULTS = {
    auto = {
        cooldownMs = 220, hitDelayMs = 85, durationMs = 180,
        followUpAimScale = 0.15, burstSize = 4, burstPauseMs = 380,
    },
    burst = {
        cooldownMs = 240, hitDelayMs = 90, durationMs = 190,
        followUpAimScale = 0.18, burstSize = 3, burstPauseMs = 420,
    },
    semipistol = {
        cooldownMs = 390, hitDelayMs = 110, durationMs = 260,
        followUpAimScale = 0.25, burstSize = 0, burstPauseMs = 0,
    },
    semirifle = {
        cooldownMs = 460, hitDelayMs = 110, durationMs = 270,
        followUpAimScale = 0.30, burstSize = 0, burstPauseMs = 0,
    },
    revolver = {
        cooldownMs = 560, hitDelayMs = 120, durationMs = 310,
        followUpAimScale = 0.35, burstSize = 0, burstPauseMs = 0,
    },
    dbshotgun = {
        cooldownMs = 390, hitDelayMs = 120, durationMs = 290,
        followUpAimScale = 0.30, burstSize = 0, burstPauseMs = 0,
    },
    pump_shotgun = {
        cooldownMs = 960, hitDelayMs = 140, durationMs = 440,
        followUpAimScale = 0.45, burstSize = 0, burstPauseMs = 0,
    },
    bolt_rifle = {
        cooldownMs = 1220, hitDelayMs = 150, durationMs = 500,
        followUpAimScale = 0.55, burstSize = 0, burstPauseMs = 0,
    },
}

local function resolveCadenceProfile(fullType, weaponItem, scriptItem, reloadFamily, rackAfterShoot)
    local lowerType = string.lower(tostring(fullType or ""))
    local fireMode = string.lower(tostring(
        Internal.SafeMethod(weaponItem, "getFireMode")
            or Internal.SafeMethod(scriptItem, "getFireMode")
            or ""
    ))
    local modes = Internal.SafeMethod(weaponItem, "getFireModePossibilities")
        or Internal.SafeMethod(scriptItem, "getFireModePossibilities")
    local isAuto = fireMode == "auto"
        or listContainsMode(modes, "auto")
        or string.find(lowerType, "assault", 1, true) ~= nil
        or string.find(lowerType, "m16", 1, true) ~= nil
        or string.find(lowerType, "smg", 1, true) ~= nil
        or string.find(lowerType, "mp5", 1, true) ~= nil
        or string.find(lowerType, "uzi", 1, true) ~= nil
        or string.find(lowerType, "ak47", 1, true) ~= nil
        or string.find(lowerType, "ak74", 1, true) ~= nil
        or string.find(lowerType, "lmg", 1, true) ~= nil
        or string.find(lowerType, "m249", 1, true) ~= nil
        or string.find(lowerType, "vector", 1, true) ~= nil
    local isBurst = (not isAuto) and (fireMode == "burst" or listContainsMode(modes, "burst"))

    local cadenceClass
    if isAuto then
        cadenceClass = "auto"
    elseif isBurst then
        cadenceClass = "burst"
    elseif reloadFamily == "dbshotgun" then
        cadenceClass = "dbshotgun"
    elseif reloadFamily == "shotgun" then
        cadenceClass = rackAfterShoot and "pump_shotgun" or "semirifle"
    elseif reloadFamily == "revolver" then
        cadenceClass = "revolver"
    elseif reloadFamily == "rifle" then
        cadenceClass = rackAfterShoot and "bolt_rifle" or "semirifle"
    else
        cadenceClass = "semipistol"
    end

    local preset = CADENCE_DEFAULTS[cadenceClass] or CADENCE_DEFAULTS.semipistol
    local cyclic = tonumber(Internal.SafeMethod(weaponItem, "getCyclicRateMultiplier"))
        or tonumber(Internal.SafeMethod(scriptItem, "getCyclicRateMultiplier"))
        or 1
    if cyclic <= 0 then cyclic = 1 end
    cyclic = math.max(0.5, math.min(2.5, cyclic))

    local recoilDelay = tonumber(Internal.SafeMethod(weaponItem, "getRecoilDelay"))
        or tonumber(Internal.SafeMethod(scriptItem, "getRecoilDelay"))
    local recoilScale = 1
    if recoilDelay and recoilDelay >= 0 then
        -- Vanilla pistols ~12-20, M16 ~0-12, shotguns ~50, bolt rifles ~60-100.
        recoilScale = math.max(0.75, math.min(1.45, 0.78 + (recoilDelay / 90)))
    end

    local cooldownMs = math.floor((preset.cooldownMs * recoilScale) / cyclic)
    cooldownMs = math.max(130, math.min(1800, cooldownMs))
    local durationMs = math.min(preset.durationMs, math.max(110, cooldownMs - 25))
    local hitDelayMs = math.min(preset.hitDelayMs, math.max(55, math.floor(durationMs * 0.5)))

    return {
        fireMode = fireMode ~= "" and fireMode or (isAuto and "auto" or (isBurst and "burst" or "single")),
        isAutomatic = isAuto == true,
        isBurst = isBurst == true,
        cadenceClass = cadenceClass,
        fireCooldownMs = cooldownMs,
        shotHitDelayMs = hitDelayMs,
        shotDurationMs = durationMs,
        followUpAimScale = preset.followUpAimScale,
        burstSize = preset.burstSize,
        burstPauseMs = preset.burstPauseMs,
    }
end

function Firearms.Describe(record, weaponItem, character)
    local core = PNC and PNC.Core or nil
    local now = core and type(core.Now) == "function" and tonumber(core.Now()) or nil
    local runtime = type(record) == "table" and record.runtime or nil
    if type(record) == "table" and not runtime then
        runtime = {}
        record.runtime = runtime
    end
    local skills = PNC and PNC.Skills or nil
    local reloadLevel = skills and skills.GetLevel
        and math.max(0, math.min(10, tonumber(skills.GetLevel(record, "Reloading")) or 0))
        or 0
    local primaryFullType = record and record.equipment
        and record.equipment.primaryFullType or nil
    local hasChar = character ~= nil
    local scriptManagerFn = getScriptManager
    local cached = runtime and runtime.firearmDescriptorCache or nil
    if cached
        and weaponItem ~= nil
        and cached.weaponItem == weaponItem
        and cached.primaryFullType == primaryFullType
        and cached.hasCharacter == hasChar
        and cached.reloadLevel == reloadLevel
        and cached.scriptManagerFn == scriptManagerFn
        and ((now == nil and cached.noClock == true)
            or (now ~= nil and now < (tonumber(cached.expiresAt) or 0)))
    then
        return cached.descriptor
    end
    local fullType = Internal.FullTypeOf(record, weaponItem)
    if not fullType then return nil end
    if cached
        and cached.fullType == fullType
        and cached.weaponItem == weaponItem
        and cached.hasCharacter == hasChar
        and cached.reloadLevel == reloadLevel
        and cached.scriptManagerFn == scriptManagerFn
        and ((now == nil and cached.noClock == true)
            or (now ~= nil and now < (tonumber(cached.expiresAt) or 0)))
    then
        return cached.descriptor
    end
    local scriptItem = Internal.ScriptItemFor(fullType)
    local weaponFamily
    local reloadFamily
    local ammoType
    local manuallyRemoveSpentRounds
    local maxRange
    weaponFamily, reloadFamily = Internal.ResolveFamily(fullType, scriptItem)
    ammoType = Internal.SafeMethod(weaponItem, "getAmmoType")
        or Internal.SafeMethod(scriptItem, "getAmmoType")
    manuallyRemoveSpentRounds = Internal.SafeMethod(weaponItem, "isManuallyRemoveSpentRounds")
    if manuallyRemoveSpentRounds == nil then
        manuallyRemoveSpentRounds = Internal.SafeMethod(scriptItem, "isManuallyRemoveSpentRounds")
    end
    if character then
        maxRange = Internal.SafeMethod(weaponItem, "getMaxRange", character)
    end
    maxRange = tonumber(maxRange)
        or tonumber(Internal.SafeMethod(weaponItem, "getMaxRange"))
        or tonumber(Internal.SafeMethod(scriptItem, "getMaxRange"))
    local rackAfterShoot = Internal.SafeMethod(weaponItem, "isRackAfterShoot") == true
        or Internal.SafeMethod(scriptItem, "isRackAfterShoot") == true
    local cadence = resolveCadenceProfile(fullType, weaponItem, scriptItem, reloadFamily, rackAfterShoot)
    local descriptor = {
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
        maxRange = maxRange,
        piercing = Internal.SafeMethod(weaponItem, "isPiercingBullets") == true
            or Internal.SafeMethod(scriptItem, "isPiercingBullets") == true,
        impactSound = Internal.SafeMethod(weaponItem, "getImpactSound")
            or Internal.SafeMethod(scriptItem, "getImpactSound"),
        shellFallSound = Internal.SafeMethod(weaponItem, "getShellFallSound")
            or Internal.SafeMethod(scriptItem, "getShellFallSound"),
        ejectsShell = manuallyRemoveSpentRounds ~= true,
        rackAfterShoot = rackAfterShoot,
        fireMode = cadence.fireMode,
        isAutomatic = cadence.isAutomatic,
        isBurst = cadence.isBurst,
        cadenceClass = cadence.cadenceClass,
        fireCooldownMs = cadence.fireCooldownMs,
        shotHitDelayMs = cadence.shotHitDelayMs,
        shotDurationMs = cadence.shotDurationMs,
        followUpAimScale = cadence.followUpAimScale,
        burstSize = cadence.burstSize,
        burstPauseMs = cadence.burstPauseMs,
    }
    if runtime then
        runtime.firearmDescriptorCache = {
            fullType = fullType,
            primaryFullType = primaryFullType,
            weaponItem = weaponItem,
            hasCharacter = hasChar,
            reloadLevel = reloadLevel,
            scriptManagerFn = scriptManagerFn,
            noClock = now == nil,
            expiresAt = now and (now + 2000) or 0,
            descriptor = descriptor,
        }
    end
    return descriptor
end

function Firearms.GetMagazineState(record, weaponItem, options)
    local descriptor
    local state
    local reason
    local unlimitedReserve
    local looseAmmo
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
    unlimitedReserve = Firearms.HasUnlimitedReserve(record)
    if unlimitedReserve then
        looseAmmo = 0
    elseif type(options) == "table"
        and options.skipLooseAmmoWhenLoaded == true
        and (tonumber(state.count) or 0) > 0
    then
        looseAmmo = nil
    else
        looseAmmo = Internal.CountLooseAmmo(
            state.inventory,
            descriptor.ammoType,
            state.itemID
        )
    end
    return {
        ammoNotRequired = false,
        unlimitedReserve = unlimitedReserve,
        count = state.count,
        capacity = descriptor.capacity,
        ammoType = descriptor.ammoType,
        itemID = state.itemID,
        looseAmmo = looseAmmo,
        descriptor = descriptor,
    }, "magazine_ready"
end
