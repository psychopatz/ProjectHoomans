-- Pure approval/respect presentation and action-requirement math.
-- Attitudes are derived labels; they are never persisted as emotion scores.

PNC = PNC or {}
PNC.RelationshipGraph = PNC.RelationshipGraph or {}

local Graph = PNC.RelationshipGraph

Graph.MINIMUM = -100
Graph.MAXIMUM = 100
Graph.NEUTRAL_BAND = 10
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
        insideSuccessRegion = requirement.enabled
            and finalScore >= requirement.threshold or false,
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
    return (
        requirement.threshold
        - finite(contextBonus, 0)
        - requirement.respectWeight * Graph.Clamp(respect)
    ) / requirement.approvalWeight
end

local DEFAULTS = {
    {
        id = "inspect",
        label = "Relationship only",
        description = "Shows the current directed relationship.",
        enabled = false,
    },
    {
        id = "recruit",
        label = "Recruit",
        description = "Goodwill and recognized capability can both qualify.",
        approvalWeight = 0.55,
        respectWeight = 0.45,
        threshold = 35,
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
