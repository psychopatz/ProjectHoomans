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

local function plan(poolID, act, text)
    return {
        dialogueAct = act,
        sourcePoolID = poolID,
        topic = "medical_distress",
        turns = {
            {
                segments = {
                    { kind = "literal", text = text },
                },
                offers = MEDICAL_OFFERS,
            },
        },
    }
end

local function distressPool(poolID, act, lines)
    local variants = {}
    local function add(id, fallback, when, priority)
        variants[#variants + 1] = {
            id = poolID .. "." .. id,
            templateID = poolID .. "." .. id,
            fallback = fallback,
            when = when,
            priority = priority,
            plan = plan(poolID, act, fallback),
        }
    end
    add("mercy", lines.mercy, { downedNeed = "mercy" }, 8)
    add("bleedout", lines.bleedout, { downedNeed = "bleedout" }, 7)
    add("bandage", lines.bandage, { downedNeed = "bandage" }, 6)
    add("rescue", lines.rescue, { downedNeed = "rescue" }, 6)
    add("dehydration", lines.dehydration, { downedNeed = "dehydration" }, 6)
    add("starvation", lines.starvation, { downedNeed = "starvation" }, 6)
    add("exhaustion", lines.exhaustion, { downedNeed = "exhaustion" }, 6)
    add("default", lines.default, nil, 0)
    Catalog.Register(poolID, { variants = variants })
end

distressPool("semantic.medical.distress.call", "REQUEST", {
    mercy = "I am down. Please let me live.",
    bleedout = "I am bleeding out. I need a bandage now.",
    bandage = "I am hurt and down. Please patch me up.",
    rescue = "I cannot move. I need help over here.",
    dehydration = "I am too weak to move. I need water.",
    starvation = "I am too weak to move. I need food.",
    exhaustion = "I pushed too far. I need a moment to recover.",
    default = "I am down. I need help.",
})

distressPool("semantic.medical.distress.update", "REQUEST", {
    mercy = "I am still down. Please do not finish me.",
    bleedout = "The bleeding has not stopped. I still need a bandage.",
    bandage = "I am still down and waiting for a patch.",
    rescue = "I am still here. Please come back for me.",
    dehydration = "I still need water before I can move.",
    starvation = "I still need food before I can get up.",
    exhaustion = "I still need time to recover my strength.",
    default = "I am still down. I still need help.",
})

distressPool("semantic.medical.distress.repeat", "REQUEST", {
    mercy = "I am still asking you to spare me.",
    bleedout = "I am still losing blood. Please help.",
    bandage = "I still need these wounds patched.",
    rescue = "I am still down here. Do not leave me.",
    dehydration = "I still need water to recover.",
    starvation = "I still need something to eat.",
    exhaustion = "I still need a little more time to recover.",
    default = "I am not up yet. Please help me.",
})

Catalog.Register("semantic.medical.distress.teammate", {
    variants = {
        {
            id = "semantic.medical.distress.teammate.missing",
            templateID = "semantic.medical.distress.teammate.missing",
            fallback = "I am out of bandages. Can someone spare one for them?",
            when = { medicalBandageStatus = "missing" },
            priority = 5,
            plan = plan(
                "semantic.medical.distress.teammate",
                "REACT",
                "I am out of bandages. Can someone spare one for them?"
            ),
        },
        {
            id = "semantic.medical.distress.teammate.found",
            templateID = "semantic.medical.distress.teammate.found",
            fallback = "I found a bandage for them. Hold still while I patch them up.",
            when = { medicalBandageStatus = "found" },
            priority = 5,
            plan = plan(
                "semantic.medical.distress.teammate",
                "REACT",
                "I found a bandage for them. Hold still while I patch them up."
            ),
        },
        {
            id = "semantic.medical.distress.teammate.default",
            templateID = "semantic.medical.distress.teammate.default",
            fallback = "They are hurt. Stay with them while I cover you.",
            plan = plan(
                "semantic.medical.distress.teammate",
                "REACT",
                "They are hurt. Stay with them while I cover you."
            ),
        },
    },
})

Catalog.Register("semantic.medical.distress.treatment", {
    variants = {
        {
            id = "semantic.medical.distress.treatment.bandage",
            templateID = "semantic.medical.distress.treatment.bandage",
            fallback = "The wound is treated. I can move when you are ready.",
            when = { downedNeed = "bandage" },
            priority = 3,
            plan = {
                dialogueAct = "ACK",
                sourcePoolID = "semantic.medical.distress.treatment",
                topic = "medical",
                turns = {
                    {
                        segments = {
                            {
                                kind = "literal",
                                text = "The wound is treated. I can move when you are ready.",
                            },
                        },
                        offers = MEDICAL_OFFERS,
                    },
                },
            },
        },
        {
            id = "semantic.medical.distress.treatment.default",
            templateID = "semantic.medical.distress.treatment.default",
            fallback = "Thank you. That treatment helped.",
            plan = {
                dialogueAct = "ACK",
                sourcePoolID = "semantic.medical.distress.treatment",
                topic = "medical",
                turns = {
                    {
                        segments = {
                            { kind = "literal", text = "Thank you. That treatment helped." },
                        },
                        offers = MEDICAL_OFFERS,
                    },
                },
            },
        },
    },
})

return true
