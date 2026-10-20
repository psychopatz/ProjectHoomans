-- Versioned, data-only quest definitions. Runtime state belongs to the
-- server-side quest repository; this file never contains player or NPC data.

PNC = PNC or {}
PNC.Quests = PNC.Quests or {}

local Definitions = PNC.QuestDefinitions or {}
PNC.QuestDefinitions = Definitions

Definitions.SCHEMA_VERSION = 1
Definitions.OWNER = "ProjectHoomans"
Definitions.BY_ID = Definitions.BY_ID or {
    ["pnc.quest.clinic_supplies"] = {
        id = "pnc.quest.clinic_supplies",
        schemaVersion = 1,
        owner = "ProjectHoomans",
        version = 1,
        scope = "player_npc",
        repeatPolicy = "once_per_giver",
        eligibility = {
            giverRequired = true,
            medicalSupplyRequired = true,
        },
        objective = {
            id = "deliver_bandage",
            kind = "inventory_transfer",
            direction = "player_to_npc",
            itemFullType = "Base.Bandage",
            quantity = 1,
        },
        reward = {
            id = "pnc.quest.clinic_supplies.acknowledgement",
            kind = "dialogue_acknowledgement",
            responsePoolID = "semantic.quest.clinic_supplies.reward",
        },
        responses = {
            offer = "semantic.quest.clinic_supplies.offer",
            accepted = "semantic.quest.clinic_supplies.accepted",
            progress = "semantic.quest.clinic_supplies.progress",
            ready = "semantic.quest.clinic_supplies.ready",
            rewarded = "semantic.quest.clinic_supplies.rewarded",
            locked = "semantic.quest.clinic_supplies.locked",
        },
    },
}

local function copy(value, depth, seen)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 8 then return "<depth_limit>" end
    seen = seen or {}
    if seen[value] then return "<cycle>" end
    seen[value] = true
    local output = {}
    for key, entry in pairs(value) do
        if type(key) == "string" or type(key) == "number" then
            output[key] = copy(entry, depth + 1, seen)
        end
    end
    seen[value] = nil
    return output
end

function Definitions.Get(questID)
    local definition = Definitions.BY_ID[tostring(questID or "")]
    return definition and copy(definition) or nil
end

function Definitions.List()
    local output = {}
    for _, definition in pairs(Definitions.BY_ID) do
        output[#output + 1] = copy(definition)
    end
    table.sort(output, function(left, right)
        return tostring(left.id) < tostring(right.id)
    end)
    return output
end

return Definitions
