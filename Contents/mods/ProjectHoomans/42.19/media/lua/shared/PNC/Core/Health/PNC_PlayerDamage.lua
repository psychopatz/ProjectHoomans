-- Player weapon-hit bridge for managed NPC zombie bodies.
-- Native body health is only a safety buffer; custom NPC HP stays authoritative.

PNC = PNC or {}
PNC.PlayerDamage = PNC.PlayerDamage or {}

local PlayerDamage = PNC.PlayerDamage
local Core = PNC.Core
local Const = PNC.Const
local Types = PNC.Types
local Registry = PNC.Registry
local Health = PNC.Health
local Network = PNC.Network

PlayerDamage.LastReportAt = PlayerDamage.LastReportAt or {}

local function getModData(character)
    return character and character.getModData and character:getModData() or nil
end

local function getFullType(item)
    return item and item.getFullType and tostring(item:getFullType() or "") or ""
end

local function isPlayer(character)
    if not character then
        return false
    end
    if instanceof then
        return instanceof(character, "IsoPlayer")
    end
    return character.getObjectName and tostring(character:getObjectName() or "") == "Player"
end

local function isLocalPlayer(character)
    local playerNum
    if not isPlayer(character) then
        return false
    end
    if character.isLocalPlayer then
        local ok
        local result
        ok, result = pcall(character.isLocalPlayer, character)
        if ok and result == true then
            return true
        end
    end
    if character.getPlayerNum and getSpecificPlayer then
        playerNum = character:getPlayerNum()
        return playerNum ~= nil and playerNum >= 0 and getSpecificPlayer(playerNum) == character
    end
    return not (isClient and isClient())
end

local function isDedicatedServer()
    return isServer and isServer() and (not isClient or not isClient())
end

local function restoreEngineBuffer(zombie, record)
    local health = record and record.health or nil
    local buffer
    if not zombie or not zombie.setHealth or (record and record.alive == false) then
        return
    end
    buffer = health and health.state == "incapacitated"
        and Const.INCAPACITATED_ENGINE_BUFFER
        or Const.DEFAULT_ENGINE_BUFFER
    zombie:setHealth(tonumber(buffer) or 1000)
end

local function resolveHeldWeapon(player, reportedFullType)
    local primary = player and player.getPrimaryHandItem and player:getPrimaryHandItem() or nil
    local secondary = player and player.getSecondaryHandItem and player:getSecondaryHandItem() or nil
    reportedFullType = tostring(reportedFullType or "")
    if reportedFullType == "" then
        return primary or secondary
    end
    if getFullType(primary) == reportedFullType then
        return primary
    end
    if getFullType(secondary) == reportedFullType then
        return secondary
    end
    return nil
end

local function isRangedWeapon(weapon)
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
    return weapon.getSubCategory and tostring(weapon:getSubCategory() or "") == "Firearm"
end

function PlayerDamage.CanDamageRecord(record)
    local faction
    if not record or record.alive == false then
        return false
    end
    faction = Types and Types.NormalizeFaction and Types.NormalizeFaction(record.faction) or tostring(record.faction or "colonist")
    return faction ~= (Const.FACTION_COLONIST or "colonist")
end

function PlayerDamage.ScaleDamage(reportedDamage, weapon)
    local raw = tonumber(reportedDamage) or 0
    local weaponMaximum = weapon and weapon.getMaxDamage and tonumber(weapon:getMaxDamage()) or 1
    local weaponCap
    if raw <= 0 then
        return 0
    end
    weaponMaximum = math.max(0.25, weaponMaximum or 1)
    weaponCap = math.max(5, weaponMaximum * 20)
    return math.min(
        tonumber(Const.PLAYER_HIT_DAMAGE_MAX) or 50,
        weaponCap,
        math.max(1, raw * (tonumber(Const.PLAYER_HIT_DAMAGE_SCALE) or 10))
    )
end

function PlayerDamage.Apply(record, zombie, attacker, weapon, reportedDamage, source)
    local amount
    local applied
    if not record or not zombie then
        return false, "missing_target"
    end
    if not PlayerDamage.CanDamageRecord(record) then
        restoreEngineBuffer(zombie, record)
        return false, "colonist_protected"
    end
    amount = PlayerDamage.ScaleDamage(reportedDamage, weapon)
    if amount <= 0 then
        restoreEngineBuffer(zombie, record)
        return false, "invalid_damage"
    end
    applied = Health.ApplyDamage(record, zombie, {
        amount = amount,
        type = tostring(source or "player_weapon"),
        attackerKind = "player",
        attackerOnlineID = attacker and attacker.getOnlineID and attacker:getOnlineID() or nil,
        attackerUsername = attacker and attacker.getUsername and attacker:getUsername() or nil,
        weaponFullType = getFullType(weapon),
    }) == true
    restoreEngineBuffer(zombie, record)
    if applied and Network and Network.BroadcastRecord then
        Network.BroadcastRecord(record, "player_damage")
    end
    return applied, applied and "damaged" or "damage_rejected"
end

function PlayerDamage.HandleClientReport(player, args)
    local record
    local zombie
    local modData
    local weapon
    local currentOnlineID
    local currentInstanceID
    local distance
    local maxRange
    local key
    local now
    if not player or type(args) ~= "table" or not args.id then
        return false, "invalid_report"
    end
    if args.attackerOnlineID ~= nil
        and player.getOnlineID
        and tonumber(player:getOnlineID()) ~= tonumber(args.attackerOnlineID)
    then
        return false, "attacker_mismatch"
    end
    record = Registry.Get(args.id)
    zombie = record and Registry.GetLiveZombie(record.id) or nil
    if not record or not zombie or record.presenceState ~= Const.PRESENCE_LIVE then
        return false, "target_unavailable"
    end
    modData = getModData(zombie)
    if not modData or modData.PNC_NPC ~= true or tostring(modData.PNC_UUID or "") ~= tostring(record.id) then
        return false, "body_mismatch"
    end
    currentOnlineID = Network and Network.GetZombieOnlineID and Network.GetZombieOnlineID(zombie) or nil
    if args.bodyOnlineID ~= nil and currentOnlineID ~= nil
        and tonumber(args.bodyOnlineID) ~= tonumber(currentOnlineID)
    then
        return false, "online_id_mismatch"
    end
    currentInstanceID = zombie.getPersistentOutfitID and zombie:getPersistentOutfitID() or nil
    if args.bodyInstanceID ~= nil and currentInstanceID ~= nil
        and tostring(args.bodyInstanceID) ~= tostring(currentInstanceID)
    then
        return false, "instance_id_mismatch"
    end
    if args.bodyLease ~= nil and modData.PNC_BodyLease ~= nil
        and tostring(args.bodyLease) ~= tostring(modData.PNC_BodyLease)
    then
        return false, "body_lease_mismatch"
    end
    weapon = resolveHeldWeapon(player, args.weaponFullType)
    if tostring(args.weaponFullType or "") ~= "" and not weapon then
        return false, "weapon_mismatch"
    end
    distance = Core.Distance(player:getX(), player:getY(), zombie:getX(), zombie:getY())
    maxRange = isRangedWeapon(weapon)
        and (tonumber(Const.PLAYER_HIT_RANGED_RANGE) or 20)
        or (tonumber(Const.PLAYER_HIT_MELEE_RANGE) or 3)
    if distance > maxRange or player:getZ() ~= zombie:getZ() then
        return false, "out_of_range"
    end
    now = Core.Now()
    key = tostring(player.getOnlineID and player:getOnlineID() or player)
        .. ":" .. tostring(record.id)
    if (now - (tonumber(PlayerDamage.LastReportAt[key]) or 0))
        < (tonumber(Const.PLAYER_HIT_REPORT_COOLDOWN_MS) or 80)
    then
        return false, "rate_limited"
    end
    PlayerDamage.LastReportAt[key] = now
    return PlayerDamage.Apply(record, zombie, player, weapon, args.damage, "player_weapon_report")
end

local function reportClientHit(attacker, target, weapon, damage)
    local modData = getModData(target)
    if not sendClientCommand or not modData or not modData.PNC_UUID then
        return false
    end
    sendClientCommand(attacker, Const.MODULE, Const.CMD_PLAYER_WEAPON_HIT, {
        id = tostring(modData.PNC_UUID),
        attackerOnlineID = attacker.getOnlineID and attacker:getOnlineID() or nil,
        bodyOnlineID = Network and Network.GetZombieOnlineID and Network.GetZombieOnlineID(target) or nil,
        bodyInstanceID = target.getPersistentOutfitID and target:getPersistentOutfitID() or nil,
        bodyLease = modData.PNC_BodyLease,
        weaponFullType = getFullType(weapon),
        damage = tonumber(damage) or 0,
    })
    return true
end

local function onWeaponHitCharacter(attacker, target, weapon, damage)
    local modData
    local record
    if not target or not isPlayer(attacker) then
        return
    end
    modData = getModData(target)
    if not modData or modData.PNC_NPC ~= true or not modData.PNC_UUID then
        return
    end
    if Core.IsClientOnly and Core.IsClientOnly() then
        if isLocalPlayer(attacker) then
            reportClientHit(attacker, target, weapon, damage)
            restoreEngineBuffer(target, nil)
        end
        return
    end
    if isDedicatedServer() or not isLocalPlayer(attacker) then
        return
    end
    record = Registry.Get(modData.PNC_UUID)
    PlayerDamage.Apply(record, target, attacker, weapon, damage, "player_weapon_event")
end

if Events and Events.OnWeaponHitCharacter and not PlayerDamage.WeaponHitHookRegistered then
    Events.OnWeaponHitCharacter.Add(onWeaponHitCharacter)
    PlayerDamage.WeaponHitHookRegistered = true
end

