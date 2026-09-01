local T = require "tests/support/test"

local SHARED = T.path("ProjectHoomans", "shared", "")
local CLIENT = T.path("ProjectHoomans", "client", "")
local SERVER = T.path("ProjectHoomans", "server", "")
T.addPackagePaths()

local records = {
    companion = {
        id = "npc-companion",
        recruited = true,
        alive = true,
        presenceState = "live",
        x = 4,
        y = 0,
        z = 0,
    },
    neutral = {
        id = "npc-neutral",
        recruited = false,
        alive = true,
        presenceState = "live",
        x = 7,
        y = 0,
        z = 0,
    },
}
local liveBodies = {}
local appliedEffects = {}
local relationships = {}
local relationshipBroadcasts = {}

local function relationshipFor(npcID)
    relationships[npcID] = relationships[npcID] or {
        approval = 35,
        respect = 10,
        familiarity = 0,
        memories = {},
        cooldowns = {},
        revision = 1,
    }
    return relationships[npcID]
end

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        COMPANION_COMMAND_RADIUS = 20,
        CMD_PLAYER_EMOTE_INTERACTION = "PlayerEmoteInteraction",
    },
    Core = {
        Now = function() return 1000 end,
        IsAuthority = function() return true end,
    },
    Network = {
        ClientState = { snapshots = {} },
        SendPlayerEmoteInteractionResult = function() return true end,
        SendConversationRelationship = function(_, summary, reason)
            relationshipBroadcasts[#relationshipBroadcasts + 1] = {
                summary = summary,
                reason = reason,
            }
            return true
        end,
    },
    CompanionCommands = {
        IsCompanion = function(source) return source.recruited == true end,
    },
    Registry = {
        ForEach = function(callback)
            for id, record in pairs(records) do callback(record, id) end
        end,
        ForEachLive = function(callback)
            for id, body in pairs(liveBodies) do
                callback(records[id], body, id)
            end
        end,
    },
    PlayerCharacters = {
        GetEntityKey = function() return "player:slot:character-1" end,
    },
    EntityRef = {
        ForNPC = function(id) return "npc:" .. tostring(id) end,
    },
    ServerCommandRouter = {
        Register = function(command, handler)
            PNC.ServerCommandRouter.handler = handler
            PNC.ServerCommandRouter.command = command
            return true
        end,
    },
    Relationships = {
        Get = function(npcID)
            return relationshipFor(npcID)
        end,
        ApplyConversationEffect = function(npcID, _, effect, context)
            local current = relationshipFor(npcID)
            local after = {
                approval = current.approval + (tonumber(effect.approval) or 0),
                respect = current.respect + (tonumber(effect.respect) or 0),
                familiarity = current.familiarity
                    + (tonumber(effect.familiarity) or 0),
                memories = current.memories,
                cooldowns = current.cooldowns,
                revision = current.revision + 1,
            }
            after.memories[#after.memories + 1] = {
                type = effect.memoryType,
                createdAt = 42,
            }
            current.approval = after.approval
            current.respect = after.respect
            current.familiarity = after.familiarity
            current.memories = after.memories
            current.revision = after.revision
            appliedEffects[#appliedEffects + 1] = {
                effect = effect,
                context = context,
            }
            return true, "applied", {
                relationship = after,
                memoryID = context.eventID,
                eventID = context.eventID,
                memoryType = effect.memoryType,
                interactionType = effect.interactionType,
            }
        end,
    },
}

getGameTime = function()
    return { getWorldAgeHours = function() return 42 end }
end

T.load(SHARED .. "PNC/Core/Commands/PNC_CompanionCommandFlavor.lua")
T.load(SHARED .. "PNC/Core/Commands/PNC_CompanionCommandFlavorDefinitions.lua")
T.load(SHARED .. "PNC/Core/Commands/PNC_VanillaEmoteInteractions.lua")
T.load(SHARED .. "PNC/Core/Relationships/PNC_SocialEventDefinitions.lua")
T.load(SHARED .. "PNC/Core/Conduct/PNC_ConductDefinitions.lua")

local Interactions = PNC.VanillaEmoteInteractions
local Flavor = PNC.CompanionCommandFlavor
local all = Interactions.List()
T.equal(#all, 8, "first vanilla emote slice has eight interactions")
for _, id in ipairs(all) do
    local definition = Interactions.Get(id)
    T.truthy(definition.eventType, id .. " event type")
    T.truthy(Flavor.Resolve(
        definition.flavorID,
        "player",
        id,
        { names = "Mara", name = "Mara", count = 1 }
    ), id .. " player flavor")
    T.truthy(Flavor.Resolve(
        Interactions.ReplyFlavorID(definition, { approval = 0 }),
        "npc",
        id
    ), id .. " NPC flavor")
end
T.contains(
    Flavor.Resolve("vanilla_emote_wavehi", "player", "seed", {
        names = "Mara and Ellis",
    }),
    "Mara and Ellis",
    "player flavor includes dynamic target names"
)
T.contains(
    Interactions.ReplyFlavorID(
        Interactions.Get("insult"),
        { approval = -40 }
    ),
    "hostile",
    "hostile relationship selects hard insult reply"
)
T.contains(
    Interactions.ReplyFlavorID(
        Interactions.Get("insult"),
        { approval = 35 }
    ),
    "familiar",
    "friendly relationship selects familiar insult reply"
)
T.equal(
    PNC.SocialEventDefinitions.player_emote_insult.cooldownHours,
    nil,
    "negative insult emote has no cooldown"
)
T.equal(
    PNC.SocialEventDefinitions.player_emote_thumbsdown.cooldownHours,
    nil,
    "negative thumbs-down emote has no cooldown"
)
T.truthy(
    Interactions.ReplyFlavorID(
        Interactions.Get("wavehi"),
        { approval = 80 },
        { npcType = "lover", greetingState = "first" }
    ) ~= Interactions.ReplyFlavorID(
        Interactions.Get("wavehi"),
        { approval = 80 },
        { npcType = "lover", greetingState = "returning" }
    ),
    "daily greeting uses distinct first and returning replies"
)
T.equal(
    Interactions.ResolveNPCType({ tacticalClass = "hostile" }),
    "hostile",
    "hostile NPC type is resolved from tactical class"
)
T.equal(
    Interactions.ResolveNPCType({
        tacticalClass = "neutral",
        generation = { relationshipKind = "lover" },
    }),
    "lover",
    "lover NPC type is resolved from the established relationship kind"
)
T.equal(
    Interactions.ResolveNPCType({
        tacticalClass = "neutral",
        generation = { relationshipKind = "mother" },
    }),
    "family",
    "family NPC type is resolved from the established relationship kind"
)
T.equal(
    Interactions.ResolveNPCType({ tacticalClass = "colonist" }),
    "colonist",
    "colonist NPC type is resolved from tactical class"
)
T.equal(
    Interactions.ResolveNPCType({ tacticalClass = "neutral" }),
    "neutral",
    "neutral NPC type remains the default"
)

T.load(CLIENT .. "PNC/Commands/PNC_CompanionTargetResolver.lua")
local player = {
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    isDead = function() return false end,
}
local social = PNC.CompanionTargetResolver.ResolveRecipients(
    player,
    "nearby",
    12,
    PNC.CompanionTargetResolver.SCOPE_SOCIAL
)
T.equal(#social.targets, 2, "social scope includes companions and other NPCs")
local colonists = PNC.CompanionTargetResolver.ResolveRecipients(
    player,
    "nearby",
    12,
    PNC.CompanionTargetResolver.SCOPE_COLONISTS
)
T.equal(#colonists.targets, 1, "colonist scope remains companion-only")

records["npc-neutral"] = records.neutral
liveBodies["npc-neutral"] = {
    isDead = function() return false end,
    getX = function() return 5 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}
local serverPlayer = {
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    isDead = function() return false end,
}
T.load(SERVER .. "PNC/Networking/Handlers/PNC_ServerPlayerEmoteInteractionCommandHandler.lua")
local result = PNC.PlayerEmoteInteractionAuthority.Handle(serverPlayer, {
    requestID = "request-1",
    emote = "insult",
    targets = { "forged-client-target" },
})
T.truthy(result.accepted, "authority accepts a live NPC interaction")
T.equal(#appliedEffects, 1,
    "authority applies one relationship effect through the shared API")
T.equal(appliedEffects[1].context.eventID,
    "conversation:vanilla_emote:player:slot:character-1:request-1:npc-neutral",
    "authority supplies an idempotent conversation event ID")
T.equal(result.targets[1].npcType, "neutral",
    "authority resolves the NPC type from the authoritative record")
T.equal(result.targets[1].replyFlavorID,
    "vanilla_emote_insult_npc_neutral",
    "authority selects a neutral-specific reply")
T.equal(#relationshipBroadcasts, 1,
    "authority broadcasts the live relationship presentation")

local greeting = PNC.PlayerEmoteInteractionAuthority.Handle(serverPlayer, {
    requestID = "request-greeting-1",
    emote = "wavehi",
})
T.truthy(greeting.accepted, "first daily greeting is accepted")
T.truthy(greeting.targets[1].applied,
    "first daily greeting applies its relationship effect")
local repeatedGreeting = PNC.PlayerEmoteInteractionAuthority.Handle(
    serverPlayer,
    { requestID = "request-greeting-2", emote = "wavehi" }
)
T.truthy(repeatedGreeting.accepted,
    "same-day greeting still receives an NPC reply")
T.equal(repeatedGreeting.targets[1].applied, false,
    "same-day greeting does not apply a second relationship effect")
T.equal(repeatedGreeting.targets[1].greetingState, "returning",
    "same-day greeting is marked as already greeted")
T.equal(#appliedEffects, 2,
    "same-day greeting does not duplicate the relationship mutation")

return T.finish("pnc_vanilla_emote_interactions_smoke")
