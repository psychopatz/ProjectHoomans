-- Semantic response pools for Project Hoomans compatibility adapters.
--
-- The provider/addon remains authoritative for the event and its facts.  This
-- file only chooses the Hoomans meaning/response family.  The old compatibility
-- Flavor registrations are retained as migration source material, but they
-- are not needed to select any pool below.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.ResponseCatalog
if type(Catalog) ~= "table" or type(Catalog.Register) ~= "function" then
    return false
end

local CONTENT_OWNER = "projecthoomans.dialogue_content.compatibility"

local function followUp(id, fallback, reference)
    return {
        id = "semantic.followup.compatibility." .. id,
        labelKey = "UI_PNC_SemanticFollowUp_" .. id,
        labelFallback = fallback,
        utteranceKey = "UI_PNC_SemanticFollowUp_" .. id,
        utteranceFallback = fallback,
        frame = {
            subject = "CONTEXT_REFERENCE",
            reference = reference,
        },
    }
end

local WHAT_HAPPENED = followUp(
    "happened",
    "What happened?",
    "EVENT_WHAT_HAPPENED"
)
local ATTACKER = followUp(
    "attacker",
    "Who hurt you?",
    "EVENT_ATTACKER"
)

local function eventOffers(includeAttacker)
    if includeAttacker then return { WHAT_HAPPENED, ATTACKER } end
    return { WHAT_HAPPENED }
end

local function plan(poolID, act, topic, text, offers)
    return {
        dialogueAct = act,
        sourcePoolID = poolID,
        topic = topic,
        turns = {
            {
                segments = {
                    { kind = "literal", text = text },
                },
                offers = offers or {},
            },
        },
    }
end

local function variant(poolID, id, text, when, priority, templateID,
    compatibilityFlavorID, offers, act, topic)
    return {
        id = poolID .. "." .. id,
        templateID = templateID or poolID .. "." .. id,
        fallback = text,
        when = when,
        priority = priority or 0,
        compatibilityFlavorID = compatibilityFlavorID,
        contentOwner = CONTENT_OWNER,
        plan = plan(
            poolID,
            act or "REACT",
            topic or "compatibility_event",
            text,
            offers
        ),
    }
end

-- Bandits' damage/actor event is external truth.  These variants replace the
-- old Hoomans compatibility prose selector for the same grounded event.
Catalog.Register("semantic.compat.bandits.hooman_hurt", {
    variants = {
        variant(
            "semantic.compat.bandits.hooman_hurt",
            "colonist",
            "Bandit fire! Pull back and cover the wounded colonist.",
            { socialRole = "colonist" },
            4,
            "semantic.compat.bandits.hooman_hurt.colonist",
            "compat.bandits.hooman_hurt",
            eventOffers(true),
            "REACT",
            "bandits_hurt"
        ),
        variant(
            "semantic.compat.bandits.hooman_hurt",
            "lover",
            "Bandit fire. Stay close; I have got you.",
            { socialRole = "lover" },
            4,
            "semantic.compat.bandits.hooman_hurt.lover",
            "compat.bandits.hooman_hurt",
            eventOffers(true),
            "REACT",
            "bandits_hurt"
        ),
        variant(
            "semantic.compat.bandits.hooman_hurt",
            "family",
            "Bandit fire! Stay together and cover the wounded family member.",
            { socialRole = "family" },
            4,
            "semantic.compat.bandits.hooman_hurt.family",
            "compat.bandits.hooman_hurt",
            eventOffers(true),
            "REACT",
            "bandits_hurt"
        ),
        variant(
            "semantic.compat.bandits.hooman_hurt",
            "default",
            "Bandit fire! Stay with the wounded survivor and watch the flank.",
            nil,
            0,
            "semantic.compat.bandits.hooman_hurt.default",
            "compat.bandits.hooman_hurt",
            eventOffers(true),
            "REACT",
            "bandits_hurt"
        ),
    },
})

local function necroaVariant(poolID, id, text, when, priority, templateID,
    compatibilityFlavorID)
    return variant(
        poolID,
        id,
        text,
        when,
        priority,
        templateID,
        compatibilityFlavorID,
        eventOffers(false),
        "WARN",
        "necroa_mask_safety"
    )
end

Catalog.Register("semantic.compat.necroa.mask_warning", {
    variants = {
        necroaVariant(
            "semantic.compat.necroa.mask_warning",
            "family",
            "Put your mask on, family. I am not losing you to the air.",
            { socialRole = "family" },
            4,
            "semantic.compat.necroa.mask_warning.family",
            "compat.necroa.mask_warning"
        ),
        necroaVariant(
            "semantic.compat.necroa.mask_warning",
            "colonist",
            "Mask up. We keep the camp safe together.",
            { socialRole = "colonist" },
            4,
            "semantic.compat.necroa.mask_warning.colonist",
            "compat.necroa.mask_warning"
        ),
        necroaVariant(
            "semantic.compat.necroa.mask_warning",
            "default",
            "Put your mask back on. Knox is airborne.",
            nil,
            0,
            "semantic.compat.necroa.mask_warning.default",
            "compat.necroa.mask_warning"
        ),
    },
})

Catalog.Register("semantic.compat.necroa.player_mask_removed", {
    variants = {
        necroaVariant(
            "semantic.compat.necroa.player_mask_removed",
            "hostile",
            "Put your mask back on before you become a problem.",
            { socialRole = "hostile" },
            4,
            "semantic.compat.necroa.player_mask_removed.hostile",
            "compat.necroa.player_mask_removed"
        ),
        necroaVariant(
            "semantic.compat.necroa.player_mask_removed",
            "lover",
            "Please put your mask back on, love. This air is not safe.",
            { socialRole = "lover" },
            4,
            "semantic.compat.necroa.player_mask_removed.lover",
            "compat.necroa.player_mask_removed"
        ),
        necroaVariant(
            "semantic.compat.necroa.player_mask_removed",
            "default",
            "Put your mask back on. The air is not safe.",
            nil,
            0,
            "semantic.compat.necroa.player_mask_removed.default",
            "compat.necroa.player_mask_removed"
        ),
    },
})

local function projectMeta(id, text, kind, templateID, flavorID)
    return variant(
        "semantic.compat.projectalife.meta",
        id,
        text,
        { projectALifeKind = kind },
        4,
        templateID,
        flavorID,
        eventOffers(false),
        "WARN",
        "projectalife_meta"
    )
end

Catalog.Register("semantic.compat.projectalife.meta", {
    variants = {
        projectMeta(
            "gunfire",
            "Someone is shooting nearby. Keep your head down.",
            "gunfire",
            "semantic.compat.projectalife.meta.gunfire",
            "projectalife.meta_gunfire"
        ),
        projectMeta(
            "aircraft",
            "Something is flying over us. Keep listening.",
            "heli",
            "semantic.compat.projectalife.meta.aircraft.heli",
            "projectalife.meta_aircraft"
        ),
        projectMeta(
            "military",
            "That aircraft sounds close. Stay sharp.",
            "military",
            "semantic.compat.projectalife.meta.aircraft.military",
            "projectalife.meta_aircraft"
        ),
        projectMeta(
            "crash",
            "That crash sounded close. Keep your eyes open.",
            "crash",
            "semantic.compat.projectalife.meta.crash",
            "projectalife.meta_crash"
        ),
        projectMeta(
            "ambience",
            "I do not like that sound. Stay close.",
            "ambience",
            "semantic.compat.projectalife.meta.ambience",
            "projectalife.meta_ambience"
        ),
    },
})

local function projectEncounter(id, text, stance, templateID, flavorID,
    priority)
    return variant(
        "semantic.compat.projectalife.encounter",
        id,
        text,
        { projectALifeStance = stance },
        priority or 4,
        templateID,
        flavorID,
        eventOffers(false),
        "WARN",
        "projectalife_encounter"
    )
end

Catalog.Register("semantic.compat.projectalife.encounter", {
    variants = {
        projectEncounter(
            "friendly",
            "Those survivors seem friendly. Keep your hands visible.",
            "friendly",
            "semantic.compat.projectalife.encounter.friendly",
            "projectalife.encounter_friendly"
        ),
        projectEncounter(
            "hostile",
            "That group looks hostile. Keep cover between us and them.",
            { "hostile", "careful" },
            "semantic.compat.projectalife.encounter.hostile",
            "projectalife.encounter_hostile"
        ),
        projectEncounter(
            "unknown",
            "Someone is out there. Let us watch before we approach.",
            { "unknown", "neutral" },
            "semantic.compat.projectalife.encounter.unknown",
            "projectalife.encounter_unknown",
            1
        ),
    },
})

local function projectFaction(id, text, eventType, stance, direction,
    templateID, flavorID, priority)
    local when = { eventType = eventType }
    if stance then when.projectALifeStance = stance end
    if direction then when.projectALifeConflictDirection = direction end
    return variant(
        "semantic.compat.projectalife.faction",
        id,
        text,
        when,
        priority or 4,
        templateID,
        flavorID,
        eventOffers(false),
        "WARN",
        "projectalife_faction"
    )
end

Catalog.Register("semantic.compat.projectalife.faction", {
    variants = {
        projectFaction(
            "hostile",
            "That faction may be hostile toward us now. Stay alert.",
            "projectalife_faction_stance",
            { "hostile", "careful" },
            nil,
            "semantic.compat.projectalife.faction.hostile",
            "projectalife.faction_hostile"
        ),
        projectFaction(
            "incoming",
            "They just opened fire on us. Stay close.",
            "projectalife_faction_conflict",
            nil,
            "incoming",
            "semantic.compat.projectalife.faction.incoming",
            "projectalife.faction_conflict_incoming"
        ),
        projectFaction(
            "outgoing",
            "We hit them. They may retaliate soon.",
            "projectalife_faction_conflict",
            nil,
            "outgoing",
            "semantic.compat.projectalife.faction.outgoing",
            "projectalife.faction_conflict_outgoing"
        ),
    },
})

local function dogVariant(poolID, id, text, sex, templateID, flavorID)
    return variant(
        poolID,
        id,
        text,
        { companionDogSex = sex },
        3,
        templateID,
        flavorID,
        nil,
        "ACK",
        "companion_dog"
    )
end

Catalog.Register("semantic.compat.companion_dogs.greeting", {
    variants = {
        dogVariant(
            "semantic.compat.companion_dogs.greeting",
            "male",
            "Who is a good boy?",
            "male",
            "semantic.compat.companion_dogs.greeting.male",
            "companion_dogs_good_boy"
        ),
        dogVariant(
            "semantic.compat.companion_dogs.greeting",
            "female",
            "Who is a good girl?",
            "female",
            "semantic.compat.companion_dogs.greeting.female",
            "companion_dogs_good_girl"
        ),
        dogVariant(
            "semantic.compat.companion_dogs.greeting",
            "unknown",
            "Who is a good dog?",
            "unknown",
            "semantic.compat.companion_dogs.greeting.unknown",
            "companion_dogs_good_dog"
        ),
    },
})

Catalog.Register("semantic.compat.companion_dogs.feed", {
    variants = {
        dogVariant(
            "semantic.compat.companion_dogs.feed",
            "male",
            "Here you go, good boy.",
            "male",
            "semantic.compat.companion_dogs.feed.male",
            "companion_dogs_feed_boy"
        ),
        dogVariant(
            "semantic.compat.companion_dogs.feed",
            "female",
            "Here you go, good girl.",
            "female",
            "semantic.compat.companion_dogs.feed.female",
            "companion_dogs_feed_girl"
        ),
        dogVariant(
            "semantic.compat.companion_dogs.feed",
            "unknown",
            "Here you go, good dog.",
            "unknown",
            "semantic.compat.companion_dogs.feed.unknown",
            "companion_dogs_feed_dog"
        ),
    },
})

return true
