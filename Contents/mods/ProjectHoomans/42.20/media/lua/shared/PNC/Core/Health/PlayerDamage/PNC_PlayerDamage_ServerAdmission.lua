-- Server-side admission for compact player-hit reports.

PNC = PNC or {}
PNC.PlayerDamage = PNC.PlayerDamage or {}
PNC.PlayerDamage.Internal = PNC.PlayerDamage.Internal or {}
PNC.PlayerDamage.LastReportAt = PNC.PlayerDamage.LastReportAt or {}

local PlayerDamage = PNC.PlayerDamage
local Internal = PlayerDamage.Internal
local Runtime = Internal.Runtime
local Core = PNC.Core
local Const = PNC.Const
local Registry = PNC.Registry
local Network = PNC.Network
local Report = PlayerDamage.Report

local function resolveHeldWeapon(player, reportedFullType)
    local primary = player and player.getPrimaryHandItem
        and player:getPrimaryHandItem() or nil
    local secondary = player and player.getSecondaryHandItem
        and player:getSecondaryHandItem() or nil
    reportedFullType = tostring(reportedFullType or "")
    if reportedFullType == "" then
        return primary or secondary
    end
    if Runtime.GetFullType(primary) == reportedFullType then
        return primary
    end
    if Runtime.GetFullType(secondary) == reportedFullType then
        return secondary
    end
    return nil
end

local function playerKey(player)
    local onlineID = player and player.getOnlineID
        and player:getOnlineID() or nil
    return tostring(onlineID ~= nil and onlineID or player)
end

local function reject(record, player, report, reason)
    Internal.Audit(record, "server_admission", "rejected", reason,
        playerKey(player), report and report.weaponFullType,
        report and report.damage)
    return false, reason
end

function PlayerDamage.HandleClientReport(player, args)
    local report
    local reason
    local record
    local zombie
    local modData
    local weapon
    local currentOnlineID
    local currentInstanceID
    local distance
    local maxRange
    local attackerKey
    local accepted
    local now
    if not Core or type(Core.IsAuthority) ~= "function"
        or not Core.IsAuthority()
    then
        return false, "not_authority"
    end
    if not player or type(args) ~= "table" or args.id == nil then
        return false, "invalid_report"
    end
    report, reason = Report.Normalize(args)
    if not report then
        return false, reason
    end
    if report.attackerOnlineID ~= nil
        and player.getOnlineID
        and tonumber(player:getOnlineID()) ~= report.attackerOnlineID
    then
        return reject(nil, player, report, "attacker_mismatch")
    end
    record = Registry.Get(report.id)
    zombie = record and Registry.GetLiveZombie(record.id) or nil
    if not record or not zombie
        or record.presenceState ~= Const.PRESENCE_LIVE
    then
        return reject(record, player, report, "target_unavailable")
    end
    modData = Runtime.GetModData(zombie)
    if not modData or modData.PNC_NPC ~= true
        or tostring(modData.PNC_UUID or "") ~= tostring(record.id)
    then
        return reject(record, player, report, "body_mismatch")
    end
    currentOnlineID = Network and Network.GetZombieOnlineID
        and Network.GetZombieOnlineID(zombie) or nil
    if report.bodyOnlineID ~= nil and currentOnlineID ~= nil
        and report.bodyOnlineID ~= tonumber(currentOnlineID)
    then
        return reject(record, player, report, "online_id_mismatch")
    end
    currentInstanceID = zombie.getPersistentOutfitID
        and zombie:getPersistentOutfitID() or nil
    if report.bodyInstanceID ~= nil and currentInstanceID ~= nil
        and report.bodyInstanceID ~= tostring(currentInstanceID)
    then
        return reject(record, player, report, "instance_id_mismatch")
    end
    if report.bodyLease ~= nil and modData.PNC_BodyLease ~= nil
        and report.bodyLease ~= tostring(modData.PNC_BodyLease)
    then
        return reject(record, player, report, "body_lease_mismatch")
    end
    weapon = resolveHeldWeapon(player, report.weaponFullType)
    if report.weaponFullType ~= "" and not weapon then
        return reject(record, player, report, "weapon_mismatch")
    end
    distance = Core.Distance(
        player:getX(), player:getY(), zombie:getX(), zombie:getY())
    maxRange = Runtime.IsRangedWeapon(weapon)
        and (tonumber(Const.PLAYER_HIT_RANGED_RANGE) or 20)
        or (tonumber(Const.PLAYER_HIT_MELEE_RANGE) or 3)
    if distance > maxRange or player:getZ() ~= zombie:getZ() then
        return reject(record, player, report, "out_of_range")
    end
    now = Core.Now()
    attackerKey = playerKey(player)
    accepted, reason = Internal.AdmitReportKey(
        attackerKey,
        attackerKey .. ":" .. tostring(record.id),
        now
    )
    if not accepted then
        return reject(record, player, report, reason)
    end
    local applied
    applied, reason = PlayerDamage.Apply(
        record, zombie, player, weapon, report.damage,
        "player_weapon_report")
    Internal.Audit(record, "server_admission",
        applied and "applied" or "rejected", reason,
        attackerKey, report.weaponFullType, report.damage)
    return applied, reason
end
