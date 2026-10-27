-- Semantic response pools for Project Hoomans compatibility adapters.
--
-- Provider/addon modules remain authoritative for event facts. This module
-- selects the bounded semantic response and joins it to Dialogue Content.

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

local function plan(poolID, act, topic, templateID, offers)
    return {
        dialogueAct = act,
        sourcePoolID = poolID,
        topic = topic,
        turns = {
            {
                segments = {
                    { kind = "translation", templateID = templateID },
                },
                offers = offers or {},
            },
        },
    }
end

local function variant(poolID, id, when, priority, templateID,
    offers, act, topic)
    local resolvedTemplateID = templateID or poolID .. "." .. id
    return {
        id = poolID .. "." .. id,
        templateID = resolvedTemplateID,
        when = when,
        priority = priority or 0,
        contentOwner = CONTENT_OWNER,
        plan = plan(
            poolID,
            act or "REACT",
            topic or "compatibility_event",
            resolvedTemplateID,
            offers
        ),
    }
end

Catalog.Register("semantic.compat.bandits.hooman_hurt", {
    variants = {
        variant(
            "semantic.compat.bandits.hooman_hurt",
            "colonist",
            { socialRole = "colonist" },
            4,
            "semantic.compat.bandits.hooman_hurt.colonist",
            eventOffers(true),
            "REACT",
            "bandits_hurt"
        ),
        variant(
            "semantic.compat.bandits.hooman_hurt",
            "lover",
            { socialRole = "lover" },
            4,
            "semantic.compat.bandits.hooman_hurt.lover",
            eventOffers(true),
            "REACT",
            "bandits_hurt"
        ),
        variant(
            "semantic.compat.bandits.hooman_hurt",
            "family",
            { socialRole = "family" },
            4,
            "semantic.compat.bandits.hooman_hurt.family",
            eventOffers(true),
            "REACT",
            "bandits_hurt"
        ),
        variant(
            "semantic.compat.bandits.hooman_hurt",
            "default",
            nil,
            0,
            "semantic.compat.bandits.hooman_hurt.default",
            eventOffers(true),
            "REACT",
            "bandits_hurt"
        ),
    },
})

local function necroaVariant(poolID, id, when, priority, templateID)
    return variant(
        poolID,
        id,
        when,
        priority,
        templateID,
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
            { socialRole = "family" },
            4,
            "semantic.compat.necroa.mask_warning.family"
        ),
        necroaVariant(
            "semantic.compat.necroa.mask_warning",
            "colonist",
            { socialRole = "colonist" },
            4,
            "semantic.compat.necroa.mask_warning.colonist"
        ),
        necroaVariant(
            "semantic.compat.necroa.mask_warning",
            "default",
            nil,
            0,
            "semantic.compat.necroa.mask_warning.default"
        ),
    },
})

Catalog.Register("semantic.compat.necroa.player_mask_removed", {
    variants = {
        necroaVariant(
            "semantic.compat.necroa.player_mask_removed",
            "hostile",
            { socialRole = "hostile" },
            4,
            "semantic.compat.necroa.player_mask_removed.hostile"
        ),
        necroaVariant(
            "semantic.compat.necroa.player_mask_removed",
            "lover",
            { socialRole = "lover" },
            4,
            "semantic.compat.necroa.player_mask_removed.lover"
        ),
        necroaVariant(
            "semantic.compat.necroa.player_mask_removed",
            "default",
            nil,
            0,
            "semantic.compat.necroa.player_mask_removed.default"
        ),
    },
})

local function projectMeta(id, kind, templateID)
    return variant(
        "semantic.compat.projectalife.meta",
        id,
        { projectALifeKind = kind },
        4,
        templateID,
        eventOffers(false),
        "WARN",
        "projectalife_meta"
    )
end

Catalog.Register("semantic.compat.projectalife.meta", {
    variants = {
        projectMeta(
            "gunfire",
            "gunfire",
            "semantic.compat.projectalife.meta.gunfire"
        ),
        projectMeta(
            "aircraft",
            "heli",
            "semantic.compat.projectalife.meta.aircraft.heli"
        ),
        projectMeta(
            "military",
            "military",
            "semantic.compat.projectalife.meta.aircraft.military"
        ),
        projectMeta(
            "crash",
            "crash",
            "semantic.compat.projectalife.meta.crash"
        ),
        projectMeta(
            "ambience",
            "ambience",
            "semantic.compat.projectalife.meta.ambience"
        ),
    },
})

local function projectEncounter(id, stance, templateID, priority)
    return variant(
        "semantic.compat.projectalife.encounter",
        id,
        { projectALifeStance = stance },
        priority or 4,
        templateID,
        eventOffers(false),
        "WARN",
        "projectalife_encounter"
    )
end

Catalog.Register("semantic.compat.projectalife.encounter", {
    variants = {
        projectEncounter(
            "friendly",
            "friendly",
            "semantic.compat.projectalife.encounter.friendly"
        ),
        projectEncounter(
            "hostile",
            { "hostile", "careful" },
            "semantic.compat.projectalife.encounter.hostile"
        ),
        projectEncounter(
            "unknown",
            { "unknown", "neutral" },
            "semantic.compat.projectalife.encounter.unknown",
            1
        ),
    },
})

local function projectFaction(id, eventType, stance, direction,
    templateID, priority)
    local when = { eventType = eventType }
    if stance then when.projectALifeStance = stance end
    if direction then when.projectALifeConflictDirection = direction end
    return variant(
        "semantic.compat.projectalife.faction",
        id,
        when,
        priority or 4,
        templateID,
        eventOffers(false),
        "WARN",
        "projectalife_faction"
    )
end

Catalog.Register("semantic.compat.projectalife.faction", {
    variants = {
        projectFaction(
            "hostile",
            "projectalife_faction_stance",
            { "hostile", "careful" },
            nil,
            "semantic.compat.projectalife.faction.hostile"
        ),
        projectFaction(
            "incoming",
            "projectalife_faction_conflict",
            nil,
            "incoming",
            "semantic.compat.projectalife.faction.incoming"
        ),
        projectFaction(
            "outgoing",
            "projectalife_faction_conflict",
            nil,
            "outgoing",
            "semantic.compat.projectalife.faction.outgoing"
        ),
    },
})

local function dogVariant(poolID, id, sex, templateID)
    return variant(
        poolID,
        id,
        { companionDogSex = sex },
        3,
        templateID,
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
            "male",
            "semantic.compat.companion_dogs.greeting.male"
        ),
        dogVariant(
            "semantic.compat.companion_dogs.greeting",
            "female",
            "female",
            "semantic.compat.companion_dogs.greeting.female"
        ),
        dogVariant(
            "semantic.compat.companion_dogs.greeting",
            "unknown",
            "unknown",
            "semantic.compat.companion_dogs.greeting.unknown"
        ),
    },
})

Catalog.Register("semantic.compat.companion_dogs.feed", {
    variants = {
        dogVariant(
            "semantic.compat.companion_dogs.feed",
            "male",
            "male",
            "semantic.compat.companion_dogs.feed.male"
        ),
        dogVariant(
            "semantic.compat.companion_dogs.feed",
            "female",
            "female",
            "semantic.compat.companion_dogs.feed.female"
        ),
        dogVariant(
            "semantic.compat.companion_dogs.feed",
            "unknown",
            "unknown",
            "semantic.compat.companion_dogs.feed.unknown"
        ),
    },
})

return true
