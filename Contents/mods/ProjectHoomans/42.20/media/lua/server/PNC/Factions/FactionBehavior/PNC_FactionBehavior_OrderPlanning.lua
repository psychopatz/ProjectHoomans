if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FactionBehavior = PNC.FactionBehavior or {}
PNC.FactionBehavior.Internal = PNC.FactionBehavior.Internal or {}

local Behavior = PNC.FactionBehavior
local Internal = Behavior.Internal
local Const = PNC.Const
local Core = PNC.Core

local function assign(record, key, value)
    if record[key] == value then return false end
    record[key] = value
    return true
end

local function clearCombatRuntime(record)
    record.runtime = record.runtime or {}
    record.runtime.target = nil
    record.runtime.attackAction = nil
    record.runtime.lastPathX = nil
    record.runtime.lastPathY = nil
    record.runtime.followState = nil
    record.nextThinkAt = Core.Now()
end

local function desiredOrder(record, mode, owner, faction, preservePlayerOrder)
    local mobile = faction and faction.mobile
    local home = mobile and mobile.site and mobile.site.home
    if mobile and mobile.active == true and home then
        local pathMode = mobile.pathMode
        if mode == "aggressive" then
            if pathMode == PNC.FactionConstants.MOBILE_PATH_RANDOM then
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
                kind = Const.ORDER_HOSTILE_HUNT,
                x = home.x,
                y = home.y,
                z = home.z,
            }
        end
        return {
            kind = Const.ORDER_ROAM,
            roamMode = pathMode
                == PNC.FactionConstants.MOBILE_PATH_PLAYER
                and Const.ROAM_MODE_PLAYER
                or Const.ROAM_MODE_AREA,
            x = home.x,
            y = home.y,
            z = home.z,
            radius = home.radius,
        }
    end
    if mode == "player_owned" then
        local current = record.orderSpec or {}
        local kind = tostring(current.kind or "")
        local registeredJob = PNC.JobSystem and PNC.JobSystem.OrderJobs
            and PNC.JobSystem.OrderJobs[kind] or nil
        if preservePlayerOrder == true and (
            kind == Const.ORDER_GUARD
            or kind == Const.ORDER_PATROL
            or kind == Const.ORDER_TRAVEL
            or registeredJob ~= nil
        ) then
            return Core.DeepCopy(current)
        end
        return {
            kind = Const.ORDER_FOLLOW,
            ownerUsername = owner.username,
            ownerOnlineID = owner.onlineID,
        }
    end
    if mode == "aggressive" then
        return {
            kind = Const.ORDER_HOSTILE_HUNT,
            x = record.x,
            y = record.y,
            z = record.z,
        }
    end
    return {
        kind = Const.ORDER_ROAM,
        roamMode = Const.ROAM_MODE_AREA,
        x = record.x,
        y = record.y,
        z = record.z,
        radius = Const.ROAM_DEFAULT_RADIUS,
    }
end

Internal.assign = assign
Internal.clearCombatRuntime = clearCombatRuntime
Internal.desiredOrder = desiredOrder
