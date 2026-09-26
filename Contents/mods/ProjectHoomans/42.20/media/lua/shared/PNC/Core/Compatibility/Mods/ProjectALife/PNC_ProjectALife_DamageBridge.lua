-- Route Project A-Life hits into Hoomans' managed-NPC wound pipeline.
-- The bridge only redirects attacks whose current target belongs to Hoomans.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}

local Bridge = PNC.Compatibility.ProjectALifeDamageBridge
    or { installAttempts = 0 }
PNC.Compatibility.ProjectALifeDamageBridge = Bridge
Bridge.installAttempts = tonumber(Bridge.installAttempts) or 0

local function isHoomansBody(body)
    local ownership = PNC.Compatibility.ActorOwnership
    if not ownership or type(ownership.IsHoomansOwned) ~= "function" then
        return false
    end
    local ok, owned = pcall(ownership.IsHoomansOwned, body)
    return ok and owned == true
end

local function hasAuthority()
    local core = PNC.Core
    if core and type(core.IsAuthority) == "function" then
        local ok, allowed = pcall(core.IsAuthority)
        return ok and allowed == true
    end
    return type(isServer) == "function" and isServer() == true
end

local function attackerId(shell)
    local ok, data = pcall(function() return shell:getModData() end)
    if ok and type(data) == "table"
        and type(data.ProjectALifeUID) == "string"
    then
        return data.ProjectALifeUID
    end
    return nil
end

local function attackerGeneration(shell)
    local ok, data = pcall(function() return shell:getModData() end)
    if ok and type(data) == "table" then
        return tonumber(data.ProjectALifeGeneration)
    end
    return nil
end

local function canProjectALifeAttack(actor, target, phase)
    local adapter = PNC.Compatibility.ProjectALifeAdapter
    if not adapter or type(adapter.CanProjectALifeAttack) ~= "function" then
        return false
    end
    local ok, allowed = pcall(
        adapter.CanProjectALifeAttack,
        actor,
        target,
        { phase = phase }
    )
    return ok and allowed == true
end

local function actorRecord(alife, shell)
    local uid = attackerId(shell)
    local registry = alife and alife.ActorRegistry
    if not uid or not registry then return nil end
    local reader = registry.read or registry.peek
    if type(reader) ~= "function" then return nil end
    local ok, record = pcall(reader, uid)
    return ok and type(record) == "table" and record or nil
end

local function applyIncomingDamage(alife, combat, shell, target, weapon)
    local incoming = PNC.Compatibility.IncomingDamage
    local humanDamage = alife and alife.HumanDamage
    if not incoming or type(incoming.Apply) ~= "function"
        or not humanDamage or type(humanDamage.points) ~= "function"
    then
        return false
    end

    local ok, amount, zone = pcall(humanDamage.points, weapon, 1)
    if not ok then return false end
    amount = tonumber(amount) or 0
    if amount <= 0 then return false end

    if type(humanDamage.scaled) == "function" then
        local output = 100
        local reduction = 0
        if type(humanDamage.outputOf) == "function" then
            local outputOk, value = pcall(humanDamage.outputOf, shell)
            if outputOk then output = value end
        end
        if type(humanDamage.reductionOf) == "function" then
            local reductionOk, value = pcall(humanDamage.reductionOf, target)
            if reductionOk then reduction = value end
        end
        local scaledOk, scaled = pcall(
            humanDamage.scaled, amount, output, reduction)
        if scaledOk then amount = tonumber(scaled) or amount end
    end

    local ranged = false
    if combat and type(combat.isRanged) == "function" then
        local rangedOk, value = pcall(combat.isRanged, weapon)
        ranged = rangedOk and value == true
    end

    local woundType = ranged and "bullet" or "scratch"
    if not ranged and combat and type(combat.meleeClass) == "function" then
        local classOk, class = pcall(combat.meleeClass, weapon)
        if classOk and (class == "knife" or class == "spear") then
            woundType = "laceration"
        end
    end

    local partId
    if zone == "head" then
        partId = "Head"
    elseif zone == "torso" then
        partId = "Torso_Upper"
    end
    local wounds = PNC.NPCWounds
    if partId and wounds and type(wounds.Parts) == "table"
        and not wounds.Parts[partId]
    then
        partId = nil
    end

    local weaponFullType
    pcall(function() weaponFullType = weapon:getFullType() end)
    local appliedOk, applied = pcall(incoming.Apply, {
        target = target,
        attacker = shell,
        amount = amount,
        partId = partId,
        woundType = woundType,
        type = "project_alife_combat_damage",
        attackerKind = "foreign_npc",
        attackerProvider = "ProjectALifeNPCs",
        attackerID = attackerId(shell),
        attackerGeneration = attackerGeneration(shell),
        weaponFullType = weaponFullType,
    })
    if appliedOk and applied == true then
        local adapter = PNC.Compatibility.ProjectALifeAdapter
        if adapter and type(adapter.RecordConflict) == "function" then
            local record = actorRecord(alife, shell)
            local targetFaction = type(adapter.GetHoomansFactionID) == "function"
                and adapter.GetHoomansFactionID(target) or nil
            local x, y, z
            pcall(function()
                x, y, z = target:getX(), target:getY(), target:getZ()
            end)
            pcall(
                adapter.RecordConflict,
                "ProjectALifeNPCs",
                record and record.factionId or nil,
                "ProjectHoomans",
                targetFaction,
                {
                    reason = "projectalife_confirmed_damage",
                    direction = "incoming",
                    x = x,
                    y = y,
                    z = z,
                    factionName = record and record.factionId or nil,
                    damage = amount,
                }
            )
        end
    end
    return appliedOk and applied == true
end

local function installDamageBridge()
    local alife = ProjectALife
    local combat = alife and alife.Combat
    local adapters = combat and combat.adapters
    if type(adapters) ~= "table"
        or type(combat.resolveAttack) ~= "function"
        or type(combat.weaponFor) ~= "function"
        or type(combat.isRanged) ~= "function"
        or not alife.HumanDamage
        or type(alife.HumanDamage.points) ~= "function"
    then
        return false
    end
    if Bridge.combat == combat and combat.resolveAttack == Bridge.wrapper then
        return true
    end

    local originalResolveAttack = combat.resolveAttack
    local wrapper
    wrapper = function(actor, shell, target, shove, reaction, shoveFloor)
        if not isHoomansBody(target) or not hasAuthority() then
            return originalResolveAttack(
                actor, shell, target, shove, reaction, shoveFloor)
        end

        if not canProjectALifeAttack(actor, target, "damage") then
            return false
        end

        local weaponOk, weapon = pcall(combat.weaponFor, shell)
        if not weaponOk or weapon == nil then
            return false
        end

        local originalDamageAdapter = adapters.applyDamage
        local function damageAdapter(hitShell, victim, hitWeapon)
            if isHoomansBody(victim) then
                return applyIncomingDamage(
                    alife, combat, hitShell, victim, hitWeapon)
            end
            if type(originalDamageAdapter) == "function" then
                return originalDamageAdapter(
                    hitShell, victim, hitWeapon) == true
            end
            return false
        end

        local rangedOk, rangedValue = pcall(combat.isRanged, weapon)
        local ranged = rangedOk and rangedValue == true
        local lineOfFire = alife.LineOfFire
        local originalLineResolve = lineOfFire and lineOfFire.resolve
        local deferDamageAdapter = ranged
            and type(originalLineResolve) == "function"
        local settings = type(combat.settings) == "table"
            and combat.settings or nil
        local originalPenetration = settings and settings.bulletPenetration
        local changedPenetration = false

        if ranged and type(originalDamageAdapter) ~= "function"
            and type(settings) == "table"
        then
            settings.bulletPenetration = false
            changedPenetration = true
        end

        local lineWrapper
        if deferDamageAdapter then
            lineWrapper = function(lineShell, lineTarget, lineWeapon,
                    applyCharacterHit, mayHitCharacter)
                lineOfFire.resolve = originalLineResolve
                local function routeLineHit(body)
                    if isHoomansBody(body) then
                        if body ~= target
                            and canProjectALifeAttack(actor, body, "damage")
                        then
                            applyIncomingDamage(
                                alife, combat, lineShell, body, lineWeapon)
                        end
                        return
                    end
                    if type(applyCharacterHit) == "function" then
                        return applyCharacterHit(body)
                    end
                end
                local ok, clear = pcall(
                    originalLineResolve,
                    lineShell, lineTarget, lineWeapon,
                    routeLineHit, mayHitCharacter)
                adapters.applyDamage = damageAdapter
                if not ok then error(clear) end
                return clear
            end
            lineOfFire.resolve = lineWrapper
        else
            adapters.applyDamage = damageAdapter
        end

        local ok, result = pcall(originalResolveAttack,
            actor, shell, target, shove, reaction, shoveFloor)
        adapters.applyDamage = originalDamageAdapter
        if deferDamageAdapter and lineOfFire.resolve == lineWrapper then
            lineOfFire.resolve = originalLineResolve
        end
        if changedPenetration then
            settings.bulletPenetration = originalPenetration
        end
        if not ok then error(result) end
        return result
    end

    combat.resolveAttack = wrapper
    Bridge.combat = combat
    Bridge.wrapper = wrapper
    return true
end

local function removeRetry()
    if Bridge.retry and Events and Events.OnTick
        and Events.OnTick.Remove
    then
        Events.OnTick.Remove(Bridge.retry)
    end
end

local function retryInstall()
    Bridge.installAttempts = Bridge.installAttempts + 1
    if installDamageBridge() or Bridge.installAttempts >= 120 then
        removeRetry()
    end
end

if not installDamageBridge() and Events and Events.OnTick
    and Events.OnTick.Add
then
    Bridge.retry = retryInstall
    Events.OnTick.Add(retryInstall)
end

return installDamageBridge
