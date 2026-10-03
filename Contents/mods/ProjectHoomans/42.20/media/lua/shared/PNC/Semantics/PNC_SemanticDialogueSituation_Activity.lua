-- Semantic situation activity and need projection provider.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Situation = PNC.Semantics.DialogueSituation
local Internal = Situation.Internal or {}
Situation.Internal = Internal
local text = Internal.Text
local boundedText = Internal.BoundedText
local fromSource = Internal.FromSource
local bounded = Internal.Bounded
local finite = Internal.Finite
local NEED_TYPES = Internal.NeedTypes
local NEED_WEIGHTS = Internal.NeedWeights

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


Internal.ActivityRule = activityRule
Internal.Activity = activity
Internal.FallbackNeedLevel = fallbackNeedLevel
Internal.NeedLevel = needLevel

return Situation
