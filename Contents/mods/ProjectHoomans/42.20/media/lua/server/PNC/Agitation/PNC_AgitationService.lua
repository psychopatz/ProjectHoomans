-- Sparse lazy-decay NPC agitation service driven by compiled ReactionPolicy agitationRules.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.AgitationService = PNC.AgitationService or {}

local Service = PNC.AgitationService
local ReactionPolicyRegistry = PNC.ReactionPolicy and PNC.ReactionPolicy.Registry
if not ReactionPolicyRegistry and type(require) == "function" then
    ReactionPolicyRegistry = require "PNC/ReactionPolicy/Registry"
end

Service.StateByNPC = Service.StateByNPC or {}
Service.DEFAULT_DECAY_PER_SEC = 2.0
Service.STAGE_WARY = 25
Service.STAGE_TENSE = 55
Service.STAGE_HOSTILE = 85

local function nowMs(at)
    if at ~= nil then return tonumber(at) or 0 end
    return PNC.Core and type(PNC.Core.Now) == "function" and PNC.Core.Now() or 0
end

local function policyRegistry()
    if PNC.ReactionPolicy and PNC.ReactionPolicy.Registry then
        return PNC.ReactionPolicy.Registry
    end
    return ReactionPolicyRegistry
end

local function findRuleByTrigger(triggerId)
    local reg = policyRegistry()
    local rules = reg and reg.agitationRules or nil
    if type(rules) ~= "table" then return nil end
    local tKey = tostring(triggerId or "")
    for _, rule in pairs(rules) do
        if type(rule) == "table" and (rule.trigger == tKey or rule.id == tKey) then
            return rule
        end
    end
    return nil
end

function Service.StageForScore(score, thresholds)
    local s = tonumber(score) or 0
    local th = type(thresholds) == "table" and thresholds or {}
    local hostile = tonumber(th.hostile) or Service.STAGE_HOSTILE
    local tense = tonumber(th.tense) or Service.STAGE_TENSE
    local wary = tonumber(th.wary) or Service.STAGE_WARY
    if s >= hostile then return "hostile" end
    if s >= tense then return "tense" end
    if s >= wary then return "wary" end
    return "calm"
end

---Lazily decays `npcId` score to `at`; prunes entry from sparse storage once score reaches 0.
function Service.GetState(npcId, at)
    local key = tostring(npcId or "")
    local entry = Service.StateByNPC[key]
    local current = nowMs(at)
    if not entry then
        return { score = 0, stage = "calm", active = false, updatedAt = current }
    end
    local elapsedSec = math.max(0, (current - (tonumber(entry.updatedAt) or current)) / 1000)
    local decayPerSec = tonumber(entry.decayPerSec) or Service.DEFAULT_DECAY_PER_SEC
    local decayed = math.max(0, (tonumber(entry.score) or 0) - decayPerSec * elapsedSec)
    entry.score = decayed
    entry.updatedAt = current
    if decayed <= 0 then
        Service.StateByNPC[key] = nil
        return { score = 0, stage = "calm", active = false, updatedAt = current }
    end
    entry.stage = Service.StageForScore(decayed, entry.thresholds)
    return {
        score = decayed,
        stage = entry.stage,
        active = true,
        lastTrigger = entry.lastTrigger,
        lastSourceId = entry.lastSourceId,
        updatedAt = current,
    }
end

function Service.ApplyTrigger(recordOrId, triggerId, sourceId, at, opts)
    local record = type(recordOrId) == "table" and recordOrId
        or (PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(recordOrId))
    local npcId = tostring(type(recordOrId) == "table" and recordOrId.id or recordOrId or "")
    if npcId == "" then return false, "NPC_ID_REQUIRED" end

    local rule = findRuleByTrigger(triggerId)
    if not rule then return false, "UNKNOWN_AGITATION_TRIGGER" end

    local current = nowMs(at)
    local stateNow = Service.GetState(npcId, current)
    local entry = Service.StateByNPC[npcId]
    if not entry then
        entry = {
            score = stateNow.score,
            stage = stateNow.stage,
            updatedAt = current,
            decayPerSec = tonumber(rule.decayPerSec) or Service.DEFAULT_DECAY_PER_SEC,
            thresholds = rule.stageThresholds,
            cooldowns = {},
        }
        Service.StateByNPC[npcId] = entry
    end

    local ruleKey = tostring(rule.trigger or triggerId)
    local cooldownUntil = tonumber(entry.cooldowns[ruleKey]) or 0
    if current < cooldownUntil then
        return false, "AGITATION_COOLDOWN", {
            score = entry.score,
            stage = entry.stage,
            cooldownUntil = cooldownUntil,
        }
    end

    local previousStage = entry.stage
    local delta = tonumber(rule.delta) or 0
    local nextScore = math.max(0, math.min(100, (tonumber(entry.score) or 0) + delta))
    entry.score = nextScore
    entry.updatedAt = current
    entry.decayPerSec = tonumber(rule.decayPerSec) or entry.decayPerSec or Service.DEFAULT_DECAY_PER_SEC
    if type(rule.stageThresholds) == "table" then
        entry.thresholds = rule.stageThresholds
    end
    entry.cooldowns[ruleKey] = current + math.max(0, tonumber(rule.cooldownMs) or 1000)
    entry.lastTrigger = ruleKey
    entry.lastSourceId = sourceId
    entry.stage = Service.StageForScore(nextScore, entry.thresholds)

    if nextScore <= 0 then
        Service.StateByNPC[npcId] = nil
    end

    local secondary = PNC.SecondaryChannel
    if record and secondary then
        if type(secondary.SetAlertLevel) == "function" then
            secondary.SetAlertLevel(record, nextScore <= 0 and "calm" or entry.stage)
        end
        if (ruleKey == "defuse" or ruleKey == "antagonize" or ruleKey == "greet")
            and type(secondary.SetSecondaryState) == "function"
        then
            secondary.SetSecondaryState(record, ruleKey, nil, 3000, current)
        end
    end

    opts = type(opts) == "table" and opts or {}
    if opts.emitShock == true and previousStage ~= "hostile" and entry.stage == "hostile" then
        local bus = PsychopatzCore and PsychopatzCore.ShockingEventBus or nil
        if bus and type(bus.Emit) == "function" and record and record.x and record.y then
            bus.Emit({
                eventType = "shock.weapon_aimed",
                x = record.x,
                y = record.y,
                z = record.z or 0,
                radius = 12,
                severity = 85,
                sourceId = sourceId,
                targetId = npcId,
                dedupKey = "agitation:" .. npcId,
                at = current,
            })
        end
    end

    return true, entry.stage, {
        score = nextScore,
        stage = entry.stage,
        previousStage = previousStage,
        delta = delta,
        active = nextScore > 0,
    }
end

function Service.Clear(npcId)
    local key = tostring(npcId or "")
    if key ~= "" then
        Service.StateByNPC[key] = nil
    end
end

function Service.GetActiveCount()
    local count = 0
    for _ in pairs(Service.StateByNPC) do
        count = count + 1
    end
    return count
end

function Service.Reset()
    Service.StateByNPC = {}
end

return Service
