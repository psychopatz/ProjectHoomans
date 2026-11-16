-- Production starter-customization request.  This is not a debug route.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Router = PNC.ServerCommandRouter
local Const = PNC.Const
local Service = PNC.StartingCompanionCustomizationService

Router.Register(Const.CMD_STARTING_COMPANION_CUSTOMIZATION,
    function(player, args)
        if Service and Service.Receive then
            Service.Receive(player, args)
        end
    end)

