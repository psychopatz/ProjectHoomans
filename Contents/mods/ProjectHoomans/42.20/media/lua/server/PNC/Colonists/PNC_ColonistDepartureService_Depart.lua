if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.ColonistDeparture = PNC.ColonistDeparture or {}

local Service = PNC.ColonistDeparture
local Internal = Service.Internal or {}
Service.Internal = Internal
local Core = PNC.Core
local Const = PNC.Const
local FactionConstants = PNC.FactionConstants
local Factions = PNC.Factions
local MobileInternal = PNC.MobileGroupDirectorInternal
local AbstractGroups = PNC.AbstractGroups
local worldAge = Internal.WorldAge
local relationshipFor = Internal.RelationshipFor
local sourceFaction = Internal.SourceFaction
local departureSite = Internal.DepartureSite
local buildMobileState = Internal.BuildMobileState
local applyManualPenalty = Internal.ApplyManualPenalty
local completeMarker = Internal.CompleteMarker
local markDirty = Internal.MarkDirty
local log = Internal.Log

-- Converts the existing NPC into a one-member refugee mobile faction. The
-- record stays at its current position; the first road target is an order or
-- abstract traversal objective, so live NPCs are not teleported out of view.
function Service.Depart(record, cause, options)
    if not Core or not Core.IsAuthority or Core.IsAuthority() ~= true then
        return false, "not_authority"
    end
    options = type(options) == "table" and options or {}
    cause = cause == "manual" and "manual" or "automatic"
    local ok, reason, ownerKey, source = Service.CanPlayerManage(
        options.player,
        record,
        options.ownerKey
    )
    if cause == "automatic" then
        source, reason = sourceFaction(record)
        ownerKey = options.ownerKey or source and source.ownerPlayerKey
        ok = source ~= nil and record and record.recruited == true
    end
    if not ok or not source then return false, reason or "not_player_colonist" end
    local at = worldAge(options.worldAgeHours)
    local existing = record.colonistDeparture
    if existing and existing.state == "completed"
        and existing.destinationFactionID
    then
        return true, "already_departed", {
            factionID = existing.destinationFactionID,
        }
    end
    local evaluation = options.evaluation
        or Service.Evaluate(record, relationshipFor(record, ownerKey))
    local penalty
    if cause == "manual" then
        ok, reason, penalty = applyManualPenalty(
            record, ownerKey, source.id, at
        )
        if not ok then return false, reason end
    end
    local site = departureSite(record, at)
    if not site then return false, "departure_site_unavailable" end
    local name = string.sub(
        tostring(record.name or record.id or "Colonist") .. "'s Exiles",
        1,
        FactionConstants.NAME_MAX_LENGTH
    )
    local created, createReason, mobileFaction = Factions.Create({
        name = name,
        archetypeID = "refugee",
        createdAt = at,
        tags = {
            mobileGroup = true,
            colonistDeparture = true,
            departureCause = cause,
            originFactionID = source.id,
            originPlayerKey = ownerKey,
        },
    })
    if not created or not mobileFaction then
        return false, createReason or "departure_faction_create_failed"
    end
    local leaveReason = cause == "manual"
        and "colonist_expelled" or "colonist_abandoned"
    ok, reason = Factions.TransferNPC(record.id, mobileFaction.id, {
        role = "leader",
        rank = "leader",
        membershipStatus = "member",
        worldAgeHours = at,
        leaveReason = leaveReason,
    })
    if not ok then return false, reason or "departure_transfer_failed" end
    Factions.SetLeader(mobileFaction.id, record.id, at)

    local mobileState = buildMobileState(site, at)
    ok, reason = Factions.SetMobileGroup(
        mobileFaction.id,
        mobileState,
        "colonist_departure_mobile_group"
    )
    if not ok then
        -- The transfer has already made the faction membership safe. Leave the
        -- new faction recoverable for a later repair instead of risking an
        -- unaffiliated NPC during a partial engine/API failure.
        log("mobile initialization deferred npc=" .. tostring(record.id)
            .. " reason=" .. tostring(reason or "unknown"))
    end

    record.recruited = false
    record.tacticalClass = Const.TACTICAL_CLASS_NEUTRAL or "neutral"
    record.ownerUsername = nil
    record.ownerOnlineID = nil
    record.runtime = record.runtime or {}
    record.runtime.colonistDeparture = nil
    record.activeJob = nil
    record.activeBehavior = nil

    local current = Factions.Get(mobileFaction.id)
    local roadTarget
    if current and Factions.IsMobileGroup(current)
        and MobileInternal and MobileInternal.FindRoadTarget
    then
        roadTarget = MobileInternal.FindRoadTarget(current)
        if roadTarget then
            local phase = MobileInternal.AmbientPhase
                and MobileInternal.AmbientPhase(at)
                or FactionConstants.MOBILE_AMBIENT_DAY
            Factions.UpdateMobileGroup(mobileFaction.id, {
                ambient = {
                    phase = phase,
                    objective = FactionConstants.MOBILE_AMBIENT_ROAD,
                    target = roadTarget,
                    nextCheckAt = at + 1,
                    nextObjectiveAt = at + 6,
                    retryAt = 0,
                    revision = 1,
                },
            }, "colonist_departure_road_target")
            current = Factions.Get(mobileFaction.id)
        end
    end
    if current and MobileInternal and MobileInternal.RepairMobileOrders then
        MobileInternal.RepairMobileOrders(current)
    end
    local group
    local importReason
    if current and PNC.AbstractGroups
        and PNC.AbstractGroups.ImportMobileFaction
    then
        group, importReason = PNC.AbstractGroups.ImportMobileFaction(current)
        if roadTarget and MobileInternal.SyncAbstractObjective then
            MobileInternal.SyncAbstractObjective(
                current,
                FactionConstants.MOBILE_AMBIENT_ROAD,
                roadTarget,
                at
            )
        end
    end
    completeMarker(
        record,
        {
            eventID = "colonist_departure:" .. tostring(record.id),
            ownerKey = ownerKey,
            cause = cause,
            belowThresholdChecks = existing
                and existing.belowThresholdChecks or 0,
            firstDetectedAt = existing and existing.firstDetectedAt or at,
        },
        source.id,
        mobileFaction.id,
        at,
        evaluation
    )
    markDirty(record, "colonist_departure_ownership_clear")
    if PNC.Network and PNC.Network.BroadcastRecord then
        PNC.Network.BroadcastRecord(record, "colonist_departure")
    end
    log("departed npc=" .. tostring(record.id)
        .. " source=" .. tostring(source.id)
        .. " destination=" .. tostring(mobileFaction.id)
        .. " cause=" .. cause)
    return true, "colonist_departed", {
        npcID = record.id,
        factionID = mobileFaction.id,
        sourceFactionID = source.id,
        groupID = group and group.id or nil,
        groupReason = importReason,
        mobile = current and current.mobile or nil,
        roadTarget = roadTarget,
        penalty = penalty,
    }
end

return Service
