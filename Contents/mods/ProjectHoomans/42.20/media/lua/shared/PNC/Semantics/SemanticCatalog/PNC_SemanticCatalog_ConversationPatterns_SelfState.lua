-- First-person wellbeing and need-state pattern registration.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Catalog = PNC.Semantics.Catalog
local Internal = Catalog.Internal
local registerPattern = Internal.RegisterPattern

local SELF_STATE_PREFIXES = {
    { id = "im", tokens = { "i'm" } },
    { id = "i_am", tokens = { "i", "am" } },
    { id = "im_plain", tokens = { "im" } },
}

local SELF_WELLBEING_STATUSES = {
    { id = "fine", phrase = "fine", value = "fine", thankYou = true },
    { id = "okay", phrase = "okay", value = "okay", thankYou = true },
    { id = "ok", phrase = "ok", value = "okay", thankYou = true },
    { id = "alright", phrase = "alright", value = "alright" },
    { id = "all_right", phrase = "all right", value = "all right" },
    { id = "good", phrase = "good", value = "good" },
}

local function selfStateSocialContext()
    return {
        directed = false,
        selfDirected = true,
        target = "SELF",
    }
end

local function registerSelfNeedPatterns(subject)
    local prefixIndex
    local tokenIndex
    local prefix
    local match
    local patternID
    for prefixIndex = 1, #SELF_STATE_PREFIXES do
        prefix = SELF_STATE_PREFIXES[prefixIndex]
        match = {}
        for tokenIndex = 1, #prefix.tokens do
            match[#match + 1] = {
                kind = "literal",
                value = prefix.tokens[tokenIndex],
            }
        end
        match[#match + 1] = {
            kind = "concept",
            id = subject,
            capture = "state",
        }
        patternID = "pnc.state.self_" .. string.lower(subject)
            .. "_" .. prefix.id
        registerPattern(patternID, match, {
            intent = "INFORM",
            speechAct = "INFORM",
            subject = subject,
            slots = {
                state = {
                    type = subject,
                    value = "$capture.state.text",
                },
            },
            socialContext = selfStateSocialContext(),
        }, 0.99, 180)
    end
end

local function registerSelfWellbeingPattern(prefix, status, thankYou)
    local thankYouText = thankYou
    if thankYou == true then
        thankYouText = "thank you"
    end
    local match = {}
    local tokenIndex
    for tokenIndex = 1, #prefix.tokens do
        match[#match + 1] = {
            kind = "literal",
            value = prefix.tokens[tokenIndex],
        }
    end
    match[#match + 1] = {
        kind = "literal",
        value = status.phrase,
    }
    if thankYouText then
        -- These exact suffixes keep the whole response anchored without
        -- stealing a standalone THANK utterance.
        match[#match + 1] = {
            kind = "literal",
            value = thankYouText,
        }
    end
    registerPattern(
        "pnc.state.self_wellbeing_" .. prefix.id .. "_" .. status.id
            .. (thankYouText and "_" .. string.gsub(thankYouText, " ", "_") or ""),
        match,
        {
            intent = "INFORM",
            speechAct = "INFORM",
            subject = "WELLBEING",
            slots = {
                state = {
                    type = "WELLBEING",
                    value = status.value,
                },
            },
            socialContext = selfStateSocialContext(),
        },
        0.99,
        190
    )
end

function Internal.RegisterSelfStatePatterns()
    -- Keep first-person claims ahead of the open-ended name capture. Exact
    -- prefix/state patterns consume the whole utterance, so clauses such as
    -- "I'm fine with that" cannot become wellbeing reports.
    registerSelfNeedPatterns("HUNGER")
    registerSelfNeedPatterns("THIRST")
    registerSelfNeedPatterns("FATIGUE")

    local prefixIndex
    local statusIndex
    local prefix
    local status
    for prefixIndex = 1, #SELF_STATE_PREFIXES do
        prefix = SELF_STATE_PREFIXES[prefixIndex]
        for statusIndex = 1, #SELF_WELLBEING_STATUSES do
            status = SELF_WELLBEING_STATUSES[statusIndex]
            registerSelfWellbeingPattern(prefix, status, false)
            if status.thankYou == true then
                registerSelfWellbeingPattern(prefix, status, "thank you")
                registerSelfWellbeingPattern(prefix, status, "thanks")
            end
        end
    end

    -- A reciprocal wellbeing question is distinct from the player's own
    -- state claim. Keeping its subject separate prevents the NPC wellbeing
    -- flow from opening a second pending question while the same local
    -- resolver still supplies the personality-grounded answer.
    local reciprocalPatterns = {
        {
            id = "pnc.question.wellbeing_reciprocal_how_about_you",
            match = {
                { kind = "literal", value = "how" },
                { kind = "literal", value = "about" },
                { kind = "literal", value = "you" },
            },
        },
        {
            id = "pnc.question.wellbeing_reciprocal_what_about_yourself",
            match = {
                { kind = "literal", value = "what" },
                { kind = "literal", value = "about" },
                { kind = "literal", value = "yourself" },
            },
        },
    }
    local reciprocalIndex
    local reciprocal
    for reciprocalIndex = 1, #reciprocalPatterns do
        reciprocal = reciprocalPatterns[reciprocalIndex]
        registerPattern(
            reciprocal.id,
            reciprocal.match,
            {
                intent = "QUESTION",
                speechAct = "QUESTION",
                subject = "WELLBEING_RECIPROCAL",
                target = "SELF",
                socialContext = {
                    directed = true,
                    informationalQuestion = true,
                    target = "SELF",
                    reciprocal = true,
                },
                extensions = {
                    dialogueFollowUp = "WELLBEING",
                    topic = "wellbeing",
                    reciprocal = true,
                },
            },
            0.99,
            191
        )
    end
end

return Internal

