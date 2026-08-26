--[[
    PNC Relationships Facade
    Personal relationships remain directed. Organizational faction war and
    looter policy now take precedence over the tactical classification.
]]

PNC = PNC or {}
PNC.Relationships = PNC.Relationships or {}

local Relationships = PNC.Relationships
local Core = PNC.Core
local Const = PNC.Const
local Types = PNC.Types

local function factionOf(value)
    return Types.NormalizeFaction(type(value) == "table" and value.faction or value)
end

function Relationships.AreNPCsEnemies(source, target)
    local sourceFaction
    local targetFaction
    local factions = PNC.Factions
    local sourceOrganization
    local targetOrganization
    local sourceDefinition
    local targetDefinition
    if not source or not target or tostring(source.id or "") == tostring(target.id or "") then
        return false
    end
    if source.hostility and source.hostility.attackNPCs == false then
        return false
    end
    sourceOrganization = factions
        and factions.GetFactionID
        and factions.GetFactionID(source)
        or source.affiliation and source.affiliation.factionID
    targetOrganization = factions
        and factions.GetFactionID
        and factions.GetFactionID(target)
        or target.affiliation and target.affiliation.factionID
    if PNC.FactionBehavior
        and PNC.FactionBehavior.ResolveIntent
        and sourceOrganization
    then
        local intent = PNC.FactionBehavior.ResolveIntent(
            source,
            target,
            {}
        )
        return intent and intent.attackAllowed == true
    end
    if sourceOrganization and targetOrganization then
        if sourceOrganization == targetOrganization then
            return false
        end
        if factions and factions.AreAtWar
            and factions.AreAtWar(
                sourceOrganization,
                targetOrganization
            )
        then
            return true
        end
        return false
    end
    if sourceOrganization and not targetOrganization then
        return factionOf(target) == Const.FACTION_HOSTILE
    end
    if targetOrganization and not sourceOrganization then
        return factionOf(source) == Const.FACTION_HOSTILE
    end
    sourceFaction = factionOf(source)
    targetFaction = factionOf(target)
    if sourceFaction == Const.FACTION_HOSTILE then
        return targetFaction ~= Const.FACTION_HOSTILE
    end
    return targetFaction == Const.FACTION_HOSTILE
end

function Relationships.SetFaction(record, faction, reason)
    local normalized
    local previous
    local OrderSystem
    local Registry
    if not record or record.alive == false then
        return false, "invalid_record"
    end
    normalized = Types.NormalizeFaction(faction)
    previous = factionOf(record)
    if previous == normalized then
        return false, "unchanged"
    end

    record.faction = normalized
    record.hostility = Types.DefaultHostility(normalized)
    record.runtime = record.runtime or {}
    record.runtime.target = nil
    record.runtime.attackAction = nil
    record.runtime.lastPathX = nil
    record.runtime.lastPathY = nil
    record.runtime.factionChangedReason = tostring(reason or "relationship")
    record.runtime.factionChangedAt = Core.Now()
    record.nextThinkAt = Core.Now()
    record.activeJob = nil
    record.activeBehavior = nil

    if normalized == Const.FACTION_HOSTILE then
        record.recruited = false
        record.ownerUsername = nil
        record.ownerOnlineID = nil
        OrderSystem = PNC.OrderSystem
        if OrderSystem and OrderSystem.SetOrder then
            OrderSystem.SetOrder(record, {
                kind = Const.ORDER_HOSTILE_HUNT,
                x = record.x,
                y = record.y,
                z = record.z,
            })
        else
            record.orderSpec = { kind = Const.ORDER_HOSTILE_HUNT }
        end
    end

    if PNC.SimulationClock and PNC.SimulationClock.Wake then
        PNC.SimulationClock.Wake(record, nil, Core.Now())
    end
    if PNC.Scheduler and PNC.Scheduler.Schedule then
        PNC.Scheduler.Schedule(
            record,
            Core.Now() + (tonumber(PNC.Scheduler.SLOT_MS) or 50)
        )
    end

    Registry = PNC.Registry
    if Registry and Registry.MarkDirty then
        Registry.MarkDirty(record, "faction")
        Registry.MarkDirty(record, "hostility")
    end
    if Core and Core.LogInfo then
        Core.LogInfo("PNC faction transition id=" .. tostring(record.id)
            .. " from=" .. tostring(previous)
            .. " to=" .. tostring(normalized)
            .. " reason=" .. tostring(reason or "relationship"))
    end
    return true, "changed"
end

function Relationships.ProvokeNeutralByPlayer(record)
    if factionOf(record) ~= Const.FACTION_NEUTRAL then
        return false, "not_neutral"
    end
    return Relationships.SetFaction(record, Const.FACTION_HOSTILE, "attacked_by_player")
end

return Relationships
