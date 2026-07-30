-- Central server-authoritative combat damage, ammo, condition, and wound rules.

PNC = PNC or {}
PNC.CombatDamage = PNC.CombatDamage or {}

local Damage = PNC.CombatDamage
local Inventory = PNC.Inventory
local Settings = PNC.Sandbox
local Core = PNC.Core

local BODY_PART_FALLBACK = {
    { id = "Head", weight = 5 },
    { id = "Neck", weight = 3 },
    { id = "Torso_Upper", weight = 18 },
    { id = "Torso_Lower", weight = 14 },
    { id = "Groin", weight = 5 },
    { id = "UpperArm_L", weight = 6 },
    { id = "UpperArm_R", weight = 6 },
    { id = "ForeArm_L", weight = 5 },
    { id = "ForeArm_R", weight = 5 },
    { id = "Hand_L", weight = 3 },
    { id = "Hand_R", weight = 3 },
    { id = "UpperLeg_L", weight = 8 },
    { id = "UpperLeg_R", weight = 8 },
    { id = "LowerLeg_L", weight = 6 },
    { id = "LowerLeg_R", weight = 6 },
    { id = "Foot_L", weight = 2 },
    { id = "Foot_R", weight = 2 },
}

local function sandbox()
    return SandboxVars and SandboxVars.ProjectHoomans or nil
end

local function enabled(key, fallback)
    if Settings and Settings.GetBoolean then
        return Settings.GetBoolean(key, fallback)
    end
    local vars = sandbox()
    if vars and vars[key] ~= nil then
        return vars[key] == true
    end
    return fallback == true
end

local function clamp(value, low, high)
    value = tonumber(value) or low
    return math.max(low, math.min(high, value))
end

local function roll(minimum, maximum)
    if ZombRandFloat then
        return ZombRandFloat(minimum, maximum)
    end
    return (minimum + maximum) * 0.5
end

function Damage.IsWeaponDamageEnabled()
    return enabled("EnableWeaponDamage", true)
end

function Damage.IsAmmoConsumptionEnabled()
    return enabled("NPCAmmoConsumption", false)
end

function Damage.IsWeaponConditionEnabled()
    return enabled("NPCWeaponConditionLoss", false)
end

function Damage.ArePlayerWoundsEnabled()
    return enabled("NPCPlayerWounds", true)
end

function Damage.RollWeaponDamage(weaponItem, fallback)
    local minimum
    local maximum
    if not weaponItem then
        return math.max(0, tonumber(fallback) or 0)
    end
    minimum = weaponItem.getMinDamage and tonumber(weaponItem:getMinDamage()) or nil
    maximum = weaponItem.getMaxDamage and tonumber(weaponItem:getMaxDamage()) or nil
    minimum = minimum and minimum > 0 and minimum or maximum or tonumber(fallback) or 0.5
    maximum = maximum and maximum >= minimum and maximum or minimum
    return roll(minimum, maximum)
end

function Damage.GetAttackDamage(record, attackType, weaponItem, fallback, skillLevel)
    local vars
    local base
    local normalized
    local attackMultiplier
    local dealtMultiplier
    if not Damage.IsWeaponDamageEnabled() or not weaponItem then
        return math.max(0, tonumber(fallback) or 0)
    end
    base = Damage.RollWeaponDamage(weaponItem, fallback)
    normalized = clamp(skillLevel, 0, 10) / 10
    if attackType == "ranged" then
        attackMultiplier = 15 + (10 * normalized)
    else
        attackMultiplier = 8 + (6 * normalized)
    end
    vars = sandbox()
    dealtMultiplier = math.max(0, tonumber(vars and vars.NPCDamageDealtMultiplier) or 1)
    return base * attackMultiplier * dealtMultiplier
end

local function equippedInventoryItem(record)
    local inv = Inventory and Inventory.EnsureRecordInventory and Inventory.EnsureRecordInventory(record) or nil
    local itemID = inv and inv.equipped and inv.equipped.primary or nil
    return inv, itemID, itemID and inv.items and inv.items[itemID] or nil
end

function Damage.ConsumeAmmo(record, weaponItem)
    local firearms = PNC.Firearms
    local inv
    local ammoType
    local itemID
    local item
    if firearms and firearms.PrepareShot then
        return firearms.PrepareShot(record, weaponItem)
    end
    if not Damage.IsAmmoConsumptionEnabled()
        or not record
        or not (
            record.recruited == true
            or record.ownerOnlineID ~= nil
            or (record.ownerUsername ~= nil and tostring(record.ownerUsername) ~= "")
        )
    then
        return true, "ammo_disabled"
    end
    ammoType = weaponItem and weaponItem.getAmmoType and weaponItem:getAmmoType() or nil
    if not ammoType or ammoType == "" then
        return true, "ammo_not_required"
    end
    inv = Inventory and Inventory.EnsureRecordInventory and Inventory.EnsureRecordInventory(record) or nil
    if not inv then
        return false, "inventory_unavailable"
    end
    for itemID, item in pairs(inv.items or {}) do
        if item and item.type == ammoType then
            if (tonumber(item.stack) or 1) > 1 then
                Inventory.ApplyDelta(record, {{ op = "update", itemID = itemID, stack = item.stack - 1 }}, "combat_ammo")
            else
                Inventory.ApplyDelta(record, {{ op = "remove", itemID = itemID }}, "combat_ammo")
            end
            return true, "ammo_consumed"
        end
    end
    return false, "out_of_ammo"
end

function Damage.ApplyWeaponConditionLoss(record, weaponItem)
    local inv
    local itemID
    local item
    local condition
    local lowerChance
    if not Damage.IsWeaponConditionEnabled() or not weaponItem then
        return false
    end
    inv, itemID, item = equippedInventoryItem(record)
    if not inv or not itemID or not item then
        return false
    end
    lowerChance = weaponItem.getConditionLowerChance and tonumber(weaponItem:getConditionLowerChance()) or 1
    lowerChance = math.max(1, math.floor(lowerChance or 1))
    if ZombRand and ZombRand(lowerChance) ~= 0 then
        return false
    end
    condition = tonumber(item.cond)
        or (weaponItem.getCondition and tonumber(weaponItem:getCondition()))
        or (weaponItem.getConditionMax and tonumber(weaponItem:getConditionMax()))
        or 1
    condition = math.max(0, condition - 1)
    return Inventory.ApplyDelta(record, {{ op = "update", itemID = itemID, cond = condition }}, "combat_condition") == true
end

local function bodyPartDefinitions()
    local wounds = PNC.NPCWounds
    local definitions = {}
    local i
    local id
    local part
    if wounds and wounds.PartOrder and wounds.Parts then
        for i = 1, #wounds.PartOrder do
            id = wounds.PartOrder[i]
            part = wounds.Parts[id]
            if part then
                definitions[#definitions + 1] = {
                    id = id,
                    weight = math.max(1, tonumber(part.weight) or 1),
                }
            end
        end
    end
    return #definitions > 0 and definitions or BODY_PART_FALLBACK
end

function Damage.ChooseBodyPartId(requestedPartId)
    local requested = requestedPartId and tostring(requestedPartId) or nil
    local definitions = bodyPartDefinitions()
    local total = 0
    local roll
    local i
    if requested then
        for i = 1, #definitions do
            if definitions[i].id == requested then return requested end
        end
    end
    for i = 1, #definitions do
        total = total + definitions[i].weight
    end
    roll = ZombRand and ZombRand(math.max(1, total)) or math.floor(total * 0.5)
    for i = 1, #definitions do
        roll = roll - definitions[i].weight
        if roll < 0 then return definitions[i].id end
    end
    return "Torso_Upper"
end

local function playerBodyPart(bodyDamage, partId)
    local partType = BodyPartType and BodyPartType[tostring(partId or "")] or nil
    local ok
    local result
    if not bodyDamage or not bodyDamage.getBodyPart or not partType then return nil end
    ok, result = pcall(bodyDamage.getBodyPart, bodyDamage, partType)
    return ok and result or nil
end

local function weaponFullType(weaponItem)
    return weaponItem and weaponItem.getFullType and tostring(weaponItem:getFullType() or "") or nil
end

function Damage.ResolveWoundType(attackType, weaponItem, requestedType)
    requestedType = tostring(requestedType or "")
    if requestedType == "scratch" or requestedType == "laceration"
        or requestedType == "bite" or requestedType == "bullet"
    then
        return requestedType
    end
    if attackType == "ranged" then return "bullet" end
    return weaponItem and "laceration" or "scratch"
end

function Damage.BuildHitEvent(attackerRecord, target, options)
    options = options or {}
    local attackType = tostring(options.attackType or "melee")
    local weaponItem = options.weaponItem
    return {
        amount = math.max(0, tonumber(options.damage or options.amount) or 0),
        attackType = attackType,
        attackKind = tostring(options.attackKind or attackType),
        partId = Damage.ChooseBodyPartId(options.partId),
        woundType = Damage.ResolveWoundType(attackType, weaponItem, options.woundType),
        attackerID = options.attackerID or attackerRecord and attackerRecord.id or nil,
        attackerKind = tostring(options.attackerKind or "npc"),
        attackerOnlineID = options.attackerOnlineID,
        attackerUsername = options.attackerUsername,
        weaponFullType = options.weaponFullType or weaponFullType(weaponItem),
        weaponItem = weaponItem,
        x = options.x,
        y = options.y,
        z = options.z,
        targetKind = target and target.kind or nil,
    }
end

local function addPlayerWound(bodyPart, hit)
    local pain
    local current
    if not bodyPart or not Damage.ArePlayerWoundsEnabled() then return end
    pain = tonumber(bodyPart.getAdditionalPain and bodyPart:getAdditionalPain() or 0) or 0
    if bodyPart.setAdditionalPain then
        bodyPart:setAdditionalPain(math.min(100, pain + math.max(3, hit.amount * 0.35)))
    end
    if hit.woundType == "bullet" then
        if bodyPart.setBleedingTime then
            current = tonumber(bodyPart.getBleedingTime and bodyPart:getBleedingTime() or 0) or 0
            bodyPart:setBleedingTime(math.max(current, 45))
        end
        if bodyPart.setDeepWounded then
            pcall(bodyPart.setDeepWounded, bodyPart, true)
        end
    elseif hit.woundType == "laceration" then
        if bodyPart.setCutTime then
            current = tonumber(bodyPart.getCutTime and bodyPart:getCutTime() or 0) or 0
            bodyPart:setCutTime(math.max(current, 8))
        elseif bodyPart.setScratchTime then
            current = tonumber(bodyPart.getScratchTime and bodyPart:getScratchTime() or 0) or 0
            bodyPart:setScratchTime(math.max(current, 8))
        end
        if bodyPart.setBleedingTime then
            current = tonumber(bodyPart.getBleedingTime and bodyPart:getBleedingTime() or 0) or 0
            bodyPart:setBleedingTime(math.max(current, 25))
        end
    elseif bodyPart.setScratchTime then
        current = tonumber(bodyPart.getScratchTime and bodyPart:getScratchTime() or 0) or 0
        bodyPart:setScratchTime(math.max(current, 6))
    end
end

function Damage.ApplyPlayerDamage(player, amount, attackType, weaponItem, hitEvent)
    local bodyDamage
    local bodyPart
    local current
    local healthLoss
    local hit
    local applied = false
    if not player or (tonumber(amount) or 0) <= 0 then
        return false
    end
    hit = hitEvent or Damage.BuildHitEvent(nil, { kind = "player" }, {
        damage = amount,
        attackType = attackType,
        weaponItem = weaponItem,
    })
    healthLoss = clamp((tonumber(amount) or 0) * (attackType == "ranged" and 0.42 or 0.34), 0.65, attackType == "ranged" and 22 or 16)
    bodyDamage = player.getBodyDamage and player:getBodyDamage() or nil
    bodyPart = playerBodyPart(bodyDamage, hit.partId)
    if bodyPart and bodyPart.AddDamage then
        applied = pcall(bodyPart.AddDamage, bodyPart, healthLoss) == true
    end
    if not applied and bodyPart and bodyPart.getHealth and bodyPart.setHealth then
        current = tonumber(bodyPart:getHealth()) or 100
        applied = pcall(bodyPart.setHealth, bodyPart, math.max(0, current - healthLoss)) == true
    end
    if not applied and bodyDamage and bodyDamage.getOverallBodyHealth and bodyDamage.setOverallBodyHealth then
        current = tonumber(bodyDamage:getOverallBodyHealth()) or 100
        applied = pcall(
            bodyDamage.setOverallBodyHealth,
            bodyDamage,
            math.max(0, current - healthLoss)
        ) == true
    end
    if not applied and player.getHealth and player.setHealth then
        current = tonumber(player:getHealth()) or 1
        applied = pcall(player.setHealth, player, math.max(0, current - (healthLoss / 100))) == true
    end
    if not applied then return false end
    addPlayerWound(bodyPart, hit)
    if bodyDamage and bodyDamage.Update then
        bodyDamage:Update()
    end
    if player.sendPlayerStatsPacket then
        pcall(function() player:sendPlayerStatsPacket() end)
    end
    return applied, hit
end

function Damage.ApplyNPCDamage(targetRecord, targetBody, hit)
    local wounds = PNC.NPCWounds
    local network = PNC.Network
    local relationships = PNC.Relationships
    local applied
    local result
    if not targetRecord or not wounds or not wounds.ApplyCombatDamage then
        return false, "invalid_npc_target"
    end
    applied, result = wounds.ApplyCombatDamage(targetRecord, targetBody, hit)
    if not applied then return false, "npc_damage_rejected", result end
    if hit and hit.attackerKind == "npc"
        and hit.attackerID
        and PNC.Factions
        and PNC.Factions.OnNPCAggression
    then
        local attackerRecord = PNC.Registry
            and PNC.Registry.Get
            and PNC.Registry.Get(hit.attackerID) or nil
        local at = getGameTime and getGameTime()
            and getGameTime().getWorldAgeHours
            and getGameTime():getWorldAgeHours() or 0
        if attackerRecord then
            PNC.Factions.OnNPCAggression(
                attackerRecord,
                targetRecord,
                at,
                {
                    killed = targetRecord.alive == false,
                    severe = hit and (
                        tonumber(hit.amount) or 0
                    ) >= 25,
                }
            )
        end
    end
    if hit and hit.attackerKind == "player"
        and relationships and relationships.ProvokeNeutralByPlayer
    then
        relationships.ProvokeNeutralByPlayer(targetRecord)
    end
    targetRecord.runtime = targetRecord.runtime or {}
    targetRecord.runtime.forceSyncEvent = nil
    if network then
        if targetRecord.alive == false and network.BroadcastRemoval then
            network.BroadcastRemoval(targetRecord.id, "death")
            targetRecord.lastSyncAt = targetRecord.presenceRevision
        elseif network.BroadcastRecord then
            network.BroadcastRecord(targetRecord, "combat_damage")
            targetRecord.lastSyncAt = Core and Core.Now and Core.Now() or targetRecord.lastSyncAt
        end
    end
    return true, "hit_npc", result
end

function Damage.ApplyZombieDamage(attackerRecord, attackerZombie, target, hit)
    local perception = PNC.Perception
    local reaction = PNC.CombatZombieReaction
    local victim = target and target.worldObject or nil
    local fakeZombie
    local scaledDamage
    local applied = false
    local health
    local reactionOptions
    local threatID
    local threatTarget
    local protectedRecord
    local actorKey
    local targetKey
    local socialNow
    if not victim and target and target.zombieId and perception and perception.FindZombieByID then
        victim = perception.FindZombieByID(target.zombieId)
    end
    if not victim or victim:isDead() then return false, "invalid_zombie_target" end
    threatID = target and target.zombieId
        or (victim.getOnlineID and victim:getOnlineID())
        or (victim.getPersistentOutfitID
            and victim:getPersistentOutfitID())
    actorKey = attackerRecord
        and PNC.EntityRef
        and PNC.EntityRef.ForNPC(attackerRecord.id) or nil
    threatTarget = victim.getTarget and victim:getTarget() or nil
    protectedRecord = threatTarget
        and PNC.Registry
        and PNC.Registry.FindRecordByZombie
        and PNC.Registry.FindRecordByZombie(threatTarget) or nil
    targetKey = protectedRecord
        and PNC.EntityRef.ForNPC(protectedRecord.id) or nil
    socialNow = PNC.SocialEventHooks
        and PNC.SocialEventHooks.WorldAgeHours
        and PNC.SocialEventHooks.WorldAgeHours() or nil
    if actorKey
        and socialNow
        and PNC.SocialEncounterTracker
        and PNC.SocialEncounterTracker.RecordActivity
    then
        PNC.SocialEncounterTracker.RecordActivity({
            actorKey = actorKey,
            targetKey = targetKey,
            threatID = threatID,
            threatWasTargeting = targetKey ~= nil,
            occurredAt = socialNow,
            actorX = attackerRecord.x,
            actorY = attackerRecord.y,
            actorZ = attackerRecord.z,
            targetX = protectedRecord and protectedRecord.x or nil,
            targetY = protectedRecord and protectedRecord.y or nil,
            targetZ = protectedRecord and protectedRecord.z or nil,
            x = victim:getX(),
            y = victim:getY(),
            z = victim:getZ(),
        })
    end
    fakeZombie = getCell and getCell():getFakeZombieForHit() or nil
    scaledDamage = hit.attackType == "ranged"
        and math.max(0.12, hit.amount * 0.06)
        or math.max(0.18, hit.amount * 0.08)
    reactionOptions = {
        kind = hit.attackType == "ranged" and "ranged" or "melee",
        hitReaction = hit.attackType == "ranged" and "ShotBelly" or "HitReaction",
        hitForce = hit.attackType == "ranged" and 0.78 or 0.92,
        pushDistance = hit.attackType == "ranged" and 0 or 0.18,
        pushDurationMs = hit.attackType == "ranged" and 0 or 150,
        durationMs = hit.attackType == "ranged" and 140 or 220,
        stepDistance = hit.attackType == "ranged" and 0.02 or 0.06,
        stagger = hit.attackType ~= "ranged",
        settleMs = hit.attackType == "ranged" and 420 or 650,
        partId = hit.partId,
        woundType = hit.woundType,
    }
    if reaction and reaction.ApplyWeaponHit then
        applied = reaction.ApplyWeaponHit(
            attackerZombie or fakeZombie,
            victim,
            hit.weaponItem,
            scaledDamage,
            reactionOptions
        )
    elseif hit.weaponItem and victim.Hit then
        applied = pcall(function()
            victim:Hit(hit.weaponItem, fakeZombie or attackerZombie, scaledDamage, false, 1, false)
        end)
    end
    if not applied then
        health = tonumber(victim:getHealth()) or 1
        victim:setHealth(health - scaledDamage)
        if victim:getHealth() <= 0 then
            if victim.Kill then
                victim:Kill(attackerZombie or fakeZombie)
            elseif victim.setHealth then
                victim:setHealth(0)
            end
        end
    end
    if not (reaction and reaction.ApplyWeaponHit) and reaction and reaction.Start then
        reaction.Start(attackerZombie or fakeZombie, victim, reactionOptions)
    end
    if PNC.ZombieAggro and PNC.ZombieAggro.OnZombieProvoked and (attackerZombie or fakeZombie) then
        PNC.ZombieAggro.OnZombieProvoked(victim, attackerZombie or fakeZombie)
    end
    if PNC.Network and PNC.Network.BroadcastZombieReaction then
        PNC.Network.BroadcastZombieReaction(victim, attackerZombie, reactionOptions)
    end
    if actorKey
        and socialNow
        and threatID ~= nil
        and ((victim.isDead and victim:isDead())
            or (victim.getHealth
                and (tonumber(victim:getHealth()) or 1) <= 0))
        and PNC.SocialEventHooks
        and PNC.SocialEventHooks.OnThreatNeutralized
    then
        PNC.SocialEventHooks.OnThreatNeutralized({
            actorKey = actorKey,
            targetKey = targetKey,
            threatID = threatID,
            threatWasTargeting = targetKey ~= nil,
            occurredAt = socialNow,
            x = victim:getX(),
            y = victim:getY(),
            z = victim:getZ(),
        })
    end
    return true, applied and "hit_zombie" or "hit_zombie_fallback", hit
end

function Damage.ApplyTargetDamage(attackerRecord, attackerBody, target, options)
    local registry = PNC.Registry
    local hit
    if Core and Core.IsAuthority and not Core.IsAuthority() then
        return false, "not_authority"
    end
    if not target then return false, "missing_target" end
    hit = Damage.BuildHitEvent(attackerRecord, target, options)
    if hit.amount <= 0 then return false, "invalid_damage", hit end
    if target.kind == "player" then
        local applied = Damage.ApplyPlayerDamage(target.player, hit.amount, hit.attackType, hit.weaponItem, hit)
        if applied == true
            and attackerRecord
            and PNC.Factions
            and PNC.Factions.OnNPCAttackPlayer
        then
            local at = getGameTime and getGameTime()
                and getGameTime().getWorldAgeHours
                and getGameTime():getWorldAgeHours() or 0
            PNC.Factions.OnNPCAttackPlayer(
                attackerRecord,
                target.player,
                at,
                {
                    severe = hit.amount >= 25,
                    killed = target.player.isDead
                        and target.player:isDead() == true,
                }
            )
        end
        return applied == true, applied == true and "hit_player" or "invalid_player_target", hit
    end
    if target.kind == "npc" then
        local targetRecord = registry and registry.Get and registry.Get(target.id) or nil
        local targetBody = registry and registry.GetLiveZombie and registry.GetLiveZombie(target.id) or nil
        return Damage.ApplyNPCDamage(targetRecord, targetBody, hit)
    end
    if target.kind == "zombie" then
        return Damage.ApplyZombieDamage(attackerRecord, attackerBody, target, hit)
    end
    return false, "unknown_target", hit
end
