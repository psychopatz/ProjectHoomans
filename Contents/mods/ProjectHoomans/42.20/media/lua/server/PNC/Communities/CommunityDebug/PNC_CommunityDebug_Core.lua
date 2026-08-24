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

Debug.LastValidation = Debug.LastValidation or nil

function H.Copy(value)
    return Core.DeepCopy(value)
end

function H.WorldAgeHours()
    if getGameTime and getGameTime()
        and getGameTime().getWorldAgeHours
    then
        return math.max(
            0,
            tonumber(getGameTime():getWorldAgeHours()) or 0
        )
    end
    return 0
end

function H.ActionResult(ok, reason, action)
    return {
        ok = ok == true,
        reason = reason,
        action = action,
    }
end

return Debug

