PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.ResponseCatalog
if type(Catalog) ~= "table" or type(Catalog.Register) ~= "function" then
    return false
end

local function followUp(id, fallback, reference)
    return {
        id = "semantic.followup.event." .. id,
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

local MEDICAL_OFFERS = {
    followUp("happened", "What happened?", "EVENT_WHAT_HAPPENED"),
    followUp("attacker", "Who hurt you?", "EVENT_ATTACKER"),
    followUp("need", "What do you need?", "EVENT_NEED"),
}

local function plan(poolID, act, templateID, topic)
    return {
        dialogueAct = act,
        sourcePoolID = poolID,
        topic = topic or "medical_distress",
        turns = {
            {
                segments = {
                    { kind = "translation", templateID = templateID },
                },
                offers = MEDICAL_OFFERS,
            },
        },
    }
end

local function distressPool(poolID, act)
    local variants = {}
    local function add(id, when, priority)
        local templateID = poolID .. "." .. id
        variants[#variants + 1] = {
            id = templateID,
            templateID = templateID,
            when = when,
            priority = priority,
            plan = plan(poolID, act, templateID),
        }
    end
    add("mercy", { downedNeed = "mercy" }, 8)
    add("bleedout", { downedNeed = "bleedout" }, 7)
    add("bandage", { downedNeed = "bandage" }, 6)
    add("rescue", { downedNeed = "rescue" }, 6)
    add("dehydration", { downedNeed = "dehydration" }, 6)
    add("starvation", { downedNeed = "starvation" }, 6)
    add("exhaustion", { downedNeed = "exhaustion" }, 6)
    add("default", nil, 0)
    Catalog.Register(poolID, { variants = variants })
end

distressPool("semantic.medical.distress.call", "REQUEST")
distressPool("semantic.medical.distress.update", "REQUEST")
distressPool("semantic.medical.distress.repeat", "REQUEST")

Catalog.Register("semantic.medical.distress.teammate", {
    variants = {
        {
            id = "semantic.medical.distress.teammate.missing",
            templateID = "semantic.medical.distress.teammate.missing",
            when = { medicalBandageStatus = "missing" },
            priority = 5,
            plan = plan(
                "semantic.medical.distress.teammate",
                "REACT",
                "semantic.medical.distress.teammate.missing"
            ),
        },
        {
            id = "semantic.medical.distress.teammate.found",
            templateID = "semantic.medical.distress.teammate.found",
            when = { medicalBandageStatus = "found" },
            priority = 5,
            plan = plan(
                "semantic.medical.distress.teammate",
                "REACT",
                "semantic.medical.distress.teammate.found"
            ),
        },
        {
            id = "semantic.medical.distress.teammate.default",
            templateID = "semantic.medical.distress.teammate.default",
            plan = plan(
                "semantic.medical.distress.teammate",
                "REACT",
                "semantic.medical.distress.teammate.default"
            ),
        },
    },
})

Catalog.Register("semantic.medical.distress.treatment", {
    variants = {
        {
            id = "semantic.medical.distress.treatment.bandage",
            templateID = "semantic.medical.distress.treatment.bandage",
            when = { downedNeed = "bandage" },
            priority = 3,
            plan = plan(
                "semantic.medical.distress.treatment",
                "ACK",
                "semantic.medical.distress.treatment.bandage",
                "medical"
            ),
        },
        {
            id = "semantic.medical.distress.treatment.default",
            templateID = "semantic.medical.distress.treatment.default",
            plan = plan(
                "semantic.medical.distress.treatment",
                "ACK",
                "semantic.medical.distress.treatment.default",
                "medical"
            ),
        },
    },
})

return true
