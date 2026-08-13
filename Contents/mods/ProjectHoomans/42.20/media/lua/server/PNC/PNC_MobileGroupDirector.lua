-- Server-authoritative mobile faction generation and abstract relocation.
--
-- Mobile looter groups, trading caravans, and refugee groups are not Communities: they do not
-- reserve sites, claim homes, or create a base radius. Their faction carries
-- one primitive staging site so abstract members can relocate together.

if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then
    return
end

PNC = PNC or {}
PNC.MobileGroupDirector = PNC.MobileGroupDirector or {}

local Director = PNC.MobileGroupDirector
local Constants = PNC.FactionConstants
local CommunityConstants = PNC.CommunityConstants
local Factions = PNC.Factions
local Resolver = PNC.CommunitySiteResolver
local Core = PNC.Core
local Const = PNC.Const

Director.LastPumpAt = Director.LastPumpAt or nil

local PUMP_INTERVAL_MS = 5000

local ROLE_ORDER = {
    looter = {
        "leader", "raider", "enforcer", "scavenger",
        "guard", "medic",
    },
    trader = {
        "leader", "trader", "guard", "medic",
        "mechanic", "scavenger", "laborer",
    },
    refugee = {
        "leader", "medic", "guard", "caregiver",
        "scavenger",
    },
}

local function authority()
    return Core and Core.IsAuthority
        and Core.IsAuthority() == true
end

local function copy(value)
    return Core and Core.DeepCopy and Core.DeepCopy(value) or value
end

local function worldAge(value)
    value = tonumber(value)
    if value and value == value
        and value ~= math.huge and value ~= -math.huge
    then
        return math.max(0, value)
    end
    local gameTime = getGameTime and getGameTime() or nil
    return gameTime and gameTime.getWorldAgeHours
        and math.max(
            0,
            tonumber(gameTime:getWorldAgeHours()) or 0
        ) or 0
end

local function groupSize(value)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        value = CommunityConstants.GROUP_SIZE_DEFAULT
    end
    return math.max(
        CommunityConstants.GROUP_SIZE_MIN,
        math.min(
            CommunityConstants.GROUP_SIZE_MAX,
            math.floor(value)
        )
    )
end

local function presenceMode(value)
    return CommunityConstants.VALID_GROUP_PRESENCE_MODES[value]
        and value or "auto"
end

local function pathMode(value, fallback)
    if Constants.VALID_MOBILE_PATH_MODES[value] then
        return value
    end
    if Constants.VALID_MOBILE_PATH_MODES[fallback] then
        return fallback
    end
    return Constants.MOBILE_PATH_RANDOM
end

local function factionRole(faction, index)
    local roles = ROLE_ORDER[faction.archetypeID] or {}
    return roles[index]
        or PNC.FactionArchetypes.GetDefaultRole(
            faction.archetypeID
        )
end

local function npcArchetype(faction)
    return faction.archetypeID == "looter"
        and "Scavenger" or "General"
end

local function mobileOrder(faction, mobile, site)
    local home = site and site.home or {}
    local mode = pathMode(mobile and mobile.pathMode)
    if faction.archetypeID == "looter" then
        if mode == Constants.MOBILE_PATH_PLAYER then
            return {
                kind = Const.ORDER_HOSTILE_HUNT,
                x = home.x,
                y = home.y,
                z = home.z,
            }
        end
        return {
            kind = Const.ORDER_HOSTILE_ROAM,
            roamMode = Const.ROAM_MODE_AREA,
            x = home.x,
            y = home.y,
            z = home.z,
            radius = home.radius,
            targetRadius = Const.ROAM_TARGET_RADIUS,
        }
    end
    return {
        kind = Const.ORDER_ROAM,
        roamMode = mode == Constants.MOBILE_PATH_PLAYER
            and Const.ROAM_MODE_PLAYER
            or Const.ROAM_MODE_AREA,
        x = home.x,
        y = home.y,
        z = home.z,
        radius = home.radius,
    }
end

local function currentSite(faction)
    return faction and faction.mobile
        and copy(faction.mobile.site) or nil
end

local function targetPlayerSite(spec, at)
    local target = Core and Core.GetNearestPlayerPosition
        and Core.GetNearestPlayerPosition(
            tonumber(spec.x) or 0,
            tonumber(spec.y) or 0
        ) or nil
    if not target then return nil, "no_online_player" end
    return Resolver.FindAvailableNear(
        target.x,
        target.y,
        target.z,
        {
            createdAt = at,
            searchRadius = spec.searchRadius,
        }
    )
end

local function resolveSite(faction, spec, at, forceNew)
    local mobile = faction and faction.mobile or nil
    local mode = pathMode(
        spec.mobilePathMode,
        mobile and mobile.pathMode
    )
    if type(spec.siteSpec) == "table" then
        local explicit = copy(spec.siteSpec)
        if not PNC.CommunityTypes.IsValidSiteID(explicit.id) then
            explicit.id = PNC.Communities.BuildSiteID(explicit)
        end
        explicit = PNC.CommunityTypes.NormalizeSite(explicit, explicit.id)
        if explicit then return explicit, "explicit_bounded_site" end
        return nil, "invalid_explicit_site"
    end
    if forceNew ~= true and spec.useExisting ~= false then
        local existing = currentSite(faction)
        if existing then return existing, "existing_mobile_site" end
    end
    if mode == Constants.MOBILE_PATH_PLAYER then
        local site, reason = targetPlayerSite(spec, at)
        if site then return site, reason end
    end
    return Resolver.FindRandomHouse({
        z = spec.z,
        createdAt = at,
        randomIndex = spec.randomHouseIndex,
    })
end

local function factionMembersAreAbstract(faction)
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

local function setRecordAtSite(record, point, site, faction, mobile)
    local order = mobileOrder(faction, mobile, site)
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

local function activeMembers(faction)
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

local function buildMobileState(site, mode, at, previous, moved)
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

function Director.GenerateForFaction(factionID, spec)
    if not authority() then return false, "not_authority" end
    spec = type(spec) == "table" and spec or {}
    local faction = Factions.Get(factionID)
    if not faction then return false, "faction_not_found" end
    if faction.status ~= "active" then
        return false, "faction_not_active"
    end
    if faction.archetypeID ~= "looter"
        and faction.archetypeID ~= "trader"
        and faction.archetypeID ~= "refugee"
    then
        return false, "mobile_archetype_not_allowed"
    end
    local at = worldAge(spec.worldAgeHours)
    local mode = pathMode(
        spec.mobilePathMode,
        faction.mobile and faction.mobile.pathMode
    )
    local site, siteReason = resolveSite(
        faction,
        spec,
        at,
        false
    )
    if not site then return false, siteReason end
    local count = groupSize(spec.groupSize)
    local requestedPresence = presenceMode(spec.presenceMode)
    local siteLoaded = Resolver.IsSiteLoaded(site)
    local requestLive = requestedPresence == "live"
        or requestedPresence == "auto" and siteLoaded
            and spec.allowLive ~= false
    local points = Resolver.FindSpawnPoints(site, count)
    local created = {}
    local liveCount = 0
    local abstractCount = 0
    local index
    for index = 1, count do
        local point = points[index]
        local record = PNC.API.Spawn({
            faction = "neutral",
            archetypeID = npcArchetype(faction),
            x = point.x,
            y = point.y,
            z = point.z,
            anchorX = site.home.x,
            anchorY = site.home.y,
            anchorZ = site.home.z,
            orderSpec = mobileOrder(faction, {
                pathMode = mode,
            }, site),
            forceLive = requestLive and siteLoaded,
            equipmentSpawnMode = faction.archetypeID == "looter"
                and "both" or nil,
            organizationalFactionID = faction.id,
            membershipStatus = "member",
            factionRole = factionRole(faction, index),
            factionJoinedAt = at,
            debug = spec.debug == true,
            generation = spec.generation,
        })
        if not record then
            for _, prior in ipairs(created) do
                if PNC.Factions and PNC.Factions.RemoveNPC then
                    PNC.Factions.RemoveNPC(
                        faction.id,
                        prior.id,
                        "group_generation_rollback",
                        at
                    )
                end
                if PNC.API and PNC.API.Despawn then
                    PNC.API.Despawn(prior.id)
                end
            end
            return false, "npc_spawn_failed"
        end
        if requestedPresence == "abstract" then
            record.runtime.forceAbstract = true
            if record.presenceState == Const.PRESENCE_LIVE
                and PNC.Presence and PNC.Presence.Abstract
            then
                PNC.Presence.Abstract(
                    record,
                    "mobile_director_force_abstract"
                )
            end
        end
        if record.presenceState == Const.PRESENCE_LIVE then
            liveCount = liveCount + 1
        else
            abstractCount = abstractCount + 1
        end
        created[#created + 1] = record
    end
    local previous = faction.mobile
    local state = buildMobileState(
        site,
        mode,
        at,
        previous,
        previous ~= nil
    )
    local ok, reason, mobile = Factions.SetMobileGroup(
        faction.id,
        state,
        "mobile_group_generated"
    )
    if not ok then
        for _, prior in ipairs(created) do
            if PNC.Factions and PNC.Factions.RemoveNPC then
                PNC.Factions.RemoveNPC(faction.id, prior.id,
                    "group_generation_rollback", at)
            end
            if PNC.API and PNC.API.Despawn then PNC.API.Despawn(prior.id) end
        end
        return false, reason
    end
    if not faction.leaderNPCID and created[1] then
        Factions.SetLeader(faction.id, created[1].id, at)
    end
    if PNC.AbstractGroups and PNC.AbstractGroups.ImportMobileFaction then
        PNC.AbstractGroups.ImportMobileFaction(Factions.Get(faction.id))
    end
    local ids = {}
    for _, record in ipairs(created) do
        ids[#ids + 1] = record.id
    end
    return true, "mobile_group_generated", {
        factionID = faction.id,
        mobile = mobile,
        siteID = site.id,
        siteKind = site.kind,
        siteLoaded = siteLoaded,
        siteSelectionReason = siteReason,
        presenceMode = requestedPresence,
        pathMode = mode,
        requestedCount = count,
        createdCount = #ids,
        liveCount = liveCount,
        abstractCount = abstractCount,
        npcIDs = ids,
    }
end

function Director.RelocateFaction(factionID, at, force)
    if not authority() then return false, "not_authority" end
    local faction = Factions.Get(factionID)
    if not faction then return false, "faction_not_found" end
    if not Factions.IsMobileGroup(faction) then
        return false, "not_mobile_group"
    end
    local mobile = faction.mobile
    at = worldAge(at)
    if force ~= true and at < (tonumber(mobile.nextMoveAt) or 0) then
        return false, "not_due"
    end
    local abstract, abstractReason = factionMembersAreAbstract(faction)
    if not abstract then return false, abstractReason end
    local site, siteReason = resolveSite(
        faction,
        {
            x = mobile.site.home.x,
            y = mobile.site.home.y,
            z = mobile.site.home.z,
            mobilePathMode = mobile.pathMode,
            randomHouseIndex = (tonumber(mobile.relocationCount) or 0) + 2,
        },
        at,
        true
    )
    if not site then return false, siteReason end
    local members = activeMembers(faction)
    local points = Resolver.FindSpawnPoints(site, #members)
    local nextState = buildMobileState(
        site,
        mobile.pathMode,
        at,
        mobile,
        true
    )
    local index
    for index = 1, #members do
        setRecordAtSite(
            members[index],
            points[index],
            site,
            faction,
            nextState
        )
    end
    local ok, reason, value = Factions.SetMobileGroup(
        faction.id,
        nextState,
        "mobile_group_relocated"
    )
    if not ok then return false, reason end
    return true, "mobile_group_relocated", value
end

function Director.SetPathMode(factionID, mode)
    mode = pathMode(mode)
    return Factions.UpdateMobileGroup(
        factionID,
        { pathMode = mode },
        "mobile_group_path_mode"
    )
end

function Director.Pump(now)
    now = tonumber(now) or (Core.Now and Core.Now()) or 0
    if Director.LastPumpAt
        and now - Director.LastPumpAt < PUMP_INTERVAL_MS
    then
        return 0
    end
    Director.LastPumpAt = now
    local at = worldAge()
    local factionIDs = {}
    for factionID, faction in pairs(
        Factions.Registry and Factions.Registry.byID or {}
    ) do
        local strategicallyOwned = PNC.AbstractGroups
            and PNC.AbstractGroups.FindByFactionID
            and PNC.AbstractGroups.FindByFactionID(factionID) ~= nil
        if not strategicallyOwned and faction.status == "active"
            and Factions.IsMobileGroup(faction)
            and at >= (tonumber(faction.mobile.nextMoveAt) or 0)
        then
            factionIDs[#factionIDs + 1] = factionID
        end
    end
    table.sort(factionIDs)
    local moved = 0
    for _, factionID in ipairs(factionIDs) do
        local ok = Director.RelocateFaction(factionID, at, false)
        if ok then moved = moved + 1 end
    end
    return moved
end

return Director
