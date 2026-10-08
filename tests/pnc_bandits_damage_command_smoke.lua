local T = require "tests/support/test"

local FILE = T.path(
    "ProjectHoomans",
    "server",
    "PNC/Networking/Handlers/PNC_ServerBanditsDamageCommandHandler.lua"
)

local applied
local liveBody = {
    isAlive = function() return true end,
    getModData = function()
        return {
            PNC_Owner = "ProjectHoomans",
            PNC_UUID = "npc-1",
        }
    end,
    getX = function() return 10 end,
    getY = function() return 10 end,
    getZ = function() return 0 end,
}
local bandit = {
    x = 11,
    getX = function(self) return self.x end,
    getY = function() return 10 end,
    getZ = function() return 0 end,
    getPersistentOutfitID = function() return 7 end,
}
local player = {
    getX = function() return 10 end,
    getY = function() return 10 end,
}

PNC = {
    Const = {
        CMD_BANDITS_INCOMING_DAMAGE = "BanditsIncomingDamage",
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
            IsHoomansOwned = function(body) return body == liveBody end,
        },
        Bandits = {
            Internal = {
                GetBody = function(id)
                    return id == "bandit-1" and bandit or nil
                end,
            },
            IncomingBridge = {
                ApplyAuthoritativeHit = function(
                        attacker, item, target, amount, metadata)
                    applied = {
                        attacker = attacker,
                        item = item,
                        target = target,
                        amount = amount,
                        metadata = metadata,
                    }
                    return true, "applied"
                end,
            },
        },
    },
}

T.load(FILE)
local handler = PNC.ServerCommandRouter.Handlers.BanditsIncomingDamage
T.truthy(handler, "Bandits damage command was not registered")

handler(player, {
    npcID = "npc-1",
    attackerID = "bandit-1",
    attackerGeneration = 7,
    amount = 14,
    attackType = "ranged",
    attackKind = "bandits_firearm",
    woundType = "bullet",
    weaponFullType = "Base.Pistol",
    attackerX = 11,
    attackerY = 10,
    attackerZ = 0,
})

T.truthy(applied, "valid Bandits damage request was not applied")
T.equal(applied.amount, 14,
    "Bandits server handler changed the bounded damage amount")
T.equal(applied.metadata.attackType, "ranged",
    "Bandits server handler lost the attack type")
T.equal(applied.metadata.weaponFullType, "Base.Pistol",
    "Bandits server handler lost weapon identity")
T.equal(applied.metadata.attackerX, 11,
    "Bandits server handler did not use the resolved attacker position")

applied = nil
bandit.x = 100
handler(player, {
    npcID = "npc-1",
    attackerID = "bandit-1",
    attackerGeneration = 7,
    amount = 14,
    attackerX = 100,
    attackerY = 100,
    attackerZ = 0,
})
T.falsy(applied, "out-of-range Bandits damage was accepted")

T.finish("pnc_bandits_damage_command_smoke")
