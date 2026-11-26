-- Puppet Opera authority runtime bootstrap.
--
-- This provider registers the already-composed public tick and command
-- entry points after every authority provider has loaded.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Choreography = PNC.Choreography or {}

local Opera = PNC.Choreography
local Authority = Opera.Authority or {}
Opera.Authority = Authority
local Const = PNC.Const or {}

local TickRegistry = PNC.Server and PNC.Server.TickRegistry
    or require "PNC/Server/Server/PNC_Server_TickRegistry"
if TickRegistry and type(TickRegistry.Register) == "function" then
    TickRegistry.Register("choreography", {
        phase = "prepare",
        priority = 10,
        pump = Authority.Pump,
    })
elseif Events and Events.OnTick then
    Events.OnTick.Add(Authority.Pump)
end

if PNC.ServerCommandRouter and PNC.ServerCommandRouter.Register then
    PNC.ServerCommandRouter.Register(
        Const.CMD_CHOREOGRAPHY_REQUEST,
        function(player, args)
            return Authority.HandleRequest(player, args)
        end
    )
end

return Authority
