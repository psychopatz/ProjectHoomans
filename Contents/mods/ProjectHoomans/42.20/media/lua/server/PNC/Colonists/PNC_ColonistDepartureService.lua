-- Authoritative relationship-triggered colonist departure.
-- This is deliberately separate from FollowerAbandonment: that service
-- records combat-range exits, while this service changes faction identity.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.ColonistDeparture = PNC.ColonistDeparture or {}

local Service = PNC.ColonistDeparture
local Core = PNC.Core
local Const = PNC.Const
local FactionConstants = PNC.FactionConstants
local Factions = PNC.Factions
local Registry = PNC.Registry
local Relationships = PNC.Relationships
local Graph = PNC.RelationshipGraph
local Policy = PNC.ColonistDeparturePolicy
local EntityRef = PNC.EntityRef
local PlayerCharacters = PNC.PlayerCharacters
local Mobile = PNC.MobileGroupDirector
local MobileInternal = PNC.MobileGroupDirectorInternal
local Resolver = PNC.CommunitySiteResolver

Service.PUMP_INTERVAL_HOURS = 1
Service.DEFAULT_PUMP_BUDGET = 8
Service.MANUAL_PENALTY_APPROVAL = -50
Service.MANUAL_PENALTY_RESPECT = -50

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return tonumber(fallback) or 0
    end
    return value
end

local function worldAge(value)
    value = tonumber(value)
    if value and value == value
        and value ~= math.huge and value ~= -math.huge
    then
        return math.max(0, value)
    end
    local time = getGameTime and getGameTime() or nil
    return time and time.getWorldAgeHours
        and math.max(0, tonumber(time:getWorldAgeHours()) or 0) or 0
end

local function markDirty(record, reason)
    if Registry and Registry.MarkDirty then
        Registry.MarkDirty(record, reason or "colonist_departure")
    end
end

local function log(message)
    if Core and Core.LogInfo then
        Core.LogInfo("[PNC ColonistDeparture] " .. tostring(message))
    end
end

local function playerKeyFor(player, at)
    local key
    local ok
    if not player then return nil end
    if PlayerCharacters and PlayerCharacters.GetEntityKey then
        ok, key = pcall(
            PlayerCharacters.GetEntityKey,
            player,
            { callback = "colonist_departure", worldAgeHours = at }
        )
        if ok and key and tostring(key) ~= "" then
            return tostring(key)
        end
    end
    local internal = Factions and Factions.Internal
    if internal and internal.playerKeyFor then
        ok, key = pcall(
            internal.playerKeyFor,
            player,
            "colonist_departure",
            false
        )
        if ok and key and tostring(key) ~= "" then
            return tostring(key)
        end
    end
    return nil
end

local function relationshipFor(record, playerKey)
    if not Relationships or not Relationships.Get then return nil end
    return Relationships.Get(record.id, playerKey)
end

function Service.Evaluate(record, relationship, context)
    if not Policy or not Policy.Evaluate then return nil end
    local personality = Graph and Graph.ResolveNPCPersonality
        and Graph.ResolveNPCPersonality(record) or {}
    return Policy.Evaluate(
        relationship and relationship.approval,
        relationship and relationship.respect,
        personality,
        context
    )
end

function Service.GetPreview(record, relationship)
    local evaluation = Service.Evaluate(record, relationship)
    return Policy and Policy.CopyPreview
        and Policy.CopyPreview(evaluation) or evaluation
end

local function sourceFaction(record)
    local factionID = record and record.affiliation
        and record.affiliation.factionID or nil
    local faction = factionID and Factions and Factions.Get
        and Factions.Get(factionID) or nil
    if not faction or Factions.IsMobileGroup(faction) then
        return nil, "not_player_colonist"
    end
    if not faction.ownerPlayerKey
        or not EntityRef or not EntityRef.IsPlayer
        or not EntityRef.IsPlayer(faction.ownerPlayerKey)
    then
        return nil, "not_player_faction"
    end
    return faction
end

function Service.CanPlayerManage(player, record, suppliedKey)
    if not record or record.alive == false then
        return false, "npc_not_found"
    end
    if record.recruited ~= true then return false, "npc_not_recruited" end
    local at = worldAge()
    local key = suppliedKey or playerKeyFor(player, at)
    if not key then return false, "player_identity_unavailable" end
    local faction, factionReason = sourceFaction(record)
    if not faction then return false, factionReason end
    if faction.ownerPlayerKey ~= key then
        return false, "not_colonist_owner"
    end
    return true, nil, key, faction
end

local function fallbackSite(record, at)
    local x = finite(record and record.x, 0)
    local y = finite(record and record.y, 0)
    local z = finite(record and record.z, 0)
    local site = {
        kind = "radius",
        home = { x = x, y = y, z = z, radius = 12 },
        bounds = {
            minX = x - 12, minY = y - 12,
            maxX = x + 12, maxY = y + 12,
            minZ = z, maxZ = z,
        },
        createdAt = at,
    }
    if PNC.Communities and PNC.Communities.BuildSiteID then
        site.id = PNC.Communities.BuildSiteID(site)
    else
        site.id = "community_site_radius_" .. tostring(math.floor(x))
            .. "_" .. tostring(math.floor(y))
    end
    return PNC.CommunityTypes and PNC.CommunityTypes.NormalizeSite
        and PNC.CommunityTypes.NormalizeSite(site, site.id) or site
end

local function departureSite(record, at)
    local site
    if Resolver and Resolver.FindAvailableNear then
        site = Resolver.FindAvailableNear(
            finite(record and record.x, 0),
            finite(record and record.y, 0),
            finite(record and record.z, 0),
            { createdAt = at, searchRadius = 80 }
        )
    end
    if site then return site end
    if Resolver and Resolver.FindRandomHouse then
        site = Resolver.FindRandomHouse({
            z = finite(record and record.z, 0),
            createdAt = at,
        })
    end
    return site or fallbackSite(record, at)
end

local function buildMobileState(site, at)
    if MobileInternal and MobileInternal.BuildMobileState then
        return MobileInternal.BuildMobileState(
            site,
            FactionConstants.MOBILE_PATH_RANDOM,
            at,
            nil,
            false,
            FactionConstants.MOBILE_CONTROL_AMBIENT
        )
    end
    return {
        active = true,
        pathMode = FactionConstants.MOBILE_PATH_RANDOM,
        controlMode = FactionConstants.MOBILE_CONTROL_AMBIENT,
        activity = FactionConstants.MOBILE_ACTIVITY_STREET_ROAMING,
        site = site,
        lastMovedAt = at,
        nextMoveAt = at + 24,
        relocationHours = 24,
        relocationCount = 0,
        lastDepartureAt = -1,
        revision = 1,
    }
end

local function applyManualPenalty(record, playerKey, sourceFactionID, at)
    local before = relationshipFor(record, playerKey)
    local eventID = "conversation:colonist_expelled:" .. tostring(record.id)
        .. ":" .. tostring(sourceFactionID or "unknown")
    if not Relationships or not Relationships.ApplyConversationEffect then
        return false, "relationship_service_unavailable"
    end
    local ok, reason, details = Relationships.ApplyConversationEffect(
        record.id,
        playerKey,
        {
            approval = Service.MANUAL_PENALTY_APPROVAL,
            respect = Service.MANUAL_PENALTY_RESPECT,
            permanent = true,
            decayPerDay = 0,
            memoryType = "colonist_expelled",
            interactionType = "colonist_expelled",
            tags = { colonistDeparture = true, manual = true },
        },
        {
            eventID = eventID,
            blockID = "projecthoomans:colonist_departure",
            choiceID = "disband_confirm",
            outcomeID = "expelled",
            worldAgeHours = at,
            sourceSystem = "colonist_departure",
            interaction = {
                kind = "colonist_departure",
                source = "colonist_departure",
                interactionType = "colonist_expelled",
                choiceID = "disband_confirm",
                applied = true,
            },
        }
    )
    if not ok and reason ~= "duplicate_event" then
        return false, reason or "relationship_penalty_failed"
    end
    local after = details and details.relationship
        or relationshipFor(record, playerKey)
    return true, reason or "penalty_applied", {
        before = before,
        after = after,
        delta = {
            approval = finite(after and after.approval, 0)
                - finite(before and before.approval, 0),
            respect = finite(after and after.respect, 0)
                - finite(before and before.respect, 0),
        },
        eventID = eventID,
    }
end

local function completeMarker(record, options, sourceFactionID,
    destinationFactionID, at, evaluation)
    record.colonistDeparture = {
        state = "completed",
        eventID = tostring(options.eventID),
        ownerKey = options.ownerKey,
        sourceFactionID = sourceFactionID,
        destinationFactionID = destinationFactionID,
        cause = options.cause,
        belowThresholdChecks = tonumber(
            options.belowThresholdChecks
        ) or 0,
        firstDetectedAt = tonumber(options.firstDetectedAt) or at,
        lastEvaluatedAt = at,
        completedAt = at,
        approvalThreshold = evaluation and evaluation.approvalThreshold,
        respectThreshold = evaluation and evaluation.respectThreshold,
    }
    markDirty(record, "colonist_departure_complete")
end

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

local function markPending(record, source, ownerKey, at, evaluation)
    local marker = record.colonistDeparture
    if type(marker) ~= "table" or marker.state == "completed" then
        marker = {
            state = "pending",
            eventID = "colonist_departure:" .. tostring(record.id),
            ownerKey = ownerKey,
            sourceFactionID = source.id,
            belowThresholdChecks = 0,
            firstDetectedAt = at,
            lastEvaluatedAt = 0,
        }
    end
    if at - finite(marker.lastEvaluatedAt, 0)
        < Service.PUMP_INTERVAL_HOURS
        and finite(marker.lastEvaluatedAt, 0) > 0
    then
        return marker, false
    end
    marker.state = "pending"
    marker.ownerKey = ownerKey
    marker.sourceFactionID = source.id
    marker.belowThresholdChecks = math.min(
        8, math.max(0, math.floor(finite(
            marker.belowThresholdChecks, 0
        ))) + 1
    )
    marker.firstDetectedAt = finite(marker.firstDetectedAt, at)
    marker.lastEvaluatedAt = at
    marker.approvalThreshold = evaluation.approvalThreshold
    marker.respectThreshold = evaluation.respectThreshold
    record.colonistDeparture = marker
    markDirty(record, "colonist_departure_threshold")
    return marker, true
end

function Service.Pump(at, budget)
    if not Core or not Core.IsAuthority or Core.IsAuthority() ~= true then
        return 0
    end
    at = worldAge(at)
    budget = math.max(1, math.floor(tonumber(budget)
        or Service.DEFAULT_PUMP_BUDGET))
    if Service.LastPumpAt
        and at - Service.LastPumpAt < Service.PUMP_INTERVAL_HOURS
    then
        return 0
    end
    Service.LastPumpAt = at
    if Registry and Registry.EnsureLoaded then Registry.EnsureLoaded() end
    local departures = 0
    for _, record in pairs(Registry and Registry.Data or {}) do
        if departures >= budget then break end
        if record and record.alive ~= false and record.recruited == true
            and record.affiliation and record.affiliation.factionID
        then
            local source = sourceFaction(record)
            if source then
                local ownerKey = source.ownerPlayerKey
                local relationship = relationshipFor(record, ownerKey)
                local evaluation = Service.Evaluate(record, relationship)
                if evaluation and evaluation.eligible then
                    local marker, changed = markPending(
                        record, source, ownerKey, at, evaluation
                    )
                    if changed and marker.belowThresholdChecks
                        >= evaluation.confirmationChecks
                    then
                        local ok = Service.Depart(record, "automatic", {
                            ownerKey = ownerKey,
                            worldAgeHours = at,
                            evaluation = evaluation,
                        })
                        if ok then departures = departures + 1 end
                    end
                elseif record.colonistDeparture
                    and record.colonistDeparture.state == "pending"
                    and evaluation and evaluation.recoverable
                then
                    record.colonistDeparture = nil
                    markDirty(record, "colonist_departure_recovered")
                end
            end
        end
    end
    return departures
end

return Service
