if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ColonyManagement = PNC.ColonyManagement or {}
PNC.ColonyManagement.Internal = PNC.ColonyManagement.Internal or {}

local Management = PNC.ColonyManagement
local Internal = Management.Internal
local Definitions = PNC.NeedsDefinitions


local function canUseDebug(player)
    if not isServer or not isServer() then
        if isDebugEnabled then return isDebugEnabled() == true end
        return getCore and getCore() and getCore():getDebug() == true or false
    end
    local access = player and player.getAccessLevel
        and tostring(player:getAccessLevel() or "") or ""
    return string.lower(access) == "admin"
end

Internal.canUseDebug = canUseDebug
Management.CanUseDebug = canUseDebug

return Management
