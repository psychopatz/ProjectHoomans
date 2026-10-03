-- Bounded, presentation-safe situation projection for semantic dialogue.
--
-- The conversation router should not know how a Project Hoomans record is
-- shaped, and the response layer should not inspect a complete NPC record.
-- This adapter translates already-authorized context into a small set of
-- stable, scalar signals: activity, need pressure, health, relationship, and
-- conversation continuity. It observes only; it never starts a task or
-- changes gameplay state.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Situation = PNC.Semantics.DialogueSituation or {}
PNC.Semantics.DialogueSituation = Situation

Situation.VERSION = 1
Situation.MAX_NEED_VALUES = 3
Situation.MAX_ACTIVITY_RULES = 64
Situation.MAX_ACTIVITY_PATTERNS = 16
Situation.MAX_CONDITION_VALUES = 3

-- Activity names are deliberately semantic rather than engine behavior names.
-- New behavior families can be added here without changing the parser or
-- response policy.
Situation.ACTIVITY_RULES = Situation.ACTIVITY_RULES or {
    {
        id = "dead",
        label = "dead",
        patterns = { "dead" },
        priority = 200,
        busy = false,
    },
    {
        id = "incapacitated",
        label = "recovering",
        patterns = { "incapacitated", "grounded", "downed" },
        priority = 190,
        busy = true,
    },
    {
        id = "combat",
        label = "keeping watch",
        patterns = { "combat", "attack", "threat", "fighting", "guard" },
        priority = 180,
        busy = true,
    },
    {
        id = "treatment",
        label = "tending to an injury",
        patterns = { "bandage", "treatment", "medical", "selfbandage" },
        priority = 170,
        busy = true,
    },
    {
        id = "fishing",
        label = "fishing",
        patterns = { "fishing" },
        priority = 160,
        busy = true,
    },
    {
        id = "traveling",
        label = "on the move",
        patterns = { "travel", "following", "followowner", "roam:player" },
        priority = 150,
        busy = true,
    },
    {
        id = "working",
        label = "working",
        patterns = { "work", "lumber", "production", "collectinputs" },
        priority = 140,
        busy = true,
    },
    {
        id = "resting",
        label = "taking a breather",
        patterns = { "athome", "atcamp", "rest", "seat", "sleep" },
        priority = 130,
        busy = false,
    },
    {
        id = "roaming",
        label = "looking around",
        patterns = { "roam", "scavenge" },
        priority = 120,
        busy = true,
    },
    {
        id = "idle",
        label = "taking it easy",
        patterns = { "idle", "waiting" },
        priority = 20,
        busy = false,
    },
}

local NEED_TYPES = { "hunger", "thirst", "fatigue" }
local NEED_WEIGHTS = { hunger = 1, thirst = 2, fatigue = 1 }
local CONDITION_TYPES = { "stress", "boredom", "panic" }
local CONDITION_WEIGHTS = { stress = 2, panic = 3, boredom = 1 }

local function text(value)
    value = tostring(value or "")
    return string.lower(value)
end

local function finite(value)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return nil
    end
    return value
end

local function bounded(value, minimum, maximum)
    value = finite(value)
    if value == nil then return nil end
    return math.max(minimum, math.min(maximum, value))
end

local function validID(value)
    value = tostring(value or "")
    return value ~= ""
        and #value <= 64
        and string.find(value, "[^%w_%.%-]") == nil
end

local function boundedText(value, maximum)
    value = tostring(value or "")
    maximum = tonumber(maximum) or 96
    if #value > maximum then return string.sub(value, 1, maximum) end
    return value
end

-- Activity rules are an extension point for domain modules. Normalize them
-- at registration time so a bad or oversized authored rule cannot turn every
-- conversation turn into an unbounded scan or leak arbitrary text into the
-- presentation context.
local function normalizeActivityRule(rule)
    local patterns = {}
    local seen = {}
    local index
    local pattern
    local id
    if type(rule) ~= "table" then return nil, "invalid_activity_rule" end
    id = tostring(rule.id or "")
    if not validID(id) or type(rule.patterns) ~= "table" then
        return nil, "invalid_activity_rule"
    end
    for index = 1, math.min(#rule.patterns, Situation.MAX_ACTIVITY_PATTERNS) do
        pattern = string.lower(boundedText(rule.patterns[index], 64))
        if pattern ~= "" and not seen[pattern] then
            seen[pattern] = true
            patterns[#patterns + 1] = pattern
        end
    end
    if #patterns == 0 then return nil, "activity_rule_requires_patterns" end
    return {
        id = id,
        label = boundedText(rule.label or id, 96),
        patterns = patterns,
        priority = bounded(rule.priority, -1000, 1000) or 0,
        busy = rule.busy == true,
    }
end

local function fromSource(context, key)
    local snapshot
    local record
    local sources = {
        context,
        context and context.npcState,
        context and context.npcSnapshot,
        context and context.npcRecord,
        context and context.conversationBlockContext,
        context and context.entry,
    }
    local index
    local source
    for index = 1, #sources do
        source = sources[index]
        if type(source) == "table" and source[key] ~= nil then
            return source[key]
        end
    end
    local entry = context and context.entry
    snapshot = entry and entry.snapshot
    record = entry and entry.record
    if type(snapshot) == "table" and snapshot[key] ~= nil then
        return snapshot[key]
    end
    if type(record) == "table" and record[key] ~= nil then
        return record[key]
    end
    return nil
end


Situation.Internal = Situation.Internal or {}
local Internal = Situation.Internal
Internal.Text = text
Internal.Finite = finite
Internal.Bounded = bounded
Internal.ValidID = validID
Internal.BoundedText = boundedText
Internal.NormalizeActivityRule = normalizeActivityRule
Internal.FromSource = fromSource
Internal.NeedTypes = NEED_TYPES
Internal.NeedWeights = NEED_WEIGHTS
Internal.ConditionTypes = CONDITION_TYPES
Internal.ConditionWeights = CONDITION_WEIGHTS

return Situation
