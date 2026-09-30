local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "client" },
    { "ProjectHoomans", "common_lua" },
    { "PsychopatzCore", "common" },
    { "PsychopatzCore", "common_client" },
})

-- ---------------------------------------------------------------------------
-- This test drives the REAL client flavor pipeline (PsychopatzCore's
-- arbitration queue) rather than a stub, because the risk it guards against is
-- a queue-level interaction: several mourners from one faction share a flavor
-- family, and a family cooldown would silently reduce the whole scene to a
-- single voice.  Only the real queue proves otherwise.
-- ---------------------------------------------------------------------------

local now = 1000
local tickHandlers = {}
getTimeInMillis = function() return now end
getCurrentSaveName = function() return "leader-loss-test" end
getText = function(key) return key end
Events = {
    OnTick = {
        Add = function(callback) tickHandlers[#tickHandlers + 1] = callback end,
    },
}

PsychopatzCore = { Conversation = {} }
local EventBus = require "PsychopatzCore/Events/PC_EventBus"
local Message = require "PsychopatzCore/Conversation/PsychopatzConversationMessage"
local Flavor = require "PsychopatzCore/Conversation/PsychopatzSocialFlavor"
local Client = require "PsychopatzCore/Conversation/PsychopatzSocialFlavorClient"

local messages = {}
EventBus.subscribe(Message.EVENT_TYPE, function(message)
    messages[#messages + 1] = message
end, "leader-loss-message-test")

-- The shared resolver owns the leader-loss vocabulary this test asserts on.
local Resolver = require "PNC/Core/Social/PNC_FlavorTextResolver"
local Const = PNC.FlavorTextConst

-- Register the authored leader-loss lanes into the real registry.
dofile("Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/Conversation/"
    .. "PNC_SocialFlavorDefinitions_LeaderDeath_Close.lua")
dofile("Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/Conversation/"
    .. "PNC_SocialFlavorDefinitions_LeaderDeath_Wider.lua")
dofile("Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/Conversation/"
    .. "PNC_SocialFlavorDefinitions_LeaderDeath.lua")

-- ---------------------------------------------------------------------------
-- Enqueue three mourners exactly as the server emitter's packets arrive.
-- ---------------------------------------------------------------------------

local function mournerPacket(npcID, grief, succession)
    return {
        eventID = "leader_loss:F1:1000:" .. npcID,
        flavorID = Const.FLAVOR_LEADER_DEATH,
        eventType = Const.FLAVOR_LEADER_DEATH,
        family = Const.LEADER_DEATH_FAMILY,
        priority = Const.LEADER_DEATH_PRIORITY,
        weight = Const.LEADER_DEATH_WEIGHT,
        llmEligible = false,
        memoryEligible = true,
        npcID = npcID,
        npcType = grief,
        socialRole = grief,
        relationshipState = grief,
        relationshipTier = "reserved",
        mergeKey = npcID .. ":" .. Const.LEADER_DEATH_FAMILY,
        cooldowns = {
            familyMs = 0,
            speakerMs = Const.LEADER_DEATH_COOLDOWN_MS,
            ambientMs = 0,
            mergeWindowMs = 5000,
        },
        ttlMs = Const.LEADER_DEATH_TTL_MS,
        holdMs = Const.LEADER_DEATH_HOLD_MS,
        context = {
            leaderGrief = grief,
            leaderSuccession = succession,
            leaderDied = true,
            leaderName = "Mara",
            successorName = "Rook",
        },
        source = {
            kind = "social_flavor",
            channel = "succession",
            eventType = Const.FLAVOR_LEADER_DEATH,
            contextEligible = true,
        },
    }
end

local speakerIDs = { "npc-mate", "npc-friend", "npc-colonist" }
local griefs = { "devoted", "close", "colonist" }
local accepted = 0
local i
for i = 1, #speakerIDs do
    local ok = Client.Enqueue(mournerPacket(
        speakerIDs[i], griefs[i], Const.Succession.PROMOTED))
    if ok == true then accepted = accepted + 1 end
end
T.equal(accepted, #speakerIDs,
    "every mourner is admitted to the real queue, not just the first")

local snapshot = Client.GetQueueSnapshot()
T.equal(#snapshot, #speakerIDs,
    "all mourners are queued together")

-- Deliver them one at a time, advancing past each hold window.
local delivered = 0
for i = 1, #speakerIDs do
    local ok = Client.Pump(now)
    if ok == true then delivered = delivered + 1 end
    -- The next voice waits out the previous line's hold window.
    now = now + (Const.LEADER_DEATH_HOLD_MS or 4500) + 100
end
T.equal(delivered, #speakerIDs,
    "each mourner is delivered in sequence, got " .. tostring(delivered))
T.equal(#messages, #speakerIDs,
    "the scene produced one message per mourner")

-- The three lines must actually differ, and each must resolve to authored
-- text rather than a raw key.
local seen = {}
for i = 1, #messages do
    local text = messages[i].text
    T.truthy(text and text ~= "", "mourner " .. tostring(i) .. " has text")
    T.falsy(string.find(text, "social." .. "witnessed_leader_death", 1, true),
        "no raw flavor key leaks into mourner " .. tostring(i))
    T.falsy(string.find(text, "{leaderName}", 1, true),
        "the leader name is substituted in mourner " .. tostring(i))
    T.falsy(string.find(text, "{", 1, true),
        "no unresolved token in mourner " .. tostring(i) .. ": " .. text)
    seen[text] = true
end
local distinct = 0
for _ in pairs(seen) do distinct = distinct + 1 end
T.equal(distinct, #speakerIDs,
    "the mourners say different things rather than one repeated line")

-- ---------------------------------------------------------------------------
-- A single mourner must not be able to repeat inside its speaker cooldown.
-- ---------------------------------------------------------------------------

messages = {}
local before = #messages
local readmitted = Client.Enqueue({
    eventID = "leader_loss:F1:1000:npc-mate",
    flavorID = Const.FLAVOR_LEADER_DEATH,
    family = Const.LEADER_DEATH_FAMILY,
    priority = Const.LEADER_DEATH_PRIORITY,
    npcID = "npc-mate",
    speakerID = "npc-mate",
    mergeKey = "npc-mate:" .. Const.LEADER_DEATH_FAMILY,
    cooldowns = { familyMs = 0, speakerMs = 60000, ambientMs = 0 },
    context = { leaderGrief = "devoted", leaderDied = true },
    source = { kind = "social_flavor" },
})
T.falsy(readmitted,
    "the same mourner cannot replay its line inside the speaker cooldown")
T.equal(#messages, before, "the repeat produced no message")

return true