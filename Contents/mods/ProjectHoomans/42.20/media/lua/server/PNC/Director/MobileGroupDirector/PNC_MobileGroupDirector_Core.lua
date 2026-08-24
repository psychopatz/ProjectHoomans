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

Director.LastPumpAt = Director.LastPumpAt or nil

H.PumpIntervalMs = H.PumpIntervalMs or 5000

H.RoleOrder = H.RoleOrder or {
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

function H.Authority()
    return Core and Core.IsAuthority
        and Core.IsAuthority() == true
end

function H.Copy(value)
    return Core and Core.DeepCopy and Core.DeepCopy(value) or value
end

function H.WorldAge(value)
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

function H.GroupSize(value)
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

function H.PresenceMode(value)
    return CommunityConstants.VALID_GROUP_PRESENCE_MODES[value]
        and value or "auto"
end

function H.PathMode(value, fallback)
    if Constants.VALID_MOBILE_PATH_MODES[value] then
        return value
    end
    if Constants.VALID_MOBILE_PATH_MODES[fallback] then
        return fallback
    end
    return Constants.MOBILE_PATH_RANDOM
end

function H.FactionRole(faction, index)
    local roles = H.RoleOrder[faction.archetypeID] or {}
    return roles[index]
        or PNC.FactionArchetypes.GetDefaultRole(
            faction.archetypeID
        )
end

function H.NPCArchetype(faction)
    return faction.archetypeID == "looter"
        and "Scavenger" or "General"
end

function H.MobileOrder(faction, mobile, site)
    local home = site and site.home or {}
    local mode = H.PathMode(mobile and mobile.pathMode)
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
