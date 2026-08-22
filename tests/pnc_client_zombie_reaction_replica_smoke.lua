local T = require "tests/support/test"

local FILE =
    T.path("ProjectHoomans", "client", "PNC/")
    .. "Networking/PNC_ClientCombatCommands.lua"

local now = 1000
local handlers = {}
local applied = 0
local pumped = 0
local target = {}
local attacker = {}

PNC = {
    Const = {
        CMD_ZOMBIE_REACTION = "zombie_reaction",
        CMD_ZOMBIE_BITE = "zombie_bite",
        CMD_FIREARM_SHOT = "firearm_shot",
    },
    Core = {
        Now = function() return now end,
    },
    Network = {
        ClientState = {},
        FindZombieByOnlineID = function(id)
            if id == 11 then return target end
            if id == 22 then return attacker end
            return nil
        end,
    },
    Client = {
        Internal = {
            RegisterServerCommand = function(command, callback)
                handlers[command] = callback
            end,
        },
    },
    CombatZombieReaction = {
        ApplyReplicatedHit = function(source, victim)
            T.truthy(source == attacker and victim == target,
                "replicated reaction resolved the wrong bodies")
            applied = applied + 1
            return true
        end,
        Pump = function(victim)
            T.truthy(victim == target,
                "client reaction pump lost its target body")
            pumped = pumped + 1
            return false
        end,
    },
}

T.load(FILE)

T.truthy(handlers.zombie_reaction,
    "zombie reaction command was not registered")
handlers.zombie_reaction({
    targetOnlineID = 11,
    attackerOnlineID = 22,
})
T.truthy(applied == 1,
    "replicated zombie reaction was not applied")
T.truthy(PNC.Client.ZombieReactionReplicas["11"] ~= nil,
    "client did not retain the reaction release lease")

PNC.Client.Internal.PumpCombatReplicas()
T.truthy(pumped == 1,
    "client combat tick did not pump zombie reaction release")
T.truthy(PNC.Client.ZombieReactionReplicas["11"] == nil,
    "completed client reaction lease was not removed")
T.truthy(
    PNC.Client.Internal.PumpBiteReplicas
        == PNC.Client.Internal.PumpCombatReplicas,
    "legacy combat-pump alias no longer points at the unified pump"
)
T.finish("pnc_client_zombie_reaction_replica_smoke")

T.finish("pnc_client_zombie_reaction_replica_smoke")
