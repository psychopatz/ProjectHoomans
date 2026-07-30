-- Server-authoritative bridge from organizational factions to existing
-- companion/combat fields. Persistent faction identity remains canonical;
-- legacy tactical fields are derived compatibility state.

if isClient and isClient() and (not isServer or not isServer()) then
    return
end

PNC = PNC or {}
PNC.FactionBehavior = PNC.FactionBehavior or {}

local Behavior = PNC.FactionBehavior
local Factions = PNC.Factions
local Archetypes = PNC.FactionArchetypes
local EntityRef = PNC.EntityRef
local Types = PNC.Types
local Const = PNC.Const
local Core = PNC.Core

local function same(left, right)
    return PNC.FactionTypes.AreEqual(left, right)
end

local function ownerIdentity(faction)
    local parsed = faction and faction.ownerPlayerKey
        and EntityRef.Parse(faction.ownerPlayerKey) or nil
    local player = parsed
        and PNC.PlayerCharacters
        and PNC.PlayerCharacters.RuntimeByUUID
        and PNC.PlayerCharacters.RuntimeByUUID[
            parsed.characterUUID
        ] or nil
    return parsed, player
end

local function factionHasPlayerMembers(faction)
    return faction ~= nil
        and next(faction.playerMemberKeys or {}) ~= nil
end

local function factionAtWarWithPlayerFaction(factionID)
    local relation
    local otherID
    local other
    for _, relation in pairs(
        Factions.Registry.diplomacy or {}
    ) do
        if relation.state == "war"
            and (relation.factionAID == factionID
                or relation.factionBID == factionID)
        then
            otherID = relation.factionAID == factionID
                and relation.factionBID
                or relation.factionAID
            other = Factions.Registry.byID[otherID]
            if factionHasPlayerMembers(other) then
                return true
            end
        end
    end
    return false
end

local function assign(record, key, value)
    if record[key] == value then return false end
    record[key] = value
    return true
end

local function clearCombatRuntime(record)
    record.runtime = record.runtime or {}
    record.runtime.target = nil
    record.runtime.attackAction = nil
    record.runtime.lastPathX = nil
    record.runtime.lastPathY = nil
    record.runtime.followState = nil
    record.nextThinkAt = Core.Now()
end

local function desiredOrder(record, mode, owner)
    if mode == "player_owned" then
        return {
            kind = Const.ORDER_FOLLOW,
            ownerUsername = owner.username,
            ownerOnlineID = owner.onlineID,
        }
    end
    if mode == "aggressive" then
        return {
            kind = Const.ORDER_HOSTILE_HUNT,
            x = record.x,
            y = record.y,
            z = record.z,
        }
    end
    return {
        kind = Const.ORDER_ROAM,
        roamMode = Const.ROAM_MODE_AREA,
        x = record.x,
        y = record.y,
        z = record.z,
        radius = Const.ROAM_DEFAULT_RADIUS,
    }
end

local function apply(record, mode, owner, reason)
    local changed = false
    local faction
    local hostility
    local order
    if not record or record.alive == false then
        return false, "invalid_record"
    end
    if mode == "player_owned" then
        faction = Const.FACTION_COLONIST
        hostility = Types.DefaultHostility(faction)
        changed = assign(record, "recruited", true) or changed
        changed = assign(
            record,
            "ownerUsername",
            owner.username
        ) or changed
        changed = assign(
            record,
            "ownerOnlineID",
            owner.onlineID
        ) or changed
    elseif mode == "aggressive" then
        faction = Const.FACTION_HOSTILE
        hostility = {
            mode = "faction_war",
            attackPlayers = owner.attackPlayers == true,
            attackNPCs = true,
            attackZombies = true,
        }
        changed = assign(record, "recruited", false) or changed
        changed = assign(record, "ownerUsername", nil) or changed
        changed = assign(record, "ownerOnlineID", nil) or changed
    else
        faction = Const.FACTION_NEUTRAL
        hostility = Types.DefaultHostility(faction)
        changed = assign(record, "recruited", false) or changed
        changed = assign(record, "ownerUsername", nil) or changed
        changed = assign(record, "ownerOnlineID", nil) or changed
    end
    changed = assign(record, "faction", faction) or changed
    if not same(record.hostility, hostility) then
        record.hostility = hostility
        changed = true
    end
    order = desiredOrder(record, mode, owner)
    if not same(record.orderSpec, order) then
        if PNC.OrderSystem and PNC.OrderSystem.SetOrder then
            PNC.OrderSystem.SetOrder(record, order)
        else
            record.orderSpec = order
        end
        changed = true
    end
    if not changed then return false, "unchanged" end
    clearCombatRuntime(record)
    record.runtime.factionBehaviorReason =
        tostring(reason or "faction_policy")
    record.runtime.factionBehaviorAt = Core.Now()
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "faction_behavior")
    end
    if PNC.SimulationClock and PNC.SimulationClock.Wake then
        PNC.SimulationClock.Wake(record, nil, Core.Now())
    end
    return true, "applied"
end

function Behavior.ApplyNPC(record, reason)
    local factionID = Factions.GetOrganizationalFactionID(record)
    local faction = factionID
        and Factions.Registry.byID[factionID] or nil
    local parsed
    local livePlayer
    local owner
    local aggressive
    if not faction then
        return Behavior.ApplyUnaffiliated(record, reason)
    end
    if faction.ownerPlayerKey then
        parsed, livePlayer = ownerIdentity(faction)
        owner = {
            username = livePlayer and parsed
                and parsed.accountIdentity or nil,
            onlineID = livePlayer
                and livePlayer.getOnlineID
                and livePlayer:getOnlineID() or nil,
        }
        return apply(record, "player_owned", owner, reason)
    end
    aggressive = Archetypes.IsHostileToOutsiders(
        faction.archetypeID
    ) or Factions.IsFactionAtWar(factionID)
    return apply(
        record,
        aggressive and "aggressive" or "neutral",
        {
            attackPlayers =
                Archetypes.IsHostileToOutsiders(
                    faction.archetypeID
                )
                or factionAtWarWithPlayerFaction(factionID),
        },
        reason
    )
end

function Behavior.ApplyUnaffiliated(record, reason)
    return apply(record, "neutral", {}, reason)
end

function Behavior.ReconcileFaction(factionID, reason)
    local faction = Factions.Registry.byID[factionID]
    local changed = 0
    if not faction then return 0 end
    for npcID, _ in pairs(faction.memberIDs or {}) do
        local record = PNC.Registry.Get(npcID)
        if record and Behavior.ApplyNPC(record, reason) then
            changed = changed + 1
        end
    end
    return changed
end

function Behavior.ReconcileAll(reason)
    local changed = 0
    for factionID, _ in pairs(Factions.Registry.byID or {}) do
        changed = changed
            + Behavior.ReconcileFaction(factionID, reason)
    end
    return changed
end

return Behavior
