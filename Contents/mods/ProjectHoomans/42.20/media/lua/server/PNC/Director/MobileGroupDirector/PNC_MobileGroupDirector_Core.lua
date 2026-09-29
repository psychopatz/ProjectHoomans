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

-- `override` requests a different role sequence for this one group: a trading
-- caravan roams as a trader plus guards while its faction leader stays at the
-- base. The caller validates every token against the archetype's allowed roles,
-- so an override can never assign a role the faction may not hold.
function H.FactionRole(faction, index, override)
    if type(override) == "table" and override[index] then
        return override[index]
    end
    local roles = H.RoleOrder[faction.archetypeID] or {}
    return roles[index]
        or PNC.FactionArchetypes.GetDefaultRole(
            faction.archetypeID
        )
end

-- Validate a caller-supplied role order against the faction archetype before a
-- single NPC is created. Returns a copied order, or nil plus a reason.
function H.ValidRoleOrder(faction, override)
    local Archetypes = PNC.FactionArchetypes
    local output = {}
    local index
    local role
    if type(override) ~= "table" then return nil, "role_order_required" end
    if #override < 1 then return nil, "role_order_empty" end
    for index = 1, #override do
        role = override[index]
        if type(role) ~= "string"
            or not Archetypes.IsRoleAllowed(faction.archetypeID, role)
        then
            return nil, "invalid_role_order"
        end
        output[index] = role
    end
    return output
end

function H.NPCArchetype(faction)
    return faction.archetypeID == "looter"
        and "Scavenger" or "General"
end

function H.MobileOrder(faction, mobile, site)
    local home = site and site.home or {}
    if mobile
        and mobile.activity
            == Constants.MOBILE_ACTIVITY_TRAVELING_TO_SETTLEMENT
    then
        return {
            kind = Const.ORDER_GUARD,
        }
    end
    local mode = H.PathMode(mobile and mobile.pathMode)
    if faction.archetypeID ~= "looter"
        and H.PlayerRoamAreaOrder
        and H.IsPlayerRoamArea
        and H.IsPlayerRoamArea(mobile)
    then
        return H.PlayerRoamAreaOrder(faction, mobile, site)
    end
    if H.AmbientOrder then
        local ambient = H.AmbientOrder(faction, mobile, site)
        if ambient then return ambient end
    end
    if faction.archetypeID ~= "looter"
        and H.PlayerRoamStreetPoolOrder
        and H.IsPlayerRoamStreetPool
        and H.IsPlayerRoamStreetPool(mobile)
    then
        return H.PlayerRoamStreetPoolOrder(faction, mobile, site)
    end
    if faction.archetypeID == "looter" then
        if mode == Constants.MOBILE_PATH_PLAYER then
            return {
                kind = Const.ORDER_HOSTILE_HUNT,
                x = mobile and mobile.strategicTarget
                    and mobile.strategicTarget.x or home.x,
                y = mobile and mobile.strategicTarget
                    and mobile.strategicTarget.y or home.y,
                z = mobile and mobile.strategicTarget
                    and mobile.strategicTarget.z or home.z,
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
