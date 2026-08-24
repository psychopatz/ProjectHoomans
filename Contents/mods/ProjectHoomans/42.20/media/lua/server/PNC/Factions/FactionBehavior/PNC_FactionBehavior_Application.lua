if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FactionBehavior = PNC.FactionBehavior or {}
PNC.FactionBehavior.Internal = PNC.FactionBehavior.Internal or {}

local Behavior = PNC.FactionBehavior
local Internal = Behavior.Internal
local Factions = PNC.Factions
local Archetypes = PNC.FactionArchetypes
local EntityRef = PNC.EntityRef
local Types = PNC.Types
local Const = PNC.Const
local Core = PNC.Core
local same = Internal.same
local ownerIdentity = Internal.ownerIdentity
local factionAtWarWithPlayerFaction = Internal.factionAtWarWithPlayerFaction
local playerEntityKey = Internal.playerEntityKey
local assign = Internal.assign
local clearCombatRuntime = Internal.clearCombatRuntime
local desiredOrder = Internal.desiredOrder

local function apply(record, mode, owner, reason, faction)
    local changed = false
    local legacyFaction
    local hostility
    local order
    local preservePlayerOrder
    local recordOwnerUsername
    local ownerUsername
    local recordOwnerOnlineID
    local ownerOnlineID
    if not record or record.alive == false then
        return false, "invalid_record"
    end
    recordOwnerUsername = tostring(record.ownerUsername or "")
    ownerUsername = tostring(owner and owner.username or "")
    recordOwnerOnlineID = tonumber(record.ownerOnlineID)
    ownerOnlineID = tonumber(owner and owner.onlineID)
    preservePlayerOrder = mode == "player_owned"
        and record.recruited == true
        and (
            recordOwnerUsername ~= ""
                and recordOwnerUsername == ownerUsername
            or recordOwnerOnlineID ~= nil
                and ownerOnlineID ~= nil
                and recordOwnerOnlineID == ownerOnlineID
        )
    if mode == "player_owned" then
        legacyFaction = Const.FACTION_COLONIST
        hostility = Types.DefaultHostility(legacyFaction)
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
        legacyFaction = Const.FACTION_HOSTILE
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
        legacyFaction = Const.FACTION_NEUTRAL
        hostility = Types.DefaultHostility(legacyFaction)
        changed = assign(record, "recruited", false) or changed
        changed = assign(record, "ownerUsername", nil) or changed
        changed = assign(record, "ownerOnlineID", nil) or changed
    end
    changed = assign(record, "faction", legacyFaction) or changed
    if not same(record.hostility, hostility) then
        record.hostility = hostility
        changed = true
    end
    order = desiredOrder(
        record,
        mode,
        owner,
        faction,
        preservePlayerOrder
    )
    if not same(record.orderSpec, order) then
        if PNC.OrderSystem and PNC.OrderSystem.SetOrder then
            PNC.OrderSystem.SetOrder(record, order)
        else
            record.orderSpec = order
        end
        changed = true
    end
    if not changed then return false, "unchanged" end
    local runtimeTarget = record.runtime
        and record.runtime.target or nil
    if not runtimeTarget or runtimeTarget.kind ~= "zombie" then
        clearCombatRuntime(record)
    end
    record.runtime = record.runtime or {}
    record.runtime.factionBehaviorReason =
        tostring(reason or "faction_policy")
    record.runtime.factionBehaviorAt = Core.Now()
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "faction_behavior")
    end
    if PNC.Network and PNC.Network.BroadcastRecord then
        PNC.Network.BroadcastRecord(
            record,
            tostring(reason or "faction_behavior")
        )
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
            -- The faction key is durable, while RuntimeByUUID is populated
            -- only after the player joins.  Startup reconciliation must use
            -- the persisted account identity or it will mistake every
            -- offline-owned companion for an unbound recruit and replace
            -- saved orders (including colony_home) with Follow.
            username = parsed and parsed.accountIdentity or nil,
            onlineID = livePlayer
                and livePlayer.getOnlineID
                and livePlayer:getOnlineID() or nil,
        }
        return apply(record, "player_owned", owner, reason, faction)
    end
    local territorialToll =
        Factions.IsTerritorialTollFaction(faction)
    aggressive = (
        faction.archetypeID == "looter"
            and not territorialToll
        )
        or Archetypes.IsHostileToOutsiders(
            faction.archetypeID
        )
        or Factions.IsFactionAtWar(factionID)
    return apply(
        record,
        aggressive and "aggressive" or "neutral",
        {
            attackPlayers =
                faction.archetypeID == "looter"
                    and not territorialToll
                or Archetypes.IsHostileToOutsiders(
                    faction.archetypeID
                )
                or factionAtWarWithPlayerFaction(factionID),
        },
        reason,
        faction
    )
end

function Behavior.ReconcilePlayerPacification(
    factionID,
    playerKey,
    reason
)
    local faction = Factions.Registry.byID[factionID]
    local cleared = 0
    if not faction or not EntityRef.IsPlayer(playerKey) then
        return 0
    end
    for npcID, _ in pairs(faction.memberIDs or {}) do
        local record = PNC.Registry.Get(npcID)
        local target = record and record.runtime
            and record.runtime.target or nil
        local targetKey = target
            and target.kind == "player"
            and target.player
            and playerEntityKey(target.player) or nil
        if targetKey == playerKey then
            clearCombatRuntime(record)
            record.runtime.factionBehaviorReason =
                tostring(reason or "player_pacified")
            if PNC.SimulationClock
                and PNC.SimulationClock.Wake
            then
                PNC.SimulationClock.Wake(
                    record,
                    nil,
                    Core.Now()
                )
            end
            cleared = cleared + 1
        end
    end
    return cleared
end

function Behavior.ApplyUnaffiliated(record, reason)
    return apply(record, "neutral", {}, reason, nil)
end
