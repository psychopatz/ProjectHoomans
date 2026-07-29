local FILE =
    "Contents/mods/ProjectHoomans/42.19/media/lua/client/PNC/"
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
            assert(source == attacker and victim == target,
                "replicated reaction resolved the wrong bodies")
            applied = applied + 1
            return true
        end,
        Pump = function(victim)
            assert(victim == target,
                "client reaction pump lost its target body")
            pumped = pumped + 1
            return false
        end,
    },
}

dofile(FILE)

assert(handlers.zombie_reaction,
    "zombie reaction command was not registered")
handlers.zombie_reaction({
    targetOnlineID = 11,
    attackerOnlineID = 22,
})
assert(applied == 1,
    "replicated zombie reaction was not applied")
assert(PNC.Client.ZombieReactionReplicas["11"] ~= nil,
    "client did not retain the reaction release lease")

PNC.Client.Internal.PumpCombatReplicas()
assert(pumped == 1,
    "client combat tick did not pump zombie reaction release")
assert(PNC.Client.ZombieReactionReplicas["11"] == nil,
    "completed client reaction lease was not removed")
assert(
    PNC.Client.Internal.PumpBiteReplicas
        == PNC.Client.Internal.PumpCombatReplicas,
    "legacy combat-pump alias no longer points at the unified pump"
)

print("pnc_client_zombie_reaction_replica_smoke: ok")
