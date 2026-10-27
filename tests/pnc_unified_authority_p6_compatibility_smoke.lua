local T = require "tests/support/test"

T.addPackagePaths()

-- Compatibility selection must work without loading any first-party
-- SocialFlavor definition shard.  The external adapter supplies facts; the
-- Hoomans semantic catalog selects the response and its bounded plan.
PNC = { Semantics = {} }
require "PsychopatzCore/Semantics/PsychopatzSemantic"
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueResponseCatalog.lua"
)
local Reactions = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticSocialReaction.lua"
)

T.falsy(PNC.SocialFlavorDefinitions,
    "compatibility selection does not require first-party Flavor definitions")
T.falsy(
    package.loaded[
        "PNC/Compatibility/Mods/ProjectALife/PNC_ProjectALife_FlavorDefinitions"
    ],
    "Project A-Life semantic selection does not load its legacy definitions"
)

local function fact(eventRef, values)
    values = values or {}
    values.eventRef = eventRef
    values.authoritative = true
    values.disclosure = "player"
    return { [eventRef] = values }
end

local function resolve(eventType, eventID, context)
    context = context or {}
    context.eventType = eventType
    context.eventRef = eventID
    context.eventID = eventID
    context.factRefs = context.factRefs or { eventID }
    context.semanticEventFacts = context.semanticEventFacts
        or fact(eventID, { summary = "an authoritative compatibility event" })
    local result = Reactions.Resolve({
        eventType = eventType,
        eventID = eventID,
        npcID = "npc-p6",
        context = context,
    })
    T.truthy(result, eventType .. " selects a semantic compatibility response")
    T.truthy(result.fallback and result.fallback ~= "",
        eventType .. " carries selected wording")
    T.truthy(result.responsePlan,
        eventType .. " carries a ResponsePlan")
    T.equal(result.contentOwner,
        "projecthoomans.dialogue_content.compatibility",
        eventType .. " exposes the compatibility content owner")
    T.falsy(string.find(result.fallback, "compat.", 1, true),
        eventType .. " does not expose a legacy Flavor key")
    return result
end

local bandit = resolve("bandit_attack", "event:p6:bandit", {
    socialRole = "colonist",
    compatibilitySource = "bandits",
    semanticEventFacts = fact("event:p6:bandit", {
        summary = "a Bandits attacker hurt a teammate",
        happened = "a teammate was hurt by bandit fire",
        attacker = "bandit",
    }),
})
T.equal(bandit.realizationFamily,
    "semantic.compat.bandits.hooman_hurt",
    "Bandits damage uses the explicit compatibility semantic pool")
T.equal(#(bandit.offerIDs or {}), 2,
    "Bandits exposes only grounded event and attacker follow-ups")

local mask = resolve("necroa_mask_removed", "event:p6:mask", {
    socialRole = "family",
    semanticEventFacts = fact("event:p6:mask", {
        summary = "a survivor removed their mask",
        happened = "a survivor removed their mask",
    }),
})
T.equal(mask.realizationFamily,
    "semantic.compat.necroa.mask_warning",
    "Necroa NPC exposure uses the explicit semantic safety pool")
T.equal(#(mask.offerIDs or {}), 1,
    "Necroa warning exposes one grounded follow-up")

local playerMask = resolve(
    "necroa_player_mask_removed",
    "event:p6:player-mask",
    {
        socialRole = "lover",
        semanticEventFacts = fact("event:p6:player-mask", {
            summary = "the player removed their mask",
            happened = "the player removed their mask",
        }),
    }
)
T.equal(playerMask.realizationFamily,
    "semantic.compat.necroa.player_mask_removed",
    "Necroa player exposure uses the explicit semantic safety pool")

local meta = resolve("projectalife_meta", "event:p6:meta", {
    projectALifeKind = "gunfire",
    semanticEventFacts = fact("event:p6:meta", {
        summary = "gunfire was heard nearby",
        happened = "gunfire was heard nearby",
        location = "nearby",
    }),
})
T.equal(meta.realizationFamily,
    "semantic.compat.projectalife.meta",
    "Project A-Life meta speech uses the explicit semantic pool")
T.equal(meta.realizationID,
    "semantic.compat.projectalife.meta.gunfire",
    "Project A-Life meta kind selects the matching semantic variant")

local encounter = resolve("projectalife_encounter", "event:p6:encounter", {
    projectALifeStance = "hostile",
    semanticEventFacts = fact("event:p6:encounter", {
        summary = "a hostile encounter was observed nearby",
        happened = "a hostile encounter was observed nearby",
        location = "nearby",
    }),
})
T.equal(encounter.realizationID,
    "semantic.compat.projectalife.encounter.hostile",
    "Project A-Life encounter stance selects the matching variant")

local faction = resolve(
    "projectalife_faction_conflict",
    "event:p6:faction",
    {
        projectALifeConflictDirection = "outgoing",
        semanticEventFacts = fact("event:p6:faction", {
            summary = "the faction conflict moved against that faction",
            happened = "the group struck that faction",
            factionName = "the raiders",
        }),
    }
)
T.equal(faction.realizationID,
    "semantic.compat.projectalife.faction.outgoing",
    "Project A-Life faction direction selects the matching variant")

local dog = resolve("companion_dog_feed", "event:p6:dog", {
    companionDogSex = "male",
    companionDogFed = true,
    semanticEventFacts = fact("event:p6:dog", {
        summary = "the companion dog was fed",
        happened = "the companion dog was fed",
    }),
})
T.equal(dog.realizationFamily,
    "semantic.compat.companion_dogs.feed",
    "Companion Dogs feed speech uses the explicit semantic pool")
T.equal(dog.realizationID,
    "semantic.compat.companion_dogs.feed.male",
    "Companion Dogs sex selects the matching semantic variant")

T.truthy(PNC.Semantics.ResponseCatalog.Get(
    "semantic.compat.bandits.hooman_hurt"
), "Bandits pool is registered in the production catalog")
T.truthy(PNC.Semantics.ResponseCatalog.Get(
    "semantic.compat.necroa.mask_warning"
), "Necroa pool is registered in the production catalog")
T.truthy(PNC.Semantics.ResponseCatalog.Get(
    "semantic.compat.projectalife.meta"
), "Project A-Life pool is registered in the production catalog")
T.truthy(PNC.Semantics.ResponseCatalog.Get(
    "semantic.compat.companion_dogs.greeting"
), "Companion Dogs pool is registered in the production catalog")

-- Exercise the real Project A-Life presenter without its legacy definition
-- module.  The presenter must enqueue the already-selected semantic packet.
local received
PNC.Compatibility = {
    ProjectALifeEvents = {},
}
PNC.SemanticSpeechPresentation = {
    Receive = function(payload)
        received = payload
        return true
    end,
}
PNC.CompanionTargetResolver = {
    CollectNearbyCompanions = function()
        return {
            {
                id = "npc-p6-presenter",
                source = {
                    x = 0,
                    y = 0,
                    z = 0,
                    socialRole = "colonist",
                },
            },
        }
    end,
}
getSpecificPlayer = function()
    return {
        getX = function() return 0 end,
        getY = function() return 0 end,
        getZ = function() return 0 end,
    }
end
local normalizedClient = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Compatibility/Mods/ProjectALife/PNC_ProjectALife_EventNormalizer.lua"
)
normalizedClient.seen = {}
normalizedClient.lastAccepted = {}
T.load(
    "ProjectHoomans",
    "client",
    "PNC/Compatibility/Mods/ProjectALife/PNC_ProjectALife_EventPresenter.lua"
)
T.truthy(normalizedClient.HandleAdapterEvent({
    event = "projectalife_meta_event",
    context = {
        eventId = "p6-presenter",
        kind = "gunfire",
        x = 0,
        y = 0,
        z = 0,
    },
}), "Project A-Life presenter accepts a semantic event")
T.truthy(received and received.semanticOwned,
    "Project A-Life presenter enqueues a semantic-owned packet")
T.equal(received.poolID, "semantic.compat.projectalife.meta",
    "Project A-Life presenter carries the semantic response pool")
T.equal(received.source.kind, "semantic_speech",
    "Project A-Life presenter does not fall through legacy prose")
T.truthy(received.text and received.text ~= "",
    "Project A-Life presenter carries selected wording")
T.falsy(
    package.loaded[
        "PNC/Compatibility/Mods/ProjectALife/PNC_ProjectALife_FlavorDefinitions"
    ],
    "Project A-Life presenter never loads its legacy prose definition module"
)

T.finish("pnc_unified_authority_p6_compatibility_smoke")
