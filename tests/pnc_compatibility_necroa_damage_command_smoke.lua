local T = require "tests/support/test"

local HANDLER_FILE = T.path(
    "ProjectHoomans",
    "server",
    "PNC/Networking/Handlers/PNC_ServerNecroaDamageCommandHandler.lua"
)

local applied
local liveBody = {
    getModData = function()
        return {
            PNC_Owner = "ProjectHoomans",
            PNC_UUID = "npc-1",
        }
    end,
    isAlive = function() return true end,
    getX = function() return 10 end,
    getY = function() return 10 end,
    getZ = function() return 0 end,
}

local player = {
    getX = function() return 10 end,
    getY = function() return 10 end,
}

PNC = {
    Const = {
        CMD_NECROA_INCOMING_DAMAGE = "NecroaIncomingDamage",
    },
    ServerCommandRouter = {
        Handlers = {},
        Register = function(command, handler)
            PNC.ServerCommandRouter.Handlers[command] = handler
            return true
        end,
    },
    Registry = {
        GetLiveZombie = function(id)
            return id == "npc-1" and liveBody or nil
        end,
    },
    Compatibility = {
        ActorOwnership = {
            IsHoomansOwned = function(body)
                return body == liveBody
            end,
        },
        IncomingDamage = {
            Apply = function(context)
                applied = context
                return true, { outcome = "wounded" }
            end,
        },
    },
}

T.load(HANDLER_FILE)

local handler = PNC.ServerCommandRouter.Handlers.NecroaIncomingDamage
T.truthy(handler, "Necroa damage command was not registered")

handler(player, {
    npcID = "npc-1",
    amount = 12,
    type = "necroa_explosion",
    attackerX = 11,
    attackerY = 10,
    attackerZ = 0,
})

T.truthy(applied, "valid Necroa damage request was not applied")
T.equal(applied.amount, 12, "Necroa damage amount was not preserved")
T.equal(applied.attackerProvider, "Necroa",
    "Necroa provider was not preserved")
T.equal(applied.attackerX, 11,
    "Necroa attacker position was not preserved")

applied = nil
handler(player, {
    npcID = "npc-1",
    amount = 12,
    attackerX = 100,
    attackerY = 100,
    attackerZ = 0,
})
T.falsy(applied, "out-of-range Necroa damage was accepted")

T.finish("pnc_compatibility_necroa_damage_command_smoke")
