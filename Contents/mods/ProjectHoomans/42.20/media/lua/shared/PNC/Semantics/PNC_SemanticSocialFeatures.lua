PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Features = PNC.Semantics.SocialFeatures or {}
PNC.Semantics.SocialFeatures = Features

Features.VERSION = 1
Features.MAX_EVIDENCE = 8

local INTENSITY = {
    none = 0,
    mild = 0.25,
    moderate = 0.50,
    high = 0.78,
    critical = 1.00,
}

local ACTS = {
    INSULT = {
        valence = -0.95,
        hostility = 0.95,
        contempt = 0.90,
        affiliation = -0.80,
    },
    HOSTILE_REMARK = {
        valence = -0.90,
        hostility = 0.85,
        contempt = 0.55,
        affiliation = -0.70,
    },
    THREATEN = {
        valence = -1.00,
        hostility = 1.00,
        threat = 1.00,
        contempt = 0.45,
        affiliation = -0.90,
    },
    COMPLIMENT = {
        valence = 0.90,
        hostility = 0,
        affiliation = 0.90,
    },
    THANK = {
        valence = 0.75,
        hostility = 0,
        affiliation = 0.80,
    },
    APOLOGIZE = {
        valence = 0.20,
        hostility = 0,
        affiliation = 0.70,
        distress = 0.25,
    },
    AGREE = {
        valence = 0.35,
        affiliation = 0.45,
    },
    DISAGREE = {
        valence = -0.15,
        affiliation = -0.10,
    },
    COMPLAIN = {
        valence = -0.65,
        distress = 0.45,
    },
    SELF_REFLECTION = {
        valence = -0.45,
        distress = 0.40,
    },
}

local SELF_STATE_SUBJECTS = {
    HUNGER = true,
    THIRST = true,
    FATIGUE = true,
    WELLBEING = true,
}

local function clamp(value)
    value = tonumber(value) or 0
    if value < -1 then return -1 end
    if value > 1 then return 1 end
    return value
end

local function unit(value)
    value = tonumber(value) or 0
    if value < 0 then return 0 end
    if value > 1 then return 1 end
    return value
end

local function copyValue(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 8 then return nil end
    local output = {}
    for key, item in pairs(value) do
        output[key] = copyValue(item, depth + 1)
    end
    return output
end

local function appendEvidence(output, value)
    value = tostring(value or "")
    if value == "" or #output >= Features.MAX_EVIDENCE then return end
    for _, existing in ipairs(output) do
        if existing == value then return end
    end
    output[#output + 1] = value
end

local function conceptIDs(ir)
    local output = {}
    local analysis = type(ir.analysis) == "table" and ir.analysis or {}
    for _, symbol in ipairs(
        type(analysis.symbols) == "table" and analysis.symbols or {}
    ) do
        if type(symbol) == "table" and type(symbol.id) == "string" then
            output[symbol.id] = true
        end
    end
    return output
end

local function directedness(ir, social)
    if social.selfDirected == true or tostring(social.target or "") == "SELF"
        or tostring(ir.subject or "") == "SELF"
        or SELF_STATE_SUBJECTS[tostring(ir.subject or "")]
    then
        return "SELF"
    end
    if social.worldDirected == true or tostring(social.target or "") == "WORLD"
        or tostring(ir.subject or "") == "WORLD"
    then
        return "WORLD"
    end
    if social.thirdParty == true
        or tostring(social.target or "") == "THIRD_PARTY"
    then
        return "THIRD_PARTY"
    end
    if social.directed == true or tostring(ir.subject or "") == "RECIPIENT" then
        return "RECIPIENT"
    end
    return "UNSPECIFIED"
end

function Features.Project(ir)
    if type(ir) ~= "table" then return nil end

    local act = tostring(ir.speechAct or ir.intent or "")
    local base = ACTS[act] or {}
    local social = type(ir.socialContext) == "table" and ir.socialContext or {}
    local emotional = type(ir.emotionalState) == "table"
        and ir.emotionalState or {}
    local concepts = conceptIDs(ir)
    local evidence = {}

    local output = {
        schemaVersion = Features.VERSION,
        kind = "semantic_social_features",
        directedness = directedness(ir, social),
        valence = tonumber(base.valence) or 0,
        hostility = tonumber(base.hostility) or 0,
        affiliation = tonumber(base.affiliation) or 0,
        threat = tonumber(base.threat) or 0,
        contempt = tonumber(base.contempt) or 0,
        distress = tonumber(base.distress) or 0,
        intensity = INTENSITY[tostring(emotional.intensity or "")]
            or tonumber(emotional.intensity) or 0,
        profanity = concepts.PROFANITY == true,
        maliciousWish = social.maliciousWish == true,
        negatedNegative = social.negatedNegative == true,
        evidence = evidence,
    }

    if emotional.valence == "negative" then
        output.valence = math.min(output.valence, -0.50)
        appendEvidence(evidence, "emotional.valence:negative")
    elseif emotional.valence == "positive" then
        output.valence = math.max(output.valence, 0.50)
        appendEvidence(evidence, "emotional.valence:positive")
    end

    if social.hostility == "mild" then
        output.hostility = math.max(output.hostility, 0.30)
    elseif social.hostility == "moderate" then
        output.hostility = math.max(output.hostility, 0.55)
    elseif social.hostility == "high" then
        output.hostility = math.max(output.hostility, 0.82)
    elseif social.hostility == "critical" then
        output.hostility = 1
    elseif type(social.hostility) == "number" then
        output.hostility = math.max(output.hostility, social.hostility)
    end

    if social.affiliative == true then
        output.affiliation = math.max(output.affiliation, 0.65)
        appendEvidence(evidence, "social.affiliative")
    end

    if output.maliciousWish then
        output.valence = math.min(output.valence, -0.90)
        output.hostility = math.max(output.hostility, 0.88)
        -- Wishing harm is hostile but is not the same thing as asserting the
        -- speaker will personally cause that harm.
        output.threat = math.max(output.threat, 0.20)
        appendEvidence(evidence, "social.malicious_wish")
    end

    if output.negatedNegative then
        output.valence = math.max(output.valence, 0.35)
        output.hostility = math.min(output.hostility, 0.10)
        output.contempt = math.min(output.contempt, 0.10)
        output.affiliation = math.max(output.affiliation, 0.35)
        appendEvidence(evidence, "social.negated_negative")
    end

    if concepts.PROFANITY then appendEvidence(evidence, "concept:PROFANITY") end
    if concepts.INSULT then appendEvidence(evidence, "concept:INSULT") end
    if concepts.THREATEN then appendEvidence(evidence, "concept:THREATEN") end

    if SELF_STATE_SUBJECTS[tostring(ir.subject or "")] then
        output.valence = math.min(output.valence, -0.20)
        output.distress = math.max(output.distress, 0.25)
        output.hostility = 0
        output.threat = 0
        output.contempt = 0
        appendEvidence(evidence, "subject:self_state")
    end

    if output.directedness == "WORLD" then
        -- Negative world/self language is not hostility toward the recipient.
        output.hostility = 0
        output.threat = 0
        output.contempt = 0
        appendEvidence(evidence, "directedness:WORLD")
    elseif output.directedness == "SELF" then
        output.hostility = 0
        output.threat = 0
        appendEvidence(evidence, "directedness:SELF")
    elseif output.directedness == "RECIPIENT" then
        appendEvidence(evidence, "directedness:RECIPIENT")
    end

    output.valence = clamp(output.valence)
    output.hostility = unit(output.hostility)
    output.affiliation = clamp(output.affiliation)
    output.threat = unit(output.threat)
    output.contempt = unit(output.contempt)
    output.distress = unit(output.distress)
    output.intensity = unit(output.intensity)
    return output
end

function Features.Annotate(ir)
    if type(ir) ~= "table" then return ir end
    ir.extensions = type(ir.extensions) == "table" and ir.extensions or {}
    ir.extensions.socialFeatures = Features.Project(ir)
    return ir
end

return Features
