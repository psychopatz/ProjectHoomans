-- Client event capture and singleplayer routing for managed-body player hits.

PNC = PNC or {}
PNC.PlayerDamage = PNC.PlayerDamage or {}
PNC.PlayerDamage.Internal = PNC.PlayerDamage.Internal or {}

local PlayerDamage = PNC.PlayerDamage
local Internal = PlayerDamage.Internal
local Runtime = Internal.Runtime
local Core = PNC.Core
local Const = PNC.Const
local Registry = PNC.Registry
local Network = PNC.Network
local Report = PlayerDamage.Report

local function isPlayer(character)
    if not character then
        return false
    end
    if instanceof then
        return instanceof(character, "IsoPlayer")
    end
    return character.getObjectName
        and tostring(character:getObjectName() or "") == "Player"
end

local function isLocalPlayer(character)
    local playerNum
    if not isPlayer(character) then
        return false
    end
    if character.isLocalPlayer then
        if character:isLocalPlayer() == true then
            return true
        end
    end
    if character.getPlayerNum and getSpecificPlayer then
        playerNum = character:getPlayerNum()
        return playerNum ~= nil and playerNum >= 0
            and getSpecificPlayer(playerNum) == character
    end
    return not (isClient and isClient())
end

local FRIENDLY_PUSH_REPORT_MS = 800
local friendlyPushReportAt = {}
local friendlyPushReportCount = 0

local function nowMs()
    if Core and Core.Now then
        return tonumber(Core.Now()) or 0
    end
    if getTimestampMs then
        return tonumber(getTimestampMs()) or 0
    end
    return 0
end

local function shouldSendFriendlyPushReport(npcID, attacker)
    if not npcID then
        return false
    end
    local attackerID = attacker and attacker.getOnlineID and attacker:getOnlineID()
        or attacker and attacker.getUsername and attacker:getUsername()
        or "local"
    local key = tostring(npcID) .. "|" .. tostring(attackerID)
    local now = nowMs()
    local last = friendlyPushReportAt[key]
    if last and now > 0 and (now - last) < FRIENDLY_PUSH_REPORT_MS then
        return false
    end
    if last == nil then
        friendlyPushReportCount = friendlyPushReportCount + 1
        if friendlyPushReportCount > 64 then
            friendlyPushReportAt = {}
            friendlyPushReportCount = 1
        end
    end
    friendlyPushReportAt[key] = now
    return true
end

local function isDedicatedServer()
    return isServer and isServer() and (not isClient or not isClient())
end

local function reportClientHit(attacker, target, weapon, damage, record, overrideDamage, isShove)
    local modData = Runtime.GetModData(target)
    local report
    local reason
    local effectiveDamage = overrideDamage ~= nil
        and (tonumber(overrideDamage) or 0)
        or (tonumber(damage) or 0)
    if not sendClientCommand or not modData or not modData.PNC_UUID then
        Internal.Audit(record, "client_request", "rejected",
            "request_unavailable",
            attacker and attacker.getOnlineID
                and attacker:getOnlineID() or nil,
            Runtime.GetFullType(weapon), effectiveDamage)
        return false, "request_unavailable"
    end
    report, reason = Report.Create({
        id = modData.PNC_UUID,
        attackerOnlineID = attacker.getOnlineID
            and attacker:getOnlineID() or nil,
        bodyOnlineID = Network and Network.GetZombieOnlineID
            and Network.GetZombieOnlineID(target) or nil,
        bodyInstanceID = target.getPersistentOutfitID
            and target:getPersistentOutfitID() or nil,
        bodyLease = modData.PNC_BodyLease,
        weaponFullType = Runtime.GetFullType(weapon),
        damage = effectiveDamage,
        isShove = isShove == true,
    })
    if not report then
        Internal.Audit(record, "client_request", "rejected", reason,
            attacker and attacker.getOnlineID
                and attacker:getOnlineID() or nil,
            Runtime.GetFullType(weapon), effectiveDamage)
        return false, reason
    end
    sendClientCommand(attacker, Const.MODULE,
        Const.CMD_PLAYER_WEAPON_HIT, report)
    Internal.Audit(record, "client_request", "sent", "report_sent",
        report.attackerOnlineID, report.weaponFullType, report.damage)
    return true
end

local function onWeaponHitCharacter(attacker, target, weapon, damage)
    local modData
    local record
    local applied
    local reason
    local isShove
    if not target or not isPlayer(attacker) then
        return
    end
    modData = Runtime.GetModData(target)
    if not modData or modData.PNC_NPC ~= true or not modData.PNC_UUID then
        return
    end
    isShove = Runtime.IsShove and Runtime.IsShove(attacker, weapon, damage) == true or false
    if Core.IsClientOnly and Core.IsClientOnly() then
        if isLocalPlayer(attacker) then
            record = Registry.Get(modData.PNC_UUID)
            if PlayerDamage.IsFriendlyOwner(record, attacker) then
                if PNC.LiveBodyControl and PNC.LiveBodyControl.RecoverGroundedBody then
                    PNC.LiveBodyControl.RecoverGroundedBody(
                        record,
                        target,
                        "friendly_owner_hit_local"
                    )
                end
                Runtime.RestoreEngineBuffer(target, record)
                if sendClientCommand and shouldSendFriendlyPushReport(modData.PNC_UUID, attacker) then
                    reportClientHit(attacker, target, weapon, damage, record, 0, isShove)
                end
                Internal.Audit(record, "client_request", "suppressed",
                    "friendly_owner_hit",
                    attacker.getOnlineID and attacker:getOnlineID() or nil,
                    Runtime.GetFullType(weapon), damage)
                return
            end
            reportClientHit(attacker, target, weapon, damage, record, nil, isShove)
            Runtime.RestoreEngineBuffer(target, nil)
        end
        return
    end
    if isDedicatedServer() or not isLocalPlayer(attacker) then
        return
    end
    record = Registry.Get(modData.PNC_UUID)
    applied, reason = PlayerDamage.Apply(
        record, target, attacker, weapon, damage, "player_weapon_event",
        { isShove = isShove })
    Internal.Audit(record, "local_application",
        applied and "applied" or "rejected", reason,
        attacker.getOnlineID and attacker:getOnlineID() or nil,
        Runtime.GetFullType(weapon), damage)
end

if Events and Events.OnWeaponHitCharacter
    and not PlayerDamage.WeaponHitHookRegistered
then
    Events.OnWeaponHitCharacter.Add(onWeaponHitCharacter)
    PlayerDamage.WeaponHitHookRegistered = true
end
