-- Daily deterministic topic pool for "What's up?". Adding a topic only
-- requires another entry here plus one translation bundle per audience.
local H = PNC.Conversation.DefinitionHelpers
local Registry = PNC.Conversation.Registry

local TOPICS = {
    { id = "local_activity", weight = 5 },
    { id = "supply_pressure", weight = 3 },
    { id = "survivor_rumors", weight = 2 },
}

local function relationship(approval, respect, familiarity)
    return {{
        type = "pnc:relationship",
        approval = approval,
        respect = respect,
        familiarity = familiarity,
    }}
end

local function pair(id, nextNode, first, second)
    return {
        H.Outcome("open", "response." .. id .. ".open", {
            weight = 3,
            next = nextNode,
            effects = first or {},
        }),
        H.Outcome("guarded", "response." .. id .. ".guarded", {
            weight = 1,
            next = nextNode,
            effects = second or {},
        }),
    }
end

local function choice(id, nextNode, first, second, gate)
    return {
        id = id,
        textKey = "choice." .. id,
        lockedMode = gate and "disabled" or nil,
        lockedReasonKey = gate and gate.reasonKey or nil,
        gates = gate and { gate } or nil,
        outcomes = pair(id, nextNode, first, second),
    }
end

local function nodes()
    return {
        opening = {
            textKey = "node.opening",
            choices = {
                choice("detail", "details",
                    relationship(0, 0, 1), relationship(0, 0, 1)),
                choice("personal", "personal",
                    relationship(1, 0, 1), relationship(0, 0, 1), {
                        type = "pnc:relationship",
                        axis = "familiarity",
                        operator = ">=",
                        value = 8,
                        reasonKey = "locked.personal",
                    }),
            },
        },
        details = {
            textKey = "node.details",
            choices = {
                choice("offer_help", "followup",
                    relationship(2, 1, 1), relationship(1, 1, 0)),
                choice("press", "followup",
                    relationship(0, 2, 1), relationship(-1, 0, 1), {
                        type = "pnc:skill",
                        actor = "player",
                        skill = "Foraging",
                        operator = ">=",
                        value = 3,
                        reasonKey = "locked.skill",
                    }),
            },
        },
        personal = {
            textKey = "node.personal",
            choices = {
                choice("reassure", "followup",
                    relationship(2, 0, 1), relationship(1, 0, 1)),
                choice("challenge", "followup",
                    relationship(0, 2, 1), relationship(-1, 1, 0), {
                        type = "pnc:personality",
                        actor = "npc",
                        dimension = "bravery",
                        operator = ">=",
                        value = 0.55,
                        reasonKey = "locked.personality",
                    }),
            },
        },
        followup = {
            textKey = "node.followup",
            choices = {
                choice("advice", "closing",
                    relationship(0, 1, 1), relationship(0, 0, 1)),
                choice("wrap_up", "$root",
                    relationship(1, 0, 1), relationship(0, 0, 0)),
            },
        },
        closing = {
            textKey = "node.closing",
            choices = {
                choice("promise", "$root",
                    relationship(2, 1, 1), relationship(1, 0, 1), {
                        type = "pnc:relationship",
                        axis = "approval",
                        operator = ">=",
                        value = 10,
                        reasonKey = "locked.promise",
                    }),
                choice("leave", "$root",
                    relationship(1, 0, 0), relationship(0, 0, 0)),
            },
        },
    }
end

for _, audience in ipairs({ "neutral", "member", "special" }) do
    for _, topic in ipairs(TOPICS) do
        local id = H.PREFIX .. "whats_up_" .. topic.id .. "_" .. audience
        Registry.RegisterBlock(id, {
            schemaVersion = 1,
            ownerModID = H.MOD_ID,
            category = H.PREFIX .. "whats_up",
            audiences = { audience },
            priority = 0,
            weight = topic.weight,
            textSource = H.Source("whats_up", audience, topic.id),
            entryNode = "opening",
            nodes = nodes(),
        })
    end
end

return true
