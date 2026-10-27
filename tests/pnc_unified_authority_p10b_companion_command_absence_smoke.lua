local T = require "tests/support/test"

local SHARED = T.path("ProjectHoomans", "shared", "")
local CLIENT = T.path("ProjectHoomans", "client", "")
T.addPackagePaths()

local function read(path)
    local handle = assert(io.open(path, "rb"), "cannot open source: " .. path)
    local source = handle:read("*a")
    handle:close()
    return source
end

local function absent(relative)
    local handle = io.open(SHARED .. relative, "rb")
    if handle then
        handle:close()
        return false
    end
    return true
end

PNC = {
    Core = { Now = function() return 1000 end },
    Network = { ClientState = {} },
    Registry = {},
    NPCIdentityPresentation = {
        GetName = function(value) return value.name or value.id end,
    },
}

T.load(SHARED .. "PNC/Semantics/PNC_SemanticDialogueResponseCatalog.lua")
T.load(SHARED .. "PNC/Semantics/PNC_SemanticDialogueRealizationAuthority.lua")
T.load(SHARED .. "PNC/Semantics/PNC_SemanticCompanionSpeech.lua")
T.load(SHARED .. "PNC/Semantics/PNC_SemanticSocialReaction.lua")

local legacyFiles = {
    "PNC/Core/Commands/PNC_CompanionCommandFlavor.lua",
    "PNC/Core/Commands/PNC_CompanionCommandFlavorDefinitions.lua",
    "PNC/Core/Commands/PNC_CompanionCommandFlavorDefinitions_Core.lua",
    "PNC/Core/Commands/PNC_CompanionCommandFlavorDefinitions_Base.lua",
    "PNC/Core/Commands/PNC_CompanionCommandFlavorDefinitions_TypedA.lua",
    "PNC/Core/Commands/PNC_CompanionCommandFlavorDefinitions_TypedB.lua",
}
for _, relative in ipairs(legacyFiles) do
    T.truthy(absent(relative), "retired command wording file remains: " .. relative)
end

T.falsy(PNC.CompanionCommandFlavor,
    "retired companion command wording registry is still present")
T.falsy(string.find(
    read(T.path("ProjectHoomans", "shared",
        "PNC/Composition/PNC_SharedComposition_Final.lua")),
    "CompanionCommandFlavor",
    1,
    true
), "shared composition still loads the retired wording registry")

local playerCommand = PNC.Semantics.CompanionSpeech.ResolvePlayerCommand(
    "follow",
    "valid",
    {
        eventID = "p10b-command",
        npcID = "npc-one",
        renderTokens = { name = "Mara", names = "Mara" },
    }
)
T.truthy(playerCommand, "player command has no semantic realization")
T.truthy(string.find(playerCommand.realizationID,
    "semantic.command.player.follow", 1, true),
    "player command meaning was not selected by ResponseCatalog")
T.equal(playerCommand.responsePlanID, "semantic.command.player",
    "player command response plan changed")
T.equal(playerCommand.contentOwner,
    "projecthoomans.dialogue_content.commands_emotes",
    "player command wording is not Dialogue Content-owned")
T.truthy(string.find(playerCommand.fallback, "Mara", 1, true),
    "player command content did not render semantic tokens")

local npcReply = PNC.Semantics.CompanionSpeech.ResolveNPCCommand(
    "camp",
    "invalid",
    { eventID = "p10b-reply", npcID = "npc-one" }
)
T.truthy(npcReply, "NPC command reply has no semantic realization")
T.equal(npcReply.realizationID, "semantic.command.reply.camp_rejected",
    "NPC command rejection was not selected by ResponseCatalog")
T.equal(npcReply.responsePlanID, "semantic.command.reply",
    "NPC command reply response plan changed")
T.falsy(npcReply.compatibilityFlavorID,
    "NPC command reply still carries a wording-registry alias")

local playerEmote = PNC.Semantics.CompanionSpeech.ResolvePlayerEmote(
    "wavehi",
    {
        eventID = "p10b-emote",
        npcID = "player:one",
        renderTokens = { names = "Mara" },
    }
)
T.equal(playerEmote.realizationID, "semantic.emote.player.wavehi",
    "player emote meaning changed")
T.equal(playerEmote.responsePlanID, "semantic.emote.player",
    "player emote response plan changed")
T.equal(playerEmote.contentOwner,
    "projecthoomans.dialogue_content.commands_emotes",
    "player emote wording is not Dialogue Content-owned")
T.truthy(string.find(playerEmote.fallback, "Mara", 1, true),
    "player emote content did not render semantic tokens")
T.falsy(playerEmote.compatibilityFlavorID,
    "player emote still carries a wording-registry alias")

local greeting = PNC.Semantics.CompanionSpeech.ResolveGreeting({
    eventID = "p10b-greeting",
    npcID = "npc-one",
    npcType = "neutral",
    relationshipTier = "warm",
    greetingState = "first",
    socialStyle = "friendly",
})
T.truthy(greeting, "greeting has no semantic realization")
T.equal(greeting.responsePlanID, "semantic.flow.greeting.opening",
    "greeting meaning was not selected by ResponseCatalog")
T.truthy(string.find(greeting.realizationID,
    "semantic.flow.greeting.opening", 1, true),
    "greeting realization is not semantic-owned")
T.equal(greeting.contentOwner,
    "projecthoomans.dialogue_content.commands_emotes",
    "greeting wording is not Dialogue Content-owned")

local dog = PNC.Semantics.SocialReactions.Resolve({
    eventType = "companion_dog_feed",
    eventID = "p10b-dog",
    npcID = "dog-npc",
    context = {
        eventType = "companion_dog_feed",
        eventID = "p10b-dog",
        companionDogSex = "male",
        companionDogFed = true,
        factRefs = { "p10b-dog" },
        semanticEventFacts = {
            ["p10b-dog"] = {
                eventRef = "p10b-dog",
                authoritative = true,
                disclosure = "player",
                happened = "the companion dog was fed",
            },
        },
    },
})
T.truthy(dog, "Companion Dogs event has no semantic realization")
T.equal(dog.realizationID, "semantic.compat.companion_dogs.feed.male",
    "Companion Dogs wording was not selected by semantic compatibility pool")
T.truthy(dog.semanticOwned ~= false,
    "Companion Dogs realization is not marked semantic-owned")

T.finish("pnc_unified_authority_p10b_companion_command_absence_smoke")
