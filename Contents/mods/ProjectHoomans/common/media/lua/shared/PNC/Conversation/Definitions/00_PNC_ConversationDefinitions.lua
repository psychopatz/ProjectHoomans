-- Reusable, data-only built-in conversation definitions.
-- Runtime interpretation belongs exclusively to Build 42.20.
local Registry = PNC and PNC.Conversation and PNC.Conversation.Registry
if not Registry then return false end

local MOD_ID = "ProjectHoomans"
local PREFIX = "projecthoomans:"

local function source(kind, audience, bundle)
    return {
        modID = MOD_ID,
        pathPattern = "media/conversation/" .. kind .. "/" .. audience
            .. "/{language}/" .. bundle .. ".json",
        domain = "pnc." .. kind .. "." .. audience .. "." .. bundle,
    }
end

local categorySource = source("system", "shared", "categories")
local categories = {
    { "greetings", "category.greetings", -100, true },
    { "whats_up", "category.whats_up", 100 },
    { "wellbeing", "category.wellbeing", 200 },
    { "small_talk", "category.small_talk", 300 },
    { "ask_about", "category.ask_about", 400 },
    { "needs", "category.needs", 500 },
    { "work_orders", "category.work_orders", 600 },
    { "trade", "category.trade", 700 },
    { "personal", "category.personal", 800 },
    { "relationship", "category.relationship", 900 },
    { "goodbye", "category.goodbye", 10000, true },
}

for _, value in ipairs(categories) do
    Registry.RegisterCategory(PREFIX .. value[1], {
        ownerModID = MOD_ID,
        labelKey = value[2],
        order = value[3],
        system = value[4] == true,
        textSource = categorySource,
    })
end

local function outcome(id, responseKey, options)
    options = options or {}
    return {
        id = id,
        weight = options.weight or 1,
        responseKey = responseKey,
        next = options.next,
        close = options.close == true,
        effects = options.effects or {},
        gates = options.gates,
    }
end

local function registerSimple(kind, audience, options)
    options = options or {}
    local blockID = PREFIX .. kind .. "_basic_" .. audience
    Registry.RegisterBlock(blockID, {
        schemaVersion = 1,
        ownerModID = MOD_ID,
        category = PREFIX .. kind,
        audiences = { audience },
        priority = options.priority or 0,
        weight = options.weight or 100,
        textSource = source(kind, audience, "basic"),
        entryNode = "opening",
        gates = options.gates,
        ["repeat"] = options["repeat"],
        nodes = {
            opening = {
                textKey = "opening",
                choices = options.choices,
            },
        },
    })
end

local continueChoice = function(id, effects)
    return {
        id = id,
        textKey = "choice." .. id,
        outcomes = {
            outcome("reply", "response." .. id, {
                close = true,
                effects = effects,
            }),
        },
    }
end

for _, audience in ipairs({ "neutral", "member", "special" }) do
    registerSimple("whats_up", audience, {
        choices = {
            continueChoice("situation", {
                { type = "pnc:relationship", familiarity = 1 },
            }),
            continueChoice("anything_else"),
        },
    })
    registerSimple("wellbeing", audience, {
        choices = {
            continueChoice("condition", {
                { type = "pnc:relationship", approval = 1, familiarity = 1 },
            }),
            continueChoice("offer_help", {
                { type = "pnc:relationship", approval = 2, respect = 1 },
            }),
        },
    })
    registerSimple("small_talk", audience, {
        choices = {
            continueChoice("weather"),
            continueChoice("quiet_day", {
                { type = "pnc:relationship", familiarity = 1 },
            }),
        },
    })
    registerSimple("ask_about", audience, {
        choices = {
            continueChoice("background"),
            continueChoice("skills"),
        },
    })
    registerSimple("needs", audience, {
        choices = {
            continueChoice("supplies"),
            continueChoice("medical"),
        },
    })
    registerSimple("trade", audience, {
        choices = {
            continueChoice("trade"),
        },
    })
end

registerSimple("work_orders", "member", {
    choices = {
        continueChoice("orders"),
        continueChoice("status"),
    },
})

registerSimple("personal", "special", {
    gates = {
        {
            type = "pnc:relationship",
            axis = "familiarity",
            operator = ">=",
            value = 10,
            reasonKey = "locked.familiarity",
        },
    },
    choices = {
        continueChoice("trust", {
            { type = "pnc:relationship", approval = 2, familiarity = 2 },
        }),
    },
})

registerSimple("relationship", "special", {
    gates = {
        {
            type = "pnc:relationship",
            axis = "approval",
            operator = ">=",
            value = 20,
            reasonKey = "locked.approval",
        },
    },
    choices = {
        continueChoice("us", {
            { type = "pnc:relationship", approval = 2, familiarity = 2 },
        }),
    },
})

Registry.RegisterBlock(PREFIX .. "hostile_parley", {
    schemaVersion = 1,
    ownerModID = MOD_ID,
    category = PREFIX .. "greetings",
    audiences = { "hostile" },
    priority = 100,
    weight = 100,
    textSource = source("greetings", "hostile", "parley"),
    entryNode = "opening",
    nodes = {
        opening = {
            textKey = "opening",
            choices = {
                {
                    id = "ceasefire",
                    textKey = "choice.ceasefire",
                    outcomes = {
                        outcome("requested", "response.ceasefire", {
                            close = true,
                            effects = { { type = "pnc:ceasefire" } },
                        }),
                    },
                },
            },
        },
    },
})

local timeWindows = {
    dawn = { 5, 6.5 },
    sunrise = { 6.5, 12 },
    sunset = { 12, 18 },
    dusk = { 18, 21 },
    twilight = { 21, 5 },
}
local relationships = {
    FirstMeet = "neutral",
    Acquaintance = "neutral",
    Member = "member",
    Lover = "special",
}

for relationshipID, audience in pairs(relationships) do
    for timeID, window in pairs(timeWindows) do
        local slug = string.lower(relationshipID) .. "_" .. timeID
        local keys = {}
        for index = 1, 5 do keys[index] = string.format("greeting.%03d", index) end
        Registry.RegisterBlock(PREFIX .. "greeting_" .. slug, {
            schemaVersion = 1,
            ownerModID = MOD_ID,
            category = PREFIX .. "greetings",
            audiences = { audience },
            priority = 10,
            weight = 100,
            textSource = source("greetings", audience, slug),
            entryNode = "opening",
            gates = {
                {
                    type = "pnc:relationship_state",
                    value = relationshipID,
                },
                {
                    type = "pnc:time",
                    startHour = window[1],
                    endHour = window[2],
                },
            },
            nodes = {
                opening = { textKeys = keys, choices = {} },
            },
        })
    end
end

return true
