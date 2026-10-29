-- Generic community-role whereabouts fact provider.
--
-- This provider is intentionally role-agnostic. A speaker's faction and the
-- participant role identify the subject; Project Hoomans owns the excursion,
-- community, privacy, and place projections. Semantic realization owns the
-- wording. Dynamic Trading's trader is only the first role consumer.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Service = PNC.Semantics.CognitionService
local Factions = PNC.Factions
local Excursions = PNC.CommunityExcursionService
local Place = PNC.CommunityPlaceProjection
    or require "PNC/Communities/PNC_CommunityPlaceProjection"

local Whereabouts = PNC.Semantics.CommunityRoleWhereabouts or {}
PNC.Semantics.CommunityRoleWhereabouts = Whereabouts

Whereabouts.VERSION = 1
Whereabouts.SUBJECT = "COMMUNITY_ROLE_WHEREABOUTS"
Whereabouts.MAX_ROLE_LENGTH = 48

local function worldAge()
    local gameTime = getGameTime and getGameTime() or nil
    if gameTime and type(gameTime.getWorldAgeHours) == "function" then
        return math.max(0, tonumber(gameTime:getWorldAgeHours()) or 0)
    end
    return 0
end

local function safeRole(value)
    value = string.lower(tostring(value or ""))
    value = string.gsub(value, "[^%w_%-]", "")
    if value == "" then return nil end
    return string.sub(value, 1, Whereabouts.MAX_ROLE_LENGTH)
end

local function participantContains(excursion, npcID)
    local participants = excursion and excursion.participants or nil
    local index
    if type(participants) ~= "table" then return false end
    for index = 1, math.min(#participants, 24) do
        if tostring(participants[index]) == tostring(npcID) then
            return true
        end
    end
    return false
end

local function roleMember(factionID, role)
    local members
    local index
    local member
    local affiliation
    if not Factions or type(Factions.GetMembers) ~= "function" then
        return nil, "faction_members_unavailable"
    end
    members = Factions.GetMembers(factionID)
    for index = 1, math.min(#(type(members) == "table" and members or {}), 64) do
        member = members[index]
        affiliation = member and member.affiliation or nil
        if member and member.alive ~= false
            and affiliation
            and safeRole(affiliation.role or affiliation.communityRole)
                == role
        then
            return member, nil
        end
    end
    return nil, "role_member_not_found"
end

local function statusFor(factionID, member, viewer)
    local excursion
    local status
    local reason
    if not Excursions then return nil, "excursion_service_unavailable" end
    excursion = type(Excursions.Get) == "function"
        and Excursions.Get(factionID) or nil
    if not excursion then
        return {
            status = "home",
            phase = "AT_HOME",
            state = "AT_HOME",
            locationState = "home",
            destinationKnown = false,
            expectedReturnKnown = false,
            homeCommunityID = member.affiliation
                and member.affiliation.communityID or nil,
        }
    end
    if not participantContains(excursion, member.npcID) then
        return {
            status = "home",
            phase = "AT_HOME",
            state = "AT_HOME",
            locationState = "home",
            destinationKnown = false,
            expectedReturnKnown = false,
            homeCommunityID = excursion.homeCommunityID,
            revision = excursion.revision,
        }
    end
    status, reason = Excursions.GetSocialStatus(factionID, viewer)
    if not status then return nil, reason or "social_status_unavailable" end
    return status
end

local function destinationProjection(status, homeCommunityID)
    local destinationID = status and status.destinationCommunityID
    local destination
    local related
    if not status or status.destinationKnown ~= true or not destinationID then
        return {}
    end
    related = Place.Relate(homeCommunityID, destinationID, {
        sameAreaThreshold = 1,
        distanceBands = {
            { max = 100, token = "nearby" },
            { max = 500, token = "not_far" },
            { max = 2000, token = "far" },
        },
    })
    destination = related and related.destination or nil
    -- An internal ID is useful for the authoritative lookup but is never
    -- emitted without a trustworthy current display name.
    if not destination or not destination.name then return {} end
    return {
        destinationCommunityID = destination.communityID,
        destinationName = destination.name,
        direction8 = related.direction8,
        directionLabel = related.directionLabel,
        distanceBand = related.distanceBand,
    }
end

function Whereabouts.BuildFact(factionID, role, viewer, options)
    local member
    local status
    local reason
    local homeCommunityID
    local value
    local destination
    role = safeRole(role)
    factionID = tostring(factionID or "")
    if factionID == "" or not role then
        return nil, "role_identity_required"
    end
    member, reason = roleMember(factionID, role)
    if not member then return nil, reason end
    homeCommunityID = member.affiliation
        and member.affiliation.communityID or nil
    if not homeCommunityID or homeCommunityID == "" then
        return {
            status = "unknown",
            targetID = role,
            reason = "home_community_unavailable",
        }
    end
    status, reason = statusFor(factionID, member, viewer)
    if not status then return nil, reason end
    value = {
        role = role,
        roleLabel = role,
        status = status.status,
        phase = status.phase,
        state = status.state,
        locationState = status.locationState,
        publicReason = status.reason or status.publicReason,
        destinationKnown = status.destinationKnown == true,
        expectedReturnKnown = status.expectedReturnKnown == true,
        revision = status.revision,
    }
    destination = destinationProjection(status, homeCommunityID)
    for key, item in pairs(destination) do value[key] = item end
    if value.expectedReturnKnown and status.expectedReturnAt ~= nil then
        value.expectedReturnAt = tonumber(status.expectedReturnAt)
    end
    return {
        subject = Whereabouts.SUBJECT,
        targetID = tostring(options and options.targetID or role),
        targetName = "the " .. role,
        status = "known",
        value = value,
        source = "community_excursion",
        sourceID = factionID,
        factRef = "community.excursion.role_whereabouts",
        observedAt = worldAge(),
        expiresAt = worldAge() + 1,
        confidence = 0.96,
    }
end

local function resolve(record, _player, options)
    local affiliation = record and record.affiliation or nil
    local factionID = affiliation and affiliation.factionID or nil
    local role = options and (options.role or options.targetID) or nil
    local viewer = options and options.viewer
    if not factionID or not role then return nil, "speaker_faction_or_role_missing" end
    viewer = type(viewer) == "table" and viewer or {
        factionID = factionID,
        homeFactionID = factionID,
    }
    return Whereabouts.BuildFact(factionID, role, viewer, options)
end

Whereabouts.Resolve = resolve

if Service and type(Service.RegisterLiveFactProvider) == "function" then
    Service.RegisterLiveFactProvider("community_role_whereabouts", {
        priority = 210,
        subjects = { [Whereabouts.SUBJECT] = true },
        Resolve = resolve,
    })
end

return Whereabouts
