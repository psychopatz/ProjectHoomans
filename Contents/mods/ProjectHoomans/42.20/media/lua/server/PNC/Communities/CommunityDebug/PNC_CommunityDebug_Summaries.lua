if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CommunityDebug = PNC.CommunityDebug or {}
PNC.CommunityDebugInternal = PNC.CommunityDebugInternal or {}

local Debug = PNC.CommunityDebug
local H = PNC.CommunityDebugInternal
local Communities = PNC.Communities
local CommunityMath = PNC.CommunityMath
local Constants = PNC.CommunityConstants
local Core = PNC.Core

local function mobileSummary(faction)
    local mobile = faction and faction.mobile or nil
    if not mobile or mobile.active ~= true then return nil end
    local ambient = mobile.ambient or {}
    local target = mobile.controlMode == "strategic"
        and mobile.strategicTarget or ambient.target
    return {
        active = true,
        archetypeID = faction.archetypeID,
        controlMode = mobile.controlMode,
        pathMode = mobile.pathMode,
        phase = ambient.phase,
        objective = ambient.objective,
        target = H.Copy(target),
        siteID = mobile.site and mobile.site.id or nil,
        siteKind = mobile.site and mobile.site.kind or nil,
        nextMoveAt = mobile.nextMoveAt,
        nextObjectiveAt = ambient.nextObjectiveAt,
        revision = mobile.revision,
    }
end

function H.FactionSummary(faction)
    return {
        id = faction.id,
        name = faction.name,
        archetypeID = faction.archetypeID,
        status = faction.status,
        mobile = mobileSummary(faction),
    }
end

function H.NPCSummary(record)
    local affiliation = PNC.FactionTypes.NormalizeAffiliation(
        record.affiliation
    )
    local community = affiliation.communityID
        and Communities.Get(affiliation.communityID) or nil
    local distance = community
        and CommunityMath.GetDistanceFromHome(
            community,
            record.x,
            record.y,
            record.z
        ) or nil
    return {
        id = record.id,
        name = tostring(record.name or record.id),
        alive = record.alive ~= false,
        x = tonumber(record.x) or 0,
        y = tonumber(record.y) or 0,
        z = tonumber(record.z) or 0,
        factionID = affiliation.factionID,
        factionRole = affiliation.role,
        communityID = affiliation.communityID,
        communityName = community and community.name or nil,
        communityRole = affiliation.communityRole,
        communityJoinedAt = affiliation.communityJoinedAt,
        affiliationRevision = affiliation.revision,
        insideHome = community and
            CommunityMath.IsInsideHomeArea(
                community,
                record.x,
                record.y,
                record.z
            ) or false,
        distanceFromHome = distance,
        recordRevision = record.recordRevision,
        presenceRevision = record.presenceRevision,
    }
end

function H.SelectedMembers(community)
    local output = {}
    if not community then return output end
    for npcID, present in pairs(community.memberIDs or {}) do
        local record = present == true
            and PNC.Registry.Get(npcID) or nil
        if record then
            output[#output + 1] = H.NPCSummary(record)
        end
    end
    table.sort(output, function(left, right)
        return left.name < right.name
    end)
    return output
end

return Debug
