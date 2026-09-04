local T = require "tests/support/test"

local SHARED = T.path("ProjectHoomans", "shared", "")
local CLIENT = T.path("ProjectHoomans", "client", "")
local CORE_CLIENT = T.path(
    "PsychopatzCore", "common_client", ""
)
T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "client" },
    { "ProjectHoomans", "common_lua" },
    { "PsychopatzCore", "common" },
    { "PsychopatzCore", "common_client" },
})

local now = 1000
local messages = {}
local playerSpeech = {}
local npcSpeech = {}
local player = {
    getUsername = function() return "alice" end,
    isDead = function() return false end,
    Say = function(_, text) playerSpeech[#playerSpeech + 1] = text end,
}
local target = { id = "npc-one", name = "Morgan" }
local body = {
    isDead = function() return false end,
    Say = function(_, text) npcSpeech[#npcSpeech + 1] = text end,
}

getTimeInMillis = function() return now end
getText = function(key) return key end
getSpecificPlayer = function() return player end
Events = {
    OnTick = { Add = function() end },
}

PNC = {
    Core = {
        Now = function() return now end,
    },
    Registry = {
        GetLiveZombie = function(id)
            return id == target.id and body or nil
        end,
    },
    NPCIdentityPresentation = {
        GetName = function(value) return value.name or value.id end,
    },
    Network = { ClientState = {} },
}

package.preload["PNC/Knowledge/PNC_NPCIdentityPresentation"] = function()
    return PNC.NPCIdentityPresentation
end
package.preload["PNC/Audio/PNC_PlayerSpeech"] = function()
    PNC.PlayerSpeech = {
        Speak = function(actor, text)
            actor:Say(text)
            return true
        end,
    }
    return PNC.PlayerSpeech
end

local EventBus = require "PsychopatzCore/Events/PC_EventBus"
local Message = require "PsychopatzCore/Conversation/PsychopatzConversationMessage"
local Client = require "PsychopatzCore/Conversation/PsychopatzSocialFlavorClient"
EventBus.subscribe(Message.EVENT_TYPE, function(message)
    messages[#messages + 1] = message
end, "companion-command-interaction-message")

T.load(SHARED .. "PNC/Core/Commands/PNC_CompanionCommandFlavor.lua")
T.load(SHARED .. "PNC/Core/Commands/PNC_CompanionCommandFlavorDefinitions.lua")
T.load(CLIENT .. "PNC/Commands/PNC_CompanionCommandPresentation.lua")

Client.Reset()
T.truthy(Client.Enqueue({
    eventID = "ambient-before-command",
    text = "ambient chatter",
    family = "ambient",
    speakerID = "npc-ambient",
    priority = 35,
    weight = 9999,
}), "ambient control line was not queued")
local accepted = PNC.CompanionCommandPresentation.ShowCommandInteraction(
    player,
    "camp",
    target,
    { target },
    "valid",
    {
        origin = "companion_emote",
        commandID = "camp",
        requestID = "camp-exchange-1",
        playerActor = player,
        target = target,
        targets = { target },
    }
)
T.equal(accepted, true, "interactive command was not queued")
local queue = Client.GetQueueSnapshot()
T.equal(#queue, 3, "player and NPC lines did not share the queue")
T.equal(queue[2].priority, 100, "interaction did not use top priority")
T.equal(queue[2].weight, 100, "interaction did not use interaction weight")
T.equal(queue[3].priority, 100, "NPC response lost interaction priority")
T.equal(#playerSpeech, 0, "player spoke before queue delivery")
T.equal(#npcSpeech, 0, "NPC spoke before queue delivery")

T.truthy(Client.Pump(now), "player line was not delivered")
T.truthy(Client.Pump(now), "NPC line was not delivered")
T.equal(#messages, 2, "queue did not publish both interaction messages")
T.equal(messages[1].speakerKind, "player", "player line speaker kind")
T.equal(messages[2].speakerKind, "npc", "NPC line speaker kind")
T.equal(#playerSpeech, 1, "queued player line was not spoken")
T.equal(#npcSpeech, 1, "queued NPC line was not spoken")

EventBus.clearOwner("companion-command-interaction-message")
T.finish("pnc_companion_command_interaction_smoke")
