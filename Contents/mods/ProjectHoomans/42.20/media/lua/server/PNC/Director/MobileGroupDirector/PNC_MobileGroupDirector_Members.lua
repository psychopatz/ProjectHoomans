if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.MobileGroupDirector = PNC.MobileGroupDirector or {}
PNC.MobileGroupDirectorInternal = PNC.MobileGroupDirectorInternal or {}

local Director = PNC.MobileGroupDirector
local H = PNC.MobileGroupDirectorInternal
local Constants = PNC.FactionConstants
local CommunityConstants = PNC.CommunityConstants
local Factions = PNC.Factions
local Resolver = PNC.CommunitySiteResolver
local Core = PNC.Core
local Const = PNC.Const

function H.FactionMembersAreAbstract(faction)
    local hasMember = false
    for npcID, _ in pairs(faction.memberIDs or {}) do
        local record = PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(npcID) or nil
        if record and record.alive ~= false then
            hasMember = true
            local live = PNC.Registry.GetLiveZombie
                and PNC.Registry.GetLiveZombie(record.id) or nil
            if live or record.presenceState == Const.PRESENCE_LIVE then
                return false, "mobile_group_live"
            end
        end
    end
    return hasMember, hasMember and "abstract" or "no_members"
end

function H.SetRecordAtSite(record, point, site, faction, mobile)
    local order = H.MobileOrder(faction, mobile, site)
    record.x = point.x
    record.y = point.y
    record.z = point.z
    record.anchorX = site.home.x
    record.anchorY = site.home.y
    record.anchorZ = site.home.z
    record.runtime = record.runtime or {}
    record.runtime.target = nil
    record.runtime.attackAction = nil
    record.runtime.roaming = nil
    if PNC.OrderSystem and PNC.OrderSystem.SetOrder then
        PNC.OrderSystem.SetOrder(record, order)
    else
        record.orderSpec = order
    end
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "mobile_group_relocation")
    end
    if PNC.Network and PNC.Network.BroadcastRecord then
        PNC.Network.BroadcastRecord(record, "mobile_group_relocation")
    end
end

function H.ActiveMembers(faction)
    local output = {}
    for npcID, _ in pairs(faction.memberIDs or {}) do
        local record = PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(npcID) or nil
        if record and record.alive ~= false then
            output[#output + 1] = record
        end
    end
    table.sort(output, function(left, right)
        return tostring(left.id) < tostring(right.id)
    end)
    return output
end

function H.BuildMobileState(site, mode, at, previous, moved)
    local interval = tonumber(previous and previous.relocationHours)
        or Constants.MOBILE_GROUP_RELOCATION_HOURS
    local relocationCount = tonumber(previous
        and previous.relocationCount) or 0
    local revision = tonumber(previous and previous.revision) or 0
    if moved == true then relocationCount = relocationCount + 1 end
    return {
        active = true,
        pathMode = mode,
        site = site,
        lastMovedAt = at,
        nextMoveAt = at + interval,
        relocationHours = interval,
        relocationCount = relocationCount,
        revision = revision + 1,
    }
end
