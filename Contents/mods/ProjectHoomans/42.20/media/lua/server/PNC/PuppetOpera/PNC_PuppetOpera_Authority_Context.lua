-- Puppet Opera authority context helpers.
--
-- This provider owns shared time, tracing, owner identity, and debug
-- authorization seams used by all authority providers.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}

local Opera = PNC.PuppetOpera
local Authority = Opera.Authority or {}
Opera.Authority = Authority
local Internal = Authority.Internal or {}
Authority.Internal = Internal
local Trace = Opera.Trace
    or require "PNC/Core/PuppetOpera/PNC_PuppetOpera_Trace"
local Core = PNC.Core

local function now()
    return Core and Core.Now and Core.Now() or 0
end

local function trace(session, eventName, fields, at)
    Trace.Add(session.trace, at or now(), eventName, fields)
end

local function ownerID(player)
    local onlineID
    local username
    if player and player.getOnlineID then
        onlineID = tonumber(player:getOnlineID())
        if onlineID and onlineID >= 0 then
            return "online:" .. tostring(onlineID)
        end
    end
    if player and player.getUsername then
        username = tostring(player:getUsername() or "")
        if username ~= "" then return "user:" .. username end
    end
    return "player:" .. tostring(player or "unknown")
end

local function debugAllowed(player)
    local router = PNC.ServerCommandRouter
    if not router or type(router.CanUseDebug) ~= "function" then
        return false
    end
    return router.CanUseDebug(player) == true
end

Internal.now = now
Internal.trace = trace
Internal.ownerID = ownerID
Internal.debugAllowed = debugAllowed

return true

