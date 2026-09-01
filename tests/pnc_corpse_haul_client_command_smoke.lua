local T = require "tests/support/test"

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local registeredCommand
PNC = {
    Const = {
        MODULE = "PNC",
        CMD_CORPSE_HAUL_ACTION = "CorpseHaulAction",
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

Events = { OnTick = { Add = function() end } }

local Sync = T.load("ProjectHoomans", "client",
    "PNC/Networking/PNC_CorpseHaulSync.lua")
T.truthy(Sync, "corpse sync loads on clients")
T.truthy(registeredCommand, "server action command is routed to sync")
T.equal(registeredCommand.command, "CorpseHaulAction",
    "grapple action command uses the shared transport")

T.finish("pnc_corpse_haul_client_command_smoke")
