-- Pure approval/respect presentation and action-requirement math.
-- Attitudes are derived labels; they are never persisted as emotion scores.

PNC = PNC or {}
PNC.RelationshipGraph = PNC.RelationshipGraph or {}

local Graph = PNC.RelationshipGraph

Graph.MINIMUM = -100
Graph.MAXIMUM = 100
Graph.NEUTRAL_BAND = 10
Graph.RECRUIT_APPROVAL_MINIMUM = 25
Graph.RECRUIT_RESPECT_MINIMUM = 35
Graph.RECRUIT_SCORE_THRESHOLD = 70
Graph.RECRUIT_LOYALTY_PENALTY = 20
Graph.RECRUIT_FEAR_APPROVAL_MAXIMUM = -30
Graph.RECRUIT_FEAR_RESPECT_MINIMUM = 70
Graph.RECRUIT_FEAR_SCORE_THRESHOLD = 60
Graph.RECRUIT_FEAR_BRAVERY_MAXIMUM = 0.85
Graph.Requirements = Graph.Requirements or {}

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        value = tonumber(fallback) or 0
    end
    return value
end

local function clamp(value, minimum, maximum)
    return math.max(
        minimum,
        math.min(maximum, finite(value, 0))
    )
end

local function copy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, item in pairs(value) do
        output[key] = copy(item)
    end
    return output
end

local function safeID(value)
    return type(value) == "string"
        and value ~= ""
        and #value <= 96
        and string.match(value, "^[%w_%-]+$") ~= nil
end

local function personalityPolicy(personality, context)
    local Policy = PNC.RecruitmentPersonalityPolicy
    if Policy and Policy.Evaluate then
        return Policy.Evaluate(personality, context)
    end

    -- Keep isolated legacy tests and partial load orders behavior-compatible.
    local loyalty = clamp(personality and personality.loyalty, 0, 1)
    local bravery = clamp(personality and personality.bravery, 0, 1)
    local loyaltyPenalty = loyalty * finite(
        context and context.loyaltyPenaltyScale,
        Graph.RECRUIT_LOYALTY_PENALTY
    )
    local braveryPenalty = bravery * finite(
        context and context.fearBraveryPenaltyScale,
        25
    )
    return {
        version = 0,
        loyalty = loyalty,
        bravery = bravery,
        loyaltyPenalty = loyaltyPenalty,
        braveryPenalty = braveryPenalty,
        admire = { scoreModifier = -loyaltyPenalty, modifiers = {} },
        fear = {
            scoreModifier = -loyaltyPenalty - braveryPenalty,
            modifiers = {},
        },
    }
end

local function rawNPCPersonality(record)
    if type(record) ~= "table" then return {} end
    if type(record.personality) == "table" then
        return record.personality
    end
    if type(record.socialProfile) == "table" then
        if type(record.socialProfile.personality) == "table" then
            return record.socialProfile.personality
        end
        return record.socialProfile
    end
    if type(record.social) == "table"
        and type(record.social.personality) == "table"
    then
        return record.social.personality
    end
    return {}
end

function Graph.ResolveNPCPersonality(record)
    local raw = rawNPCPersonality(record)
    local Types = PNC.SocialProfileTypes
    if Types and Types.NormalizeNPCPersonality then
        local identity = type(record) == "table"
            and type(record.identity) == "table" and record.identity or {}
        local social = type(record) == "table"
            and type(record.social) == "table" and record.social or {}
        return Types.NormalizeNPCPersonality(
            raw,
            record and (record.identitySeed or identity.seed),
            record and (record.archetypeID or identity.archetypeID),
            social.personalityOverrides
        )
    end
    return raw
end

function Graph.Clamp(value)
    return clamp(value, Graph.MINIMUM, Graph.MAXIMUM)
end

function Graph.ClassifyAxis(value, neutralBand)
    value = Graph.Clamp(value)
    neutralBand = clamp(
        neutralBand,
        0,
        50
    )
    if neutralBand == 0 then
        neutralBand = Graph.NEUTRAL_BAND
    end
    if value >= neutralBand then return 1 end
    if value <= -neutralBand then return -1 end
    return 0
end

function Graph.ResolveAttitude(
    approval,
    respect,
    neutralBand
)
    local approvalAxis =
        Graph.ClassifyAxis(approval, neutralBand)
    local respectAxis =
        Graph.ClassifyAxis(respect, neutralBand)
    if approvalAxis > 0 and respectAxis > 0 then
        return "admire"
    end
    if approvalAxis > 0 and respectAxis < 0 then
        return "pity"
    end
    if approvalAxis < 0 and respectAxis > 0 then
        return "fear"
    end
    if approvalAxis < 0 and respectAxis < 0 then
        return "despise"
    end
    if approvalAxis > 0 then return "sympathetic" end
    if approvalAxis < 0 then return "dislikes" end
    if respectAxis > 0 then return "impressed" end
    if respectAxis < 0 then return "dismissive" end
    return "indifferent"
end

function Graph.NormalizeRequirement(value, fallbackID)
    local source = type(value) == "table" and value or {}
    local id = safeID(source.id) and source.id
        or safeID(fallbackID) and fallbackID or nil
    if not id then return nil end
    local label = type(source.label) == "string"
        and source.label ~= "" and string.sub(source.label, 1, 96)
        or id
    local description = type(source.description) == "string"
        and string.sub(source.description, 1, 256) or ""
    local minimumApproval = source.minimumApproval ~= nil
        and clamp(source.minimumApproval, -100, 100) or nil
    local minimumRespect = source.minimumRespect ~= nil
        and clamp(source.minimumRespect, -100, 100) or nil
    return {
        id = id,
        label = label,
        description = description,
        enabled = source.enabled ~= false,
        approvalWeight = clamp(
            source.approvalWeight,
            -2,
            2
        ),
        respectWeight = clamp(
            source.respectWeight,
            -2,
            2
        ),
        threshold = clamp(
            source.threshold,
            -200,
            200
        ),
        minimumApproval = minimumApproval,
        minimumRespect = minimumRespect,
        deterministic = source.deterministic == true,
    }
end

function Graph.RegisterRequirement(id, value)
    local normalized = Graph.NormalizeRequirement(value, id)
    if not normalized then return false, "invalid_requirement" end
    Graph.Requirements[normalized.id] = normalized
    return true, "registered"
end

function Graph.GetRequirement(id)
    local value = Graph.Requirements[tostring(id or "")]
    return value and copy(value) or nil
end

function Graph.ListRequirements()
    local output = {}
    for _, requirement in pairs(Graph.Requirements) do
        output[#output + 1] = copy(requirement)
    end
    table.sort(output, function(left, right)
        if left.id == "inspect" then return true end
        if right.id == "inspect" then return false end
        return left.label < right.label
    end)
    return output
end

local function normalizeModifiers(values)
    local output = {}
    for index, value in ipairs(
        type(values) == "table" and values or {}
    ) do
        if type(value) == "table" then
            local amount = finite(value.value, 0)
            output[#output + 1] = {
                id = safeID(value.id) and value.id
                    or "modifier_" .. tostring(index),
                label = type(value.label) == "string"
                    and string.sub(value.label, 1, 128)
                    or "Context modifier",
                value = amount,
                tone = value.tone == "negative"
                    and "negative" or amount < 0
                    and "negative" or "positive",
            }
        end
    end
    return output
end

function Graph.Evaluate(
    approval,
    respect,
    requirement,
    context
)
    approval = Graph.Clamp(approval)
    respect = Graph.Clamp(respect)
    requirement = type(requirement) == "string"
        and Graph.GetRequirement(requirement)
        or Graph.NormalizeRequirement(
            requirement,
            requirement and requirement.id
        )
    requirement = requirement
        or Graph.GetRequirement("inspect")
    context = type(context) == "table" and context or {}
    local modifiers = normalizeModifiers(context.modifiers)
    local contextBonus = finite(context.bonus, 0)
    for _, modifier in ipairs(modifiers) do
        contextBonus = contextBonus + modifier.value
    end
    local baseScore =
        approval * requirement.approvalWeight
        + respect * requirement.respectWeight
    local finalScore = baseScore + contextBonus
    local meetsMinimums = (requirement.minimumApproval == nil
            or approval >= requirement.minimumApproval)
        and (requirement.minimumRespect == nil
            or respect >= requirement.minimumRespect)
    return {
        approval = approval,
        respect = respect,
        attitude = Graph.ResolveAttitude(
            approval,
            respect,
            context.neutralBand
        ),
        requirement = requirement,
        modifiers = modifiers,
        baseScore = baseScore,
        contextBonus = contextBonus,
        finalScore = finalScore,
        threshold = requirement.threshold,
        margin = finalScore - requirement.threshold,
        meetsMinimums = meetsMinimums,
        insideSuccessRegion = requirement.enabled
            and finalScore >= requirement.threshold
            and meetsMinimums or false,
    }
end

function Graph.EvaluateRecruitment(
    approval,
    respect,
    personality,
    context
)
    personality = type(personality) == "table" and personality or {}
    local policy = personalityPolicy(personality, {
        loyaltyPenaltyScale = Graph.RECRUIT_LOYALTY_PENALTY,
        fearBraveryPenaltyScale = 25,
    })
    local loyalty = policy.loyalty
    local bravery = policy.bravery
    local loyaltyPenalty = policy.loyaltyPenalty
    local graphContext = type(context) == "table" and copy(context) or {}
    graphContext.bonus = finite(graphContext.bonus, 0)
        + policy.admire.scoreModifier
    local evaluation = Graph.Evaluate(
        approval,
        respect,
        "recruit",
        graphContext
    )
    local fearScore = evaluation.respect * 0.70
        + math.max(0, -evaluation.approval) * 0.30
        + policy.fear.scoreModifier
    local normal = evaluation.insideSuccessRegion
    local fear = evaluation.approval <= Graph.RECRUIT_FEAR_APPROVAL_MAXIMUM
        and evaluation.respect >= Graph.RECRUIT_FEAR_RESPECT_MINIMUM
        and fearScore >= Graph.RECRUIT_FEAR_SCORE_THRESHOLD
        and bravery < Graph.RECRUIT_FEAR_BRAVERY_MAXIMUM
    return {
        approval = evaluation.approval,
        respect = evaluation.respect,
        attitude = evaluation.attitude,
        requirement = evaluation.requirement,
        score = evaluation.finalScore,
        baseScore = evaluation.baseScore,
        contextBonus = evaluation.contextBonus,
        threshold = evaluation.threshold,
        margin = evaluation.margin,
        meetsMinimums = evaluation.meetsMinimums,
        normal = normal,
        fear = fear,
        loyalty = loyalty,
        bravery = bravery,
        loyaltyPenalty = loyaltyPenalty,
        braveryPenalty = policy.braveryPenalty,
        personalityBreakdown = policy,
        admireScore = evaluation.finalScore,
        fearScore = fearScore,
        graph = evaluation,
    }
end

function Graph.RelationshipToNormalized(approval, respect)
    return {
        x = (Graph.Clamp(respect) - Graph.MINIMUM)
            / (Graph.MAXIMUM - Graph.MINIMUM),
        y = (Graph.MAXIMUM - Graph.Clamp(approval))
            / (Graph.MAXIMUM - Graph.MINIMUM),
    }
end

function Graph.RelationshipToScreen(
    approval,
    respect,
    x,
    y,
    width,
    height
)
    local point = Graph.RelationshipToNormalized(
        approval,
        respect
    )
    return finite(x, 0) + point.x * math.max(0, finite(width, 0)),
        finite(y, 0) + point.y
            * math.max(0, finite(height, 0))
end

function Graph.BoundaryApprovalAtRespect(
    respect,
    requirement,
    contextBonus
)
    requirement = type(requirement) == "string"
        and Graph.GetRequirement(requirement)
        or Graph.NormalizeRequirement(
            requirement,
            requirement and requirement.id
        )
    if not requirement
        or requirement.enabled == false
        or math.abs(requirement.approvalWeight) < 0.0001
    then
        return nil
    end
    respect = Graph.Clamp(respect)
    if requirement.minimumRespect ~= nil
        and respect < requirement.minimumRespect
    then
        return nil
    end
    local boundary = (
        requirement.threshold
        - finite(contextBonus, 0)
        - requirement.respectWeight * respect
    ) / requirement.approvalWeight
    if requirement.minimumApproval ~= nil then
        boundary = math.max(boundary, requirement.minimumApproval)
    end
    return boundary
end

local DEFAULTS = {
    {
        id = "inspect",
        label = "Relationship only",
        description = "Shows the current directed relationship.",
        enabled = false,
    },
    {
        id = "departure",
        label = "Disband threshold",
        description = "Shows the relationship line at which a colonist leaves.",
        enabled = false,
    },
    {
        id = "recruit",
        label = "Recruit",
        description = "Goodwill and recognized capability can both qualify.",
        approvalWeight = 0.45,
        respectWeight = 0.55,
        threshold = Graph.RECRUIT_SCORE_THRESHOLD,
        minimumApproval = Graph.RECRUIT_APPROVAL_MINIMUM,
        minimumRespect = Graph.RECRUIT_RESPECT_MINIMUM,
        deterministic = true,
    },
    {
        id = "request_mercy",
        label = "Ask for mercy",
        description = "Mostly approval; compassion and desperation are context.",
        approvalWeight = 0.80,
        respectWeight = 0.10,
        threshold = 30,
    },
    {
        id = "offer_less",
        label = "Offer less",
        description = "Goodwill and some respect support a reduced demand.",
        approvalWeight = 0.55,
        respectWeight = 0.25,
        threshold = 28,
    },
    {
        id = "challenge_extorter",
        label = "Try it",
        description = "Mostly respect and perceived threat, not affection.",
        approvalWeight = 0.10,
        respectWeight = 0.80,
        threshold = 35,
    },
    {
        id = "lie_about_supplies",
        label = "We barely have anything",
        description = "A relationship estimate; trust and deception remain contextual.",
        approvalWeight = 0.15,
        respectWeight = -0.05,
        threshold = 20,
    },
}

for _, definition in ipairs(DEFAULTS) do
    Graph.RegisterRequirement(definition.id, definition)
end

return Graph
