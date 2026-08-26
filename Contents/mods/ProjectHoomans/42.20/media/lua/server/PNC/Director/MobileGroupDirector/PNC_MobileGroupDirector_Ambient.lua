if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.MobileGroupDirector = PNC.MobileGroupDirector or {}
PNC.MobileGroupDirectorInternal = PNC.MobileGroupDirectorInternal or {}

local Director = PNC.MobileGroupDirector
local H = PNC.MobileGroupDirectorInternal
local Constants = PNC.FactionConstants
local Factions = PNC.Factions
local Resolver = PNC.CommunitySiteResolver
local Core = PNC.Core
local Const = PNC.Const
local Zones = require "PsychopatzCore/World/PC_ZoneRegistry"
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return fallback
    end
    return value
end

local function rectangleRegion(bounds)
    local helper = PNC.BaseValidationService
        and PNC.BaseValidationService.Internal
        and PNC.BaseValidationService.Internal.RectangleRegion
    if helper then
        return helper(
            bounds.minX,
            bounds.minY,
            bounds.maxX,
            bounds.maxY,
            bounds.minZ,
            bounds.maxZ
        )
    end
    local region = { levels = {} }
    local minZ = math.floor(finite(bounds.minZ, 0))
    local maxZ = math.floor(finite(bounds.maxZ, minZ))
    local z
    for z = minZ, maxZ do
        local rows = {}
        local y
        for y = math.floor(finite(bounds.minY, 0)),
            math.floor(finite(bounds.maxY, bounds.minY or 0))
        do
            rows[y] = {
                math.floor(finite(bounds.minX, 0)),
                math.floor(finite(bounds.maxX, bounds.minX or 0)),
            }
        end
        region.levels[z] = { rows = rows }
    end
    return GridRegion.normalize(region)
end

local function safehouseValue(safehouse, method)
    if not safehouse or not safehouse[method] then return nil end
    local ok, value = pcall(safehouse[method], safehouse)
    return ok and finite(value, nil) or nil
end

local function loadSafehouses()
    local output = {}
    if not SafeHouse or not SafeHouse.getSafehouseList then
        return output
    end
    local ok, list = pcall(SafeHouse.getSafehouseList)
    if not ok or not list then return output end
    local count = list.size and list:size() or #list
    local index
    for index = 0, count - 1 do
        local safehouse = list.get
            and list:get(index) or list[index + 1]
        local x = safehouseValue(safehouse, "getX")
        local y = safehouseValue(safehouse, "getY")
        local width = safehouseValue(safehouse, "getW")
        local height = safehouseValue(safehouse, "getH")
        if x and y and width and height and width > 0 and height > 0 then
            output[#output + 1] = {
                minX = x,
                minY = y,
                maxX = x + width - 1,
                maxY = y + height - 1,
            }
        end
    end
    return output
end

function H.PlayerOwnershipSnapshot()
    local zones = Zones.export and Zones.export() or { byID = {} }
    local ownedZones = {}
    for _, zone in pairs(zones.byID or {}) do
        if zone.ownerType == "projecthoomans.base"
            or zone.ownerType == "projecthoomans.facility"
        then
            ownedZones[#ownedZones + 1] = zone
        end
    end
    return { zones = ownedZones, safehouses = loadSafehouses() }
end

local function boundsOverlap(left, right)
    return left.minX <= right.maxX and right.minX <= left.maxX
        and left.minY <= right.maxY and right.minY <= left.maxY
end

function H.IsPlayerOwnedShelterSite(site, snapshot)
    if type(site) ~= "table" or site.kind ~= "building" then
        return false
    end
    if site.claimantKey or site.status == "claimed"
        or site.occupantCommunityID
        or site.status == "occupied"
    then
        return true
    end
    local bounds = site.bounds
    if type(bounds) ~= "table" then return true end
    snapshot = snapshot or H.PlayerOwnershipSnapshot()
    local candidateRegion = rectangleRegion(bounds)
    for _, zone in ipairs(snapshot.zones or {}) do
        if zone.geometry and GridRegion.intersects(
            candidateRegion,
            zone.geometry
        ) then
            return true
        end
    end
    for _, safehouse in ipairs(snapshot.safehouses or {}) do
        if boundsOverlap(bounds, safehouse) then return true end
    end
    return false
end

function H.IsValidShelterSite(site, snapshot)
    if type(site) ~= "table" or site.kind ~= "building"
        or type(site.home) ~= "table"
        or type(site.bounds) ~= "table"
    then
        return false
    end
    if not Resolver or not Resolver.FindSpawnPoints then return false end
    return not H.IsPlayerOwnedShelterSite(site, snapshot)
        and site.status ~= "claimed"
        and site.status ~= "occupied"
end

function H.ShelterFilter(snapshot)
    snapshot = snapshot or H.PlayerOwnershipSnapshot()
    return function(site)
        return H.IsValidShelterSite(site, snapshot)
    end
end

function H.AmbientPhase(at)
    local hour = finite(at, 0) % 24
    if hour >= Constants.MOBILE_AMBIENT_DAY_START_HOUR
        and hour < Constants.MOBILE_AMBIENT_NIGHT_START_HOUR
    then
        return Constants.MOBILE_AMBIENT_DAY
    end
    return Constants.MOBILE_AMBIENT_NIGHT
end

local function chooseIndex(count)
    if count <= 1 then return 1 end
    if ZombRand then
        local ok, value = pcall(ZombRand, count)
        if ok and tonumber(value) then
            return (math.floor(value) % count) + 1
        end
    end
    return 1
end

local function targetFromSite(site)
    local points = Resolver.FindSpawnPoints(site, 1)
    local point = points[1] or site.home
    return {
        kind = "building",
        siteID = site.id,
        x = finite(point.x, site.home.x),
        y = finite(point.y, site.home.y),
        z = finite(point.z, site.home.z),
        radius = math.max(2, finite(site.home.radius, 8)),
        bounds = Core.DeepCopy(site.bounds),
    }
end

function H.FindShelterTarget(faction, at)
    local mobile = faction and faction.mobile or {}
    local site = mobile.site or {}
    local snapshot = H.PlayerOwnershipSnapshot()
    local filter = H.ShelterFilter(snapshot)
    local selected, reason = Resolver.FindRandomHouse({
        z = site.home and site.home.z or 0,
        createdAt = at,
        randomIndex = (tonumber(mobile.relocationCount) or 0) + 1,
        siteFilter = filter,
    })
    if not selected then
        selected, reason = Resolver.FindAvailableNear(
            site.home and site.home.x or 0,
            site.home and site.home.y or 0,
            site.home and site.home.z or 0,
            {
                createdAt = at,
                searchRadius = Constants.MOBILE_AMBIENT_SHELTER_SEARCH_RADIUS,
                siteFilter = filter,
            }
        )
    end
    if not selected or not H.IsValidShelterSite(selected, snapshot) then
        return nil, reason or "no_valid_shelter"
    end
    return targetFromSite(selected), "shelter_selected"
end

local function invoke(object, method, ...)
    if not object or not object[method] then return nil end
    local ok, value = pcall(object[method], object, ...)
    return ok and value or nil
end

function H.FindRoadTarget(faction)
    local mobile = faction and faction.mobile or {}
    local origin = mobile.site and mobile.site.home or {}
    local world = getWorld and getWorld() or nil
    local metaGrid = invoke(world, "getMetaGrid")
    local list = ArrayList and ArrayList.new and ArrayList.new() or nil
    if not metaGrid or not list or not metaGrid.getZonesIntersecting then
        return nil, "nav_api_unavailable"
    end
    local radius = Constants.MOBILE_AMBIENT_ROAD_SEARCH_RADIUS
    local x = math.floor(finite(origin.x, 0) - radius)
    local y = math.floor(finite(origin.y, 0) - radius)
    local width = math.floor(radius * 2)
    local z = math.floor(finite(origin.z, 0))
    local ok = pcall(
        metaGrid.getZonesIntersecting,
        metaGrid,
        x, y, z, width, width, list
    )
    if not ok then return nil, "nav_query_failed" end
    local candidates = {}
    local count = list.size and list:size() or #list
    local index
    for index = 0, count - 1 do
        local zone = list.get and list:get(index) or list[index + 1]
        local zoneType = invoke(zone, "getType")
        local zoneX = finite(invoke(zone, "getX"), nil)
        local zoneY = finite(invoke(zone, "getY"), nil)
        local zoneWidth = finite(invoke(zone, "getWidth"), nil)
        local zoneHeight = finite(invoke(zone, "getHeight"), nil)
        if tostring(zoneType or "") == "Nav"
            and zoneX and zoneY and zoneWidth and zoneHeight
            and zoneWidth > 0 and zoneHeight > 0
        then
            candidates[#candidates + 1] = {
                minX = zoneX,
                minY = zoneY,
                maxX = zoneX + zoneWidth - 1,
                maxY = zoneY + zoneHeight - 1,
                z = z,
            }
        end
    end
    if #candidates == 0 then return nil, "no_nav_zone" end
    local bounds = candidates[chooseIndex(#candidates)]
    return {
        kind = "nav",
        x = (bounds.minX + bounds.maxX) / 2,
        y = (bounds.minY + bounds.maxY) / 2,
        z = bounds.z,
        radius = math.max(4, math.min(
            80,
            math.sqrt(
                ((bounds.maxX - bounds.minX) / 2) ^ 2
                    + ((bounds.maxY - bounds.minY) / 2) ^ 2
            )
        )),
        bounds = bounds,
    }, "nav_selected"
end

local function sameTarget(left, right)
    if not left or not right then return left == right end
    return left.kind == right.kind
        and left.siteID == right.siteID
        and left.baseID == right.baseID
        and math.abs(finite(left.x, 0) - finite(right.x, 0)) < 0.1
        and math.abs(finite(left.y, 0) - finite(right.y, 0)) < 0.1
        and math.abs(finite(left.z, 0) - finite(right.z, 0)) < 0.1
end

local function sameOrder(left, right)
    if not left or not right then return left == right end
    if left.kind ~= right.kind or left.roamMode ~= right.roamMode then
        return false
    end
    return math.abs(finite(left.x, 0) - finite(right.x, 0)) < 0.1
        and math.abs(finite(left.y, 0) - finite(right.y, 0)) < 0.1
        and math.abs(finite(left.z, 0) - finite(right.z, 0)) < 0.1
        and left.shelterSiteID == right.shelterSiteID
end

function H.AmbientOrder(faction, mobile, site)
    local ambient = mobile and mobile.ambient or nil
    local target = ambient and ambient.target or nil
    if mobile and mobile.controlMode == Constants.MOBILE_CONTROL_STRATEGIC
        and mobile.strategicTarget
    then
        target = mobile.strategicTarget
    end
    if not target then return nil end
    local home = site and site.home or {}
    if mobile.controlMode == Constants.MOBILE_CONTROL_AMBIENT
        and ambient.objective == Constants.MOBILE_AMBIENT_ROAD
    then
        local order = {
            kind = faction.archetypeID == "looter"
                and Const.ORDER_HOSTILE_ROAM or Const.ORDER_ROAM,
            roamMode = Const.ROAM_MODE_ROAD,
            x = target.x,
            y = target.y,
            z = target.z,
            radius = target.radius,
            targetRadius = Const.ROAM_TARGET_RADIUS,
            roadBounds = target.bounds,
        }
        return order
    end
    if mobile.controlMode == Constants.MOBILE_CONTROL_AMBIENT
        and ambient.objective == Constants.MOBILE_AMBIENT_SHELTER
    then
        return {
            kind = faction.archetypeID == "looter"
                and Const.ORDER_HOSTILE_ROAM or Const.ORDER_ROAM,
            roamMode = Const.ROAM_MODE_SHELTER,
            x = target.x,
            y = target.y,
            z = target.z,
            radius = target.radius,
            shelterSiteID = target.siteID,
            targetRadius = Const.ROAM_TARGET_RADIUS,
            reachedDistance = 3,
        }
    end
    if faction.archetypeID == "looter" then
        if mobile.pathMode == Constants.MOBILE_PATH_PLAYER then
            return {
                kind = Const.ORDER_HOSTILE_HUNT,
                x = target.x or home.x,
                y = target.y or home.y,
                z = target.z or home.z,
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
        roamMode = mobile.pathMode == Constants.MOBILE_PATH_PLAYER
            and Const.ROAM_MODE_PLAYER or Const.ROAM_MODE_AREA,
        x = home.x,
        y = home.y,
        z = home.z,
        radius = home.radius,
    }
end

local function memberRecords(faction)
    local output = {}
    for npcID, _ in pairs(faction.memberIDs or {}) do
        local record = PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(npcID) or nil
        if record and record.alive ~= false then
            output[#output + 1] = record
        end
    end
    return output
end

function H.RepairMobileOrders(faction)
    local expected = H.MobileOrder(
        faction,
        faction.mobile,
        faction.mobile and faction.mobile.site
    )
    if not expected then return 0 end
    local repaired = 0
    for _, record in ipairs(memberRecords(faction)) do
        if not sameOrder(record.orderSpec, expected) then
            if PNC.OrderSystem and PNC.OrderSystem.SetOrder then
                PNC.OrderSystem.SetOrder(record, H.Copy(expected))
            else
                record.orderSpec = H.Copy(expected)
            end
            repaired = repaired + 1
        end
    end
    return repaired
end

function H.FindPlayerBaseTarget(faction)
    local mobile = faction and faction.mobile or nil
    local current = mobile and mobile.strategicTarget or nil
    local BaseService = PNC.BaseService
    if current and current.baseID and BaseService and BaseService.Get then
        local base = BaseService.Get(current.baseID)
        if base and BaseService.BuildSnapshot then
            local snapshot = BaseService.BuildSnapshot(base)
            local bounds = snapshot and snapshot.geometry
                and snapshot.geometry.bounds or nil
            if bounds then
                return {
                    kind = "player_base",
                    baseID = base.id,
                    factionID = base.factionId,
                    zoneID = base.baseZoneId,
                    x = (bounds.minX + bounds.maxX) / 2,
                    y = (bounds.minY + bounds.maxY) / 2,
                    z = bounds.minZ,
                    radius = math.max(8, math.min(
                        32,
                        math.sqrt(
                            ((bounds.maxX - bounds.minX) / 2) ^ 2
                                + ((bounds.maxY - bounds.minY) / 2) ^ 2
                        )
                    )),
                }
            end
        end
    end
    if not Core or not Core.ForEachPlayer
        or not Factions or not Factions.GetPlayerFaction
        or not BaseService or not BaseService.GetForFaction
    then
        return nil
    end
    local best
    local bestDistance = math.huge
    local origin = mobile and mobile.site and mobile.site.home or {}
    Core.ForEachPlayer(function(player)
        local playerFaction = Factions.GetPlayerFaction(player)
        local base = playerFaction
            and BaseService.GetForFaction(playerFaction.id) or nil
        if base and BaseService.BuildSnapshot then
            local snapshot = BaseService.BuildSnapshot(base)
            local bounds = snapshot and snapshot.geometry
                and snapshot.geometry.bounds or nil
            if bounds then
                local targetX = (bounds.minX + bounds.maxX) / 2
                local targetY = (bounds.minY + bounds.maxY) / 2
                local distance = Core.DistanceSq(
                    origin.x or 0,
                    origin.y or 0,
                    targetX,
                    targetY
                )
                if distance < bestDistance then
                    bestDistance = distance
                    best = {
                        kind = "player_base",
                        baseID = base.id,
                        factionID = base.factionId,
                        zoneID = base.baseZoneId,
                        x = targetX,
                        y = targetY,
                        z = bounds.minZ,
                        radius = math.max(8, math.min(
                            32,
                            math.sqrt(
                                ((bounds.maxX - bounds.minX) / 2) ^ 2
                                    + ((bounds.maxY - bounds.minY) / 2) ^ 2
                            )
                        )),
                    }
                end
            end
        end
    end)
    return best
end

function H.TargetPlayerBaseSite(faction, at, searchRadius)
    local target = H.FindPlayerBaseTarget(faction)
    if not target then return nil, "no_player_base" end
    local snapshot = H.PlayerOwnershipSnapshot()
    local site = Resolver.FindAvailableNear(
        target.x,
        target.y,
        target.z,
        {
            createdAt = at,
            searchRadius = searchRadius
                or Constants.MOBILE_AMBIENT_SHELTER_SEARCH_RADIUS,
            siteFilter = H.ShelterFilter(snapshot),
        }
    )
    if site and H.IsValidShelterSite(site, snapshot) then
        return site, "player_base_staging_site"
    end
    return nil, "no_player_base_staging_site"
end

local function abstractTargetLocation(faction, target, objective)
    local Locations = PNC.AbstractLocations
    if not Locations then return nil end
    if target.kind == "building" then
        local site = {
            id = target.siteID,
            kind = "building",
            home = { x = target.x, y = target.y, z = target.z,
                radius = target.radius },
            bounds = target.bounds,
        }
        return Locations.RegisterSite and Locations.RegisterSite(site, {
            tags = { SHELTER = true },
        }) or nil
    end
    local factionKey = string.gsub(tostring(faction.id), "[^%w_%-%.:]", "_")
    local id = "aloc_mobile_nav_" .. string.sub(factionKey, 1, 120)
        .. "_" .. tostring(math.floor(target.x))
        .. "_" .. tostring(math.floor(target.y))
    return Locations.Register and Locations.Register({
        id = id,
        type = "TEMPORARY",
        x = target.x,
        y = target.y,
        z = target.z,
        tags = { ROAD = true, SHELTER = false },
    }) or nil
end

function H.SyncAbstractObjective(faction, objective, target, at)
    local Groups = PNC.AbstractGroups
    local Traversal = PNC.AbstractTraversal
    if not Groups or not Groups.FindByFactionID or not Traversal
        or not target
    then
        return false
    end
    local group = Groups.FindByFactionID(faction.id)
    if not group then return false end
    local location = abstractTargetLocation(faction, target, objective)
    if type(location) == "table" and location.id then
        group.mobileAmbient = true
        group.ambientObjective = objective
        if group.location and group.location.id ~= location.id
            and group.state ~= "TRAVELING"
        then
            Traversal.Begin(group, location, at)
        end
        if PNC.AbstractGroupManagerInternal
            and PNC.AbstractGroupManagerInternal.Touch
        then
            PNC.AbstractGroupManagerInternal.Touch(
                group,
                "mobile_ambient_objective"
            )
        end
        return true
    end
    return false
end

local function updateMobile(faction, patch, reason)
    if not Factions or not Factions.UpdateMobileGroup then
        return faction
    end
    local ok = Factions.UpdateMobileGroup(faction.id, patch, reason)
    return ok and Factions.Get(faction.id) or faction
end

function H.RefreshStrategic(faction, at)
    local mobile = faction and faction.mobile or nil
    if not mobile
        or mobile.controlMode ~= Constants.MOBILE_CONTROL_STRATEGIC
    then
        return faction, false
    end
    local target = H.FindPlayerBaseTarget(faction)
    local current = mobile.strategicTarget
    if target and not sameTarget(current, target) then
        faction = updateMobile(faction, {
            strategicTarget = target,
        }, "mobile_player_base_target")
    elseif not target and current and current.baseID then
        faction = updateMobile(faction, {
            strategicTarget = nil,
        }, "mobile_player_base_lost")
    end
    H.RepairMobileOrders(faction)
    return faction, target ~= nil
end

function H.RefreshAmbient(faction, at)
    local mobile = faction and faction.mobile or nil
    if not mobile
        or mobile.controlMode ~= Constants.MOBILE_CONTROL_AMBIENT
    then
        return faction, false
    end
    local phase = H.AmbientPhase(at)
    local ambient = mobile.ambient or {}
    local objective = phase == Constants.MOBILE_AMBIENT_DAY
        and Constants.MOBILE_AMBIENT_ROAD
        or Constants.MOBILE_AMBIENT_SHELTER
    local target = ambient.target
    local needsTarget = ambient.phase ~= phase
        or ambient.objective ~= objective
        or not target
        or at >= (tonumber(ambient.nextObjectiveAt) or 0)
    if needsTarget and at >= (tonumber(ambient.retryAt) or 0) then
        local selected
        if objective == Constants.MOBILE_AMBIENT_ROAD then
            selected = H.FindRoadTarget(faction)
        else
            selected = H.FindShelterTarget(faction, at)
        end
        if type(selected) == "table" then
            target = selected
            ambient = {
                phase = phase,
                objective = objective,
                target = target,
                nextCheckAt = at + Constants.MOBILE_AMBIENT_CHECK_HOURS,
                nextObjectiveAt = at + Constants.MOBILE_AMBIENT_OBJECTIVE_HOURS,
                retryAt = 0,
                revision = (tonumber(ambient.revision) or 0) + 1,
            }
            faction = updateMobile(faction, {
                ambient = ambient,
            }, "mobile_ambient_objective")
            H.SyncAbstractObjective(faction, objective, target, at)
        else
            ambient = {
                phase = phase,
                objective = nil,
                target = nil,
                nextCheckAt = at + Constants.MOBILE_AMBIENT_CHECK_HOURS,
                nextObjectiveAt = at,
                retryAt = at + Constants.MOBILE_AMBIENT_RETRY_HOURS,
                revision = (tonumber(ambient.revision) or 0) + 1,
            }
            faction = updateMobile(faction, {
                ambient = ambient,
            }, "mobile_ambient_target_retry")
        end
    elseif target and at >= (tonumber(ambient.nextCheckAt) or 0) then
        if objective == Constants.MOBILE_AMBIENT_SHELTER
            and not H.IsValidShelterSite({
                kind = "building",
                home = { x = target.x, y = target.y, z = target.z },
                bounds = target.bounds,
            })
        then
            ambient.nextObjectiveAt = at
            faction = updateMobile(faction, {
                ambient = ambient,
            }, "mobile_ambient_shelter_invalidated")
        else
            ambient.nextCheckAt = at + Constants.MOBILE_AMBIENT_CHECK_HOURS
            faction = updateMobile(faction, {
                ambient = ambient,
            }, "mobile_ambient_objective_checked")
        end
    end
    H.RepairMobileOrders(faction)
    return faction, target ~= nil
end

-- Re-evaluate one group's objective immediately. The scheduled pump keeps
-- this bounded across the world; debug tools and migration code can use this
-- targeted entry point without scanning every mobile faction.
function Director.RefreshFactionObjective(factionID, at)
    if not H.Authority() then return false, "not_authority" end
    local faction = Factions.Get(factionID)
    if not faction then return false, "faction_not_found" end
    if not Factions.IsMobileGroup(faction) then
        return false, "not_mobile_group"
    end
    at = finite(at, H.WorldAge and H.WorldAge() or 0)
    local refreshed
    local hasTarget
    if faction.mobile.controlMode
        == Constants.MOBILE_CONTROL_STRATEGIC
    then
        refreshed, hasTarget = H.RefreshStrategic(faction, at)
    else
        refreshed, hasTarget = H.RefreshAmbient(faction, at)
    end
    return true,
        hasTarget and "mobile_objective_refreshed"
            or "mobile_objective_pending",
        refreshed and H.Copy(refreshed.mobile) or nil
end

function Director.PumpAmbient(at, budget)
    at = finite(at, H.WorldAge and H.WorldAge() or 0)
    budget = math.max(1, math.floor(tonumber(budget) or 12))
    local factionIDs = {}
    for factionID, faction in pairs(
        Factions.Registry and Factions.Registry.byID or {}
    ) do
        if faction.status == "active" and Factions.IsMobileGroup(faction) then
            factionIDs[#factionIDs + 1] = factionID
        end
    end
    table.sort(factionIDs)
    local cursor = math.max(1, tonumber(Director.AmbientCursor) or 1)
    local processed = 0
    while processed < budget and #factionIDs > 0 do
        if cursor > #factionIDs then cursor = 1 end
        local faction = Factions.Get(factionIDs[cursor])
        if faction then
            if faction.mobile.controlMode
                == Constants.MOBILE_CONTROL_STRATEGIC
            then
                H.RefreshStrategic(faction, at)
            else
                H.RefreshAmbient(faction, at)
            end
        end
        cursor = cursor + 1
        processed = processed + 1
        if processed >= #factionIDs then break end
    end
    Director.AmbientCursor = cursor
    return processed
end

return Director
