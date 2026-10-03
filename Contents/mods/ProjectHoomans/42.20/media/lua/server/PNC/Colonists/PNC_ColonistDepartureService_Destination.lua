if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.ColonistDeparture = PNC.ColonistDeparture or {}

local Service = PNC.ColonistDeparture
local Internal = Service.Internal or {}
Service.Internal = Internal
local FactionConstants = PNC.FactionConstants
local Factions = PNC.Factions
local Relationships = PNC.Relationships
local MobileInternal = PNC.MobileGroupDirectorInternal
local Resolver = PNC.CommunitySiteResolver
local finite = Internal.Finite
local relationshipFor = Internal.RelationshipFor
local markDirty = Internal.MarkDirty

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

Internal.DepartureSite = departureSite
Internal.BuildMobileState = buildMobileState
Internal.ApplyManualPenalty = applyManualPenalty
Internal.CompleteMarker = completeMarker

return Service
