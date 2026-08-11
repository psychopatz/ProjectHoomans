local function equal(actual, expected, message)
    if actual ~= expected then
        error((message or "assertion failed") .. ": expected "
            .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

package.path = table.concat({
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/?.lua",
    package.path,
}, ";")

local normalizer, jobName, handler
local move
PNC = {
    Core = {
        Distance = function(x1, y1, x2, y2)
            local dx, dy = x2 - x1, y2 - y1
            return math.sqrt(dx * dx + dy * dy)
        end,
    },
    OrderSystem = {
        RegisterNormalizer = function(_, value) normalizer = value end,
    },
    JobSystem = {
        RegisterOrder = function(_, value) jobName = value end,
    },
    BehaviorRegistry = {
        Register = function(_, value) handler = value end,
    },
    BehaviorCommon = {
        ClearCombatTarget = function() end,
        HaltMovement = function(_, _, reason) move = reason end,
        MoveRecord = function(_, _, x, y, z, _, _, reason)
            move = { x = x, y = y, z = z, reason = reason }
        end,
    },
    Animation = { Apply = function() end },
}

require "PNC/Core/Behaviors/PNC_Behavior_FacilityDebugWork"
equal(jobName, "FacilityDebugWork", "debug order job registration")
equal(type(handler), "function", "debug behavior registration")

local order = normalizer({}, {
    facilityId = "facility_a", facilityName = "Farm",
    componentId = "field_a", role = "farm.field", x = 10, y = 5, z = 0,
})
local record = {
    x = 0, y = 0, z = 0, orderSpec = order,
    runtime = { facilityDebugWork = {} },
}
equal(handler(record, {}, jobName, 0), true, "travelling handler")
equal(record.runtime.facilityDebugWork.phase, "TRAVELLING", "travel phase")
equal(move.reason, "facility_debug_work", "production movement request")

record.x, record.y = 10, 5
equal(handler(record, {}, jobName, 0), true, "working handler")
equal(record.runtime.facilityDebugWork.phase, "WORKING", "arrival phase")
equal(move, "facility_debug_working", "arrival movement hold")

print("pnc_facility_debug_work_smoke: ok")
