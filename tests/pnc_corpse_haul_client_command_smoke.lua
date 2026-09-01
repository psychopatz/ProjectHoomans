local T = require "tests/support/test"

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

package.preload["TimedActions/ISTimedActionQueue"] = function() return true end
package.preload["TimedActions/ISGrabCorpseAction"] = function() return true end
package.preload["TimedActions/ISDropCorpseAction"] = function() return true end
package.preload["TimedActions/ISUnequipAction"] = function() return true end

local registeredCommand
PNC = {
    Const = {
        MODULE = "PNC",
        CMD_CORPSE_HAUL_ACTION = "CorpseHaulAction",
        CMD_CORPSE_HAUL_ACK = "CorpseHaulAck",
    },
    Client = {
        Internal = {
            RegisterServerCommand = function(command, handler)
                registeredCommand = { command = command, handler = handler }
                return true
            end,
        },
    },
    Core = {},
}

ISTimedActionQueue = {}
ISGrabCorpseAction = {}
ISDropCorpseAction = {}
ISUnequipAction = {}

local Actions = T.load("ProjectHoomans", "client",
    "PNC/Actions/PNC_CorpseHaulActions.lua")
T.truthy(Actions, "corpse action bridge loads on clients")
T.truthy(registeredCommand, "server action command is routed to the bridge")
T.equal(registeredCommand.command, "CorpseHaulAction",
    "grapple action command uses the shared transport")

T.finish("pnc_corpse_haul_client_command_smoke")
