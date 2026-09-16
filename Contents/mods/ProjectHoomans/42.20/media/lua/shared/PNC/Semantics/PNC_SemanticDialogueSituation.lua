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

local function activityRule(raw)
    raw = text(raw)
    if raw == "" then return nil end
    local best
    local bestPriority = -math.huge
    local ruleIndex
    local patternIndex
    local rule
    local pattern
    for ruleIndex = 1, math.min(
        #Situation.ACTIVITY_RULES, Situation.MAX_ACTIVITY_RULES
    ) do
        rule = Situation.ACTIVITY_RULES[ruleIndex]
        if type(rule) == "table" then
            for patternIndex = 1, math.min(
                #(rule.patterns or {}), Situation.MAX_ACTIVITY_PATTERNS
            ) do
                pattern = text(rule.patterns[patternIndex])
                if pattern ~= ""
                    and string.find(raw, pattern, 1, true) ~= nil
                    and (tonumber(rule.priority) or 0) > bestPriority
                then
                    best = rule
                    bestPriority = tonumber(rule.priority) or 0
                end
            end
        end
    end
    return best
end

local function activityFromExistingStatus(context)
    local status = PNC.ActivityStatus
    local sources = {
        context and context.npcRecord,
        context and context.entry and context.entry.record,
        context and context.entry and context.entry.snapshot,
        context and context.conversationBlockContext
            and context.conversationBlockContext.npcRecord,
    }
    local index
    local source
    local ok
    local information
    local raw
    local rule
    if not status or type(status.Build) ~= "function" then return nil end
    for index = 1, #sources do
        source = sources[index]
        if type(source) == "table" then
            ok, information = pcall(status.Build, source)
            if ok and type(information) == "table" then
                raw = information.activityId or information.behaviorId
                    or information.fallback
                rule = activityRule(raw)
                if rule then
                    return {
                        id = tostring(rule.id),
                        label = boundedText(
                            information.fallback or rule.label or rule.id,
                            96
                        ),
                        busy = rule.busy == true,
                    }
                end
                if information.kind == "treatment" then
                    return {
                        id = "treatment",
                        label = "tending to an injury",
                        busy = true,
                    }
                end
            end
        end
    end
    return nil
end

local function activity(context)
    local existing = activityFromExistingStatus(context)
    if existing then return existing end
    local raw = fromSource(context, "activeBehavior")
        or fromSource(context, "activeJob")
        or fromSource(context, "aiState")
    local rule = activityRule(raw)
    if not rule then
        return {
            id = "unknown",
            label = "getting by",
            busy = false,
        }
    end
    return {
        id = tostring(rule.id),
        label = boundedText(rule.label or rule.id, 96),
        busy = rule.busy == true,
    }
end

local function fallbackNeedLevel(value)
    if value >= 0.90 then return "EMERGENCY", "emergency", 4 end
    if value >= 0.70 then return "SEVERE", "severe", 3 end
    if value >= 0.45 then return "MODERATE", "moderate", 2 end
    if value >= 0.25 then return "MINOR", "minor", 1 end
    return "NORMAL", "normal", 0
end

local function needLevel(needType, value)
    local definitions = PNC.NeedsDefinitions
    if definitions and type(definitions.GetLevel) == "function" then
        local ok, level = pcall(definitions.GetLevel, needType, value)
        if ok and level then
            local normalized = text(level)
            local weights = {
                normal = 0, minor = 1, moderate = 2,
                severe = 3, critical = 4, emergency = 4,
            }
            return tostring(level), normalized, weights[normalized] or 0
        end
    end
    return fallbackNeedLevel(value)
end

local function needs(context)
    local values = fromSource(context, "needs")
    local output = {
        highest = nil,
        urgency = "normal",
        level = "NORMAL",
    }
    if type(values) ~= "table" then return output end

    local highestWeight = 0
    local index
    local needType
    local value
    local level
    local urgency
    local weight
    for index = 1, math.min(#NEED_TYPES, Situation.MAX_NEED_VALUES) do
        needType = NEED_TYPES[index]
        value = bounded(values[needType], 0, 1)
        if value ~= nil then
            level, urgency, weight = needLevel(needType, value)
            weight = weight + (NEED_WEIGHTS[needType] or 0) * 0.01
            if weight > highestWeight then
                highestWeight = weight
                output.highest = needType
                output.urgency = urgency
                output.level = level
            end
        end
    end

    -- A network summary may be intentionally redacted down to its derived
    -- highest/urgency fields. Preserve that semantic information when raw
    -- values are unavailable.
    if output.highest == nil and values.highest ~= nil then
        output.highest = text(values.highest)
        output.urgency = text(values.urgency or values.highestLevel)
        output.urgency = output.urgency ~= "" and output.urgency or "normal"
        output.level = string.upper(output.urgency)
    end
    return output
end

local function attitude(context, relationship)
    local graph = PNC.RelationshipGraph
    if graph and type(graph.ResolveAttitude) == "function"
        and type(relationship) == "table"
    then
        local ok, value = pcall(
            graph.ResolveAttitude,
            relationship.approval,
            relationship.respect
        )
        if ok and value then return tostring(value) end
    end
    return nil
end

local function conditionLevel(conditionType, value)
    local stats = PNC.ConditionStats
    if stats and type(stats.GetLevel) == "function" then
        local ok, level = pcall(stats.GetLevel, conditionType, value)
        if ok and level then
            local normalized = text(level)
            local weights = {
                good = 0, stable = 0, low = 1,
                critical = 2, emergency = 3,
            }
            return tostring(level), normalized, weights[normalized] or 0
        end
    end
    if conditionType == "stress" then
        if value >= 0.90 then return "EMERGENCY", "emergency", 3 end
        if value >= 0.75 then return "CRITICAL", "critical", 2 end
        if value >= 0.50 then return "LOW", "low", 1 end
        return "STABLE", "stable", 0
    end
    if value >= 90 then return "EMERGENCY", "emergency", 3 end
    if value >= 70 then return "CRITICAL", "critical", 2 end
    if value >= 45 then return "LOW", "low", 1 end
    return "STABLE", "stable", 0
end

local function emotionalState(context)
    local values = fromSource(context, "conditionStats")
    local output = {
        highest = nil,
        urgency = "stable",
        level = "STABLE",
    }
    if type(values) ~= "table" then return output end

    local highestWeight = 0
    local index
    local conditionType
    local value
    local level
    local urgency
    local weight
    for index = 1, math.min(#CONDITION_TYPES, Situation.MAX_CONDITION_VALUES) do
        conditionType = CONDITION_TYPES[index]
        value = finite(values[conditionType])
        if value ~= nil then
            if conditionType == "stress" then
                value = math.max(0, math.min(1, value))
            else
                value = math.max(0, math.min(100, value))
            end
            level, urgency, weight = conditionLevel(conditionType, value)
            weight = weight + (CONDITION_WEIGHTS[conditionType] or 0) * 0.01
            if weight > highestWeight then
                highestWeight = weight
                output.highest = conditionType
                output.urgency = urgency
                output.level = level
            end
        end
    end
    return output
end

local function healthState(context)
    local value = text(fromSource(context, "healthState"))
    return value ~= "" and value or nil
end

local function socialStyle(context)
    local personality = fromSource(context, "npcPersonality")
    local traits = fromSource(context, "npcTraits")
    local value = type(personality) == "table"
        and personality.socialStyle or nil
    value = text(value)
    if value == "friendly" or value == "withdrawn" or value == "neutral" then
        return value
    end
    if type(traits) == "table" then
        local key
        local enabled
        for key, enabled in pairs(traits) do
            if enabled == true then
                local id = text(key)
                if string.find(id, "withdrawn", 1, true) then
                    return "withdrawn"
                end
                if string.find(id, "friendly", 1, true) then
                    return "friendly"
                end
            end
        end
    end
    return nil
end

function Situation.Build(context)
    context = type(context) == "table" and context or {}
    local relationship = type(context.relationship) == "table"
        and context.relationship or {}
    local state = type(context.semanticDialogueState) == "table"
        and context.semanticDialogueState or {}
    local activityValue = activity(context)
    local needValue = needs(context)
    local emotionalValue = emotionalState(context)
    return {
        schemaVersion = Situation.VERSION,
        npc = {
            activity = activityValue,
            needs = needValue,
            emotion = emotionalValue,
            healthState = healthState(context),
            inCombat = fromSource(context, "inCombat") == true,
        },
        social = {
            relationshipState = context.relationshipState,
            attitude = attitude(context, relationship),
            style = socialStyle(context),
            familiarity = bounded(relationship.familiarity, 0, 1),
        },
        conversation = {
            currentTopic = state.currentTopic or context.currentTopic,
            previousTopic = state.previousTopic or context.previousTopic,
            lastIntent = state.lastIntent or context.lastIntent,
            lastAction = state.lastAction or context.lastAction,
            hasPendingQuestion = state.pendingQuestion ~= nil
                or context.pendingQuestion ~= nil,
            hasPendingRequest = state.pendingRequest ~= nil
                or context.pendingRequest ~= nil,
        },
        world = {
            timeBand = context.worldContext
                and context.worldContext.timeBand or nil,
            raining = context.worldContext
                and context.worldContext.weather
                and context.worldContext.weather.raining or nil,
            foggy = context.worldContext
                and context.worldContext.weather
                and context.worldContext.weather.foggy or nil,
            indoors = context.worldContext
                and context.worldContext.environment
                and context.worldContext.environment.indoors or nil,
        },
    }
end

function Situation.RegisterActivityRule(rule)
    local normalized, reason = normalizeActivityRule(rule)
    if not normalized then return false, reason end
    local index
    for index = 1, #Situation.ACTIVITY_RULES do
        if Situation.ACTIVITY_RULES[index].id == normalized.id then
            Situation.ACTIVITY_RULES[index] = normalized
            return true, normalized
        end
    end
    if #Situation.ACTIVITY_RULES >= Situation.MAX_ACTIVITY_RULES then
        return false, "activity_rule_limit"
    end
    Situation.ACTIVITY_RULES[#Situation.ACTIVITY_RULES + 1] = normalized
    return true, normalized
end

return Situation
