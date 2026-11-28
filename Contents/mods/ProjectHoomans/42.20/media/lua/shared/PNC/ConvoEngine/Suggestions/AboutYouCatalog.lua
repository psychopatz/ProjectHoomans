-- Single source of truth for the "Tell me about yourself" (about_you)
-- knowledge-discovery subcategory hub and its relationship-gated facets.

local AboutYou = {}

AboutYou.HUB_ID = "about_you"
AboutYou.HUB_GROUP_ID = "semantic_hub.about_you"

AboutYou.ROOT_DEFINITION = {
    id = "question.about_you",
    topic = "about_you",
    order = 16,
    intent = "QUESTION",
    speechAct = "QUESTION",
    subject = "CONVERSATION_TOPIC",
    labelKey = "UI_PNC_Conversation_Choice_AboutYou",
    labelFallback = "Tell me about yourself.",
    utteranceKey = "UI_PNC_Conversation_Utterance_AboutYou",
    utteranceFallback = "Tell me about yourself.",
    extensions = {
        route = "semantic_hub",
        hubID = "about_you",
        topic = "about_you",
    },
}

-- All currently identifiable knowledge facets with familiarity gates matching
-- PNC_KnowledgeBuiltins.lua (0 / 10 / 20 / 25 / 50 / 75).
AboutYou.FACETS = {
    {
        id = "question.identity_nickname",
        facetKey = "nickname",
        descriptorID = "identity.nickname",
        topic = "identity_nickname",
        subject = "IDENTITY_NICKNAME",
        minFamiliarity = 0,
        order = 10,
        labelKey = "UI_PNC_Conversation_AboutYou_Nickname",
        labelFallback = "Do people call you anything else?",
        utteranceFallback = "Do people call you anything else?",
    },
    {
        id = "question.identity_faction",
        facetKey = "faction",
        descriptorID = "faction.identity",
        topic = "identity_faction",
        subject = "IDENTITY_FACTION",
        minFamiliarity = 0,
        order = 15,
        labelKey = "UI_PNC_Conversation_AboutYou_Faction",
        labelFallback = "Who are you with?",
        utteranceFallback = "Who are you with?",
    },
    {
        id = "question.identity_surname",
        facetKey = "surname",
        descriptorID = "identity.surname",
        topic = "identity_surname",
        subject = "IDENTITY_SURNAME",
        minFamiliarity = 20,
        order = 20,
        labelKey = "UI_PNC_Conversation_AboutYou_Surname",
        labelFallback = "What's your full name?",
        utteranceFallback = "What's your last name?",
    },
    {
        id = "question.backstory.former_job",
        facetKey = "backstory:former_job",
        descriptorID = "history.backstory.former_job",
        backstoryKind = "former_job",
        topic = "backstory",
        subject = "NPC_BACKSTORY",
        minFamiliarity = 25,
        order = 30,
        labelKey = "UI_PNC_Conversation_AboutYou_FormerJob",
        labelFallback = "What did you do before all this?",
        utteranceFallback = "What did you do before the outbreak?",
    },
    {
        id = "question.backstory.hometown",
        facetKey = "backstory:hometown",
        descriptorID = "history.backstory.hometown",
        backstoryKind = "hometown",
        topic = "backstory",
        subject = "NPC_BACKSTORY",
        minFamiliarity = 25,
        order = 35,
        labelKey = "UI_PNC_Conversation_AboutYou_Hometown",
        labelFallback = "Where are you from?",
        utteranceFallback = "Where are you from?",
    },
    {
        id = "question.backstory.hobby",
        facetKey = "backstory:hobby",
        descriptorID = "history.backstory.hobby",
        backstoryKind = "hobby",
        topic = "backstory",
        subject = "NPC_BACKSTORY",
        minFamiliarity = 50,
        order = 40,
        labelKey = "UI_PNC_Conversation_AboutYou_Hobby",
        labelFallback = "What do you do to pass the time?",
        utteranceFallback = "What are your hobbies?",
    },
    {
        id = "question.backstory.education",
        facetKey = "backstory:education",
        descriptorID = "history.backstory.education",
        backstoryKind = "education",
        topic = "backstory",
        subject = "NPC_BACKSTORY",
        minFamiliarity = 50,
        order = 45,
        labelKey = "UI_PNC_Conversation_AboutYou_Education",
        labelFallback = "Did you study anything before?",
        utteranceFallback = "What did you study?",
    },
    {
        id = "question.backstory.family_background",
        facetKey = "backstory:family_background",
        descriptorID = "history.backstory.family_background",
        backstoryKind = "family_background",
        topic = "backstory",
        subject = "NPC_BACKSTORY",
        minFamiliarity = 50,
        order = 50,
        labelKey = "UI_PNC_Conversation_AboutYou_Family",
        labelFallback = "Tell me about your family.",
        utteranceFallback = "Tell me about your family.",
    },
    {
        id = "question.backstory.value",
        facetKey = "backstory:value",
        descriptorID = "history.backstory.value",
        backstoryKind = "value",
        topic = "backstory",
        subject = "NPC_BACKSTORY",
        minFamiliarity = 50,
        order = 55,
        labelKey = "UI_PNC_Conversation_AboutYou_Value",
        labelFallback = "What matters most to you?",
        utteranceFallback = "What matters most to you?",
    },
    {
        id = "question.backstory.date_of_birth",
        facetKey = "backstory:date_of_birth",
        descriptorID = "history.backstory.date_of_birth",
        backstoryKind = "date_of_birth",
        topic = "backstory",
        subject = "NPC_BACKSTORY",
        minFamiliarity = 50,
        order = 60,
        labelKey = "UI_PNC_Conversation_AboutYou_DateOfBirth",
        labelFallback = "When's your birthday?",
        utteranceFallback = "When is your birthday?",
    },
    {
        id = "question.backstory.survival_origin",
        facetKey = "backstory:survival_origin",
        descriptorID = "history.backstory.survival_origin",
        backstoryKind = "survival_origin",
        topic = "backstory",
        subject = "NPC_BACKSTORY",
        minFamiliarity = 75,
        order = 70,
        labelKey = "UI_PNC_Conversation_AboutYou_SurvivalOrigin",
        labelFallback = "How did you survive the outbreak?",
        utteranceFallback = "How did you survive the outbreak?",
    },
    {
        id = "question.backstory.fear",
        facetKey = "backstory:fear",
        descriptorID = "history.backstory.fear",
        backstoryKind = "fear",
        topic = "backstory",
        subject = "NPC_BACKSTORY",
        minFamiliarity = 75,
        order = 75,
        labelKey = "UI_PNC_Conversation_AboutYou_Fear",
        labelFallback = "What scares you most out here?",
        utteranceFallback = "What are you most afraid of?",
    },
    {
        id = "question.backstory.tragedy",
        facetKey = "backstory:tragedy",
        descriptorID = "history.backstory.tragedy",
        backstoryKind = "tragedy",
        topic = "backstory",
        subject = "NPC_BACKSTORY",
        minFamiliarity = 75,
        order = 80,
        labelKey = "UI_PNC_Conversation_AboutYou_Tragedy",
        labelFallback = "Did you lose anyone?",
        utteranceFallback = "Did you lose anyone when this started?",
    },
}

local FACET_BY_ID = {}
local FACET_BY_KEY = {}
for _, facet in ipairs(AboutYou.FACETS) do
    FACET_BY_ID[facet.id] = facet
    FACET_BY_KEY[facet.facetKey] = facet
end

function AboutYou.FindByID(id)
    return FACET_BY_ID[tostring(id or "")]
end

function AboutYou.FindByKey(key)
    return FACET_BY_KEY[tostring(key or "")]
end

function AboutYou.Familiarity(context)
    context = type(context) == "table" and context or {}
    local actor = type(context.actorConversationContext) == "table"
        and context.actorConversationContext or nil
    local rel = (actor and type(actor.relationship) == "table" and actor.relationship)
        or (type(context.relationship) == "table" and context.relationship)
        or (type(context.npcKnowledge) == "table" and type(context.npcKnowledge.relationship) == "table"
            and context.npcKnowledge.relationship)
        or nil
    local value = rel and (tonumber(rel.familiarity) or tonumber(rel.trust) or tonumber(rel.affinity))
        or tonumber(context.familiarity)
        or 0
    return math.max(0, value)
end

local function hasDescriptorFact(knowledge, descriptorID)
    if type(knowledge) ~= "table" or not descriptorID then return false end
    local facts = knowledge.facts or knowledge.descriptors
    if type(facts) == "table" and facts[descriptorID] ~= nil then
        return true
    end
    for _, category in ipairs(knowledge.categories or {}) do
        for _, entry in ipairs(category.facts or category.entries or {}) do
            if tostring(entry.id or entry.descriptorID or "") == descriptorID then
                return true
            end
        end
    end
    return false
end

function AboutYou.IsFacetKnown(context, facet)
    if type(facet) ~= "table" then return false end
    context = type(context) == "table" and context or {}
    local knowledge = type(context.npcKnowledge) == "table" and context.npcKnowledge
        or type(context.knowledge) == "table" and context.knowledge
        or {}
    local identity = type(knowledge.identity) == "table" and knowledge.identity or {}
    if facet.facetKey == "nickname" then
        return knowledge.nicknameKnown == true
            or (identity.nickname ~= nil and tostring(identity.nickname) ~= "")
            or (knowledge.knownNickname ~= nil and tostring(knowledge.knownNickname) ~= "")
    elseif facet.facetKey == "surname" then
        return knowledge.surnameKnown == true
            or (identity.surname ~= nil and tostring(identity.surname) ~= "")
            or (knowledge.knownSurname ~= nil and tostring(knowledge.knownSurname) ~= "")
    elseif facet.facetKey == "faction" then
        if knowledge.factionKnown == false then return false end
        return knowledge.factionKnown == true
            or (identity.factionName ~= nil and tostring(identity.factionName) ~= "")
            or (knowledge.factionName ~= nil and tostring(knowledge.factionName) ~= "")
            or (knowledge.factionID ~= nil and tostring(knowledge.factionID) ~= "")
    end
    return hasDescriptorFact(knowledge, facet.descriptorID)
end

-- Show unlocked facets plus the next familiarity tier (+25) so the player can
-- test boundaries and receive guarded refusal branches before unlocking deeper
-- personal questions, while hiding everything already known.
function AboutYou.IsVisibleInMenu(context, facet)
    if AboutYou.IsFacetKnown(context, facet) then return false end
    local familiarity = AboutYou.Familiarity(context)
    return (tonumber(facet.minFamiliarity) or 0) <= familiarity + 25
end

function AboutYou.HasRemainingFacets(context)
    for _, facet in ipairs(AboutYou.FACETS) do
        if AboutYou.IsVisibleInMenu(context, facet) then
            return true
        end
    end
    return false
end

function AboutYou.BuildDefinition(facet)
    local slots = nil
    if facet.backstoryKind then
        slots = { backstoryKind = facet.backstoryKind }
    end
    return {
        id = facet.id,
        topic = facet.topic,
        hubID = AboutYou.HUB_ID,
        hubOnly = true,
        order = facet.order,
        intent = "QUESTION",
        speechAct = "QUESTION",
        subject = facet.subject,
        slots = slots,
        labelKey = facet.labelKey,
        labelFallback = facet.labelFallback,
        utteranceFallback = facet.utteranceFallback,
        extensions = {
            hubID = AboutYou.HUB_ID,
            aboutYouFacet = facet.facetKey,
            minFamiliarity = facet.minFamiliarity,
        },
    }
end

function AboutYou.CollectHubCandidates(Provider, context, hubCandidate)
    local output = {}
    local familiarity = AboutYou.Familiarity(context)
    for _, facet in ipairs(AboutYou.FACETS) do
        if AboutYou.IsVisibleInMenu(context, facet) then
            local unlocked = familiarity >= (tonumber(facet.minFamiliarity) or 0)
            local reason = unlocked
                and "about_you_facet_unlocked"
                or "about_you_facet_relationship_gated"
            local def = AboutYou.BuildDefinition(facet)
            local candidate = hubCandidate(Provider, def, reason, AboutYou.HUB_ID)
            output[#output + 1] = candidate
        end
    end
    return output
end

return AboutYou
