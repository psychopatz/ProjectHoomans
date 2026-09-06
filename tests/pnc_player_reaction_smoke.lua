local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local now = 1000
local serverMode = false
local clientOnly = false
local sentCommand
local hitReaction = ""
local actionState = "idle"
local ignoreMovement = false
local reactionEvents = 0
local legacyBumpWrites = 0
local clientHandlers = {}

isServer = function() return serverMode end

local player = {
    getObjectName = function() return "Player" end,
    getOnlineID = function() return 12 end,
    getUsername = function() return "alice" end,
    getHitReaction = function() return hitReaction end,
    getActionStateName = function() return actionState end,
    setHitReaction = function(_, value) hitReaction = value end,
    reportEvent = function(_, event)
        T.equal(event, "washit", "unexpected reaction event")
        reactionEvents = reactionEvents + 1
        actionState = "hitreaction"
    end,
    setIgnoreMovement = function(_, value) ignoreMovement = value end,
    setBumpType = function() legacyBumpWrites = legacyBumpWrites + 1 end,
    setBumpFall = function() legacyBumpWrites = legacyBumpWrites + 1 end,
    setBumpStaggered = function() legacyBumpWrites = legacyBumpWrites + 1 end,
    setBlockMovement = function() legacyBumpWrites = legacyBumpWrites + 1 end,
}

local sourceNPC = {
    getOnlineID = function() return 88 end,
    getModData = function() return { PNC_UUID = "npc-88" } end,
}

PNC = {
    Const = {
        CMD_PLAYER_REACTION = "PlayerReaction",
        NPC_GROUNDED_COUNTER_STAGGER_DURATION_MS = 650,
        NPC_GROUNDED_COUNTER_STAGGER_TIMEOUT_MS = 1400,
    },
    Core = {
        Now = function() return now end,
        IsAuthority = function() return true end,
        IsClientOnly = function() return clientOnly end,
    },
    Network = {
        Internal = {
            SendToPlayer = function(target, command, payload)
                sentCommand = {
                    target = target,
                    command = command,
                    payload = payload,
                }
                return true
            end,
        },
    },
    Client = {
        Internal = {
            RegisterServerCommand = function(command, handler)
                if command ~= nil then
                    clientHandlers[command] = handler
                end
                return true
            end,
        },
    },
}

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Combat/PNC_PlayerReaction.lua"
)
T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "client" },
})
T.load(
    "ProjectHoomans",
    "client",
    "PNC/Networking/PNC_ClientCombatCommands.lua"
)

T.truthy(PNC.PlayerReaction.StartCounterStagger(
    player,
    sourceNPC,
    { kind = "counter_stagger" }
), "singleplayer counter-stagger did not start")
T.equal(hitReaction, "HitReaction", "singleplayer reaction was not applied")
T.equal(reactionEvents, 1, "singleplayer reaction event count")
T.equal(legacyBumpWrites, 0, "singleplayer used NPC bump fields")

T.truthy(PNC.PlayerReaction.ApplyLocalCounterStagger(player, {
    kind = "counter_stagger",
    token = "counter-stagger:12:1000:1",
}), "duplicate local reaction should be idempotent")
T.equal(reactionEvents, 1, "duplicate local reaction retriggered animation")

now = now + 1600
PNC.PlayerReaction.Pump(now)
T.equal(hitReaction, "", "singleplayer reaction did not release")
T.falsy(ignoreMovement, "singleplayer reaction retained movement ownership")

serverMode = true
clientOnly = false
sentCommand = nil
now = now + 100
T.truthy(PNC.PlayerReaction.StartCounterStagger(
    player,
    sourceNPC,
    { kind = "counter_stagger" }
), "multiplayer server did not dispatch reaction")
T.truthy(sentCommand, "multiplayer server sent no command")
T.equal(sentCommand.command, "PlayerReaction", "wrong multiplayer command")
T.equal(sentCommand.payload.kind, "counter_stagger", "wrong multiplayer reaction kind")
T.equal(sentCommand.payload.sourceNpcId, "npc-88", "missing source NPC identity")
T.equal(hitReaction, "", "server mutated local player presentation")

T.falsy(PNC.PlayerReaction.StartCounterStagger(
    player,
    sourceNPC,
    { kind = "counter_stagger" }
), "server stacked an active player reaction")

serverMode = false
clientOnly = true
now = now + 1600
getSpecificPlayer = function() return player end
T.truthy(clientHandlers.PlayerReaction,
    "client command handler was not registered")
PNC.PlayerReaction.Reset()
clientHandlers.PlayerReaction(sentCommand.payload)
T.equal(reactionEvents, 2, "owning client did not apply server reaction")
T.falsy(PNC.PlayerReaction.ApplyLocalCounterStagger(player, {
    kind = "invalid",
    token = "invalid",
}), "invalid reaction was accepted")

now = now + 1600
PNC.PlayerReaction.Pump(now)
T.equal(hitReaction, "", "owning client reaction did not release")
T.falsy(ignoreMovement, "owning client retained movement ownership")
T.equal(legacyBumpWrites, 0, "owning client used NPC bump fields")

return T.finish("pnc_player_reaction_smoke")
