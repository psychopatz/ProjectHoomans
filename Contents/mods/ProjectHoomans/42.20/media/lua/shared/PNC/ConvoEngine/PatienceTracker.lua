-- Bounded per-pair conversation patience/annoyance tracker, redundant-command
-- detector, and shared NPC mood resolver. O(1) lookups, zero OnTick loops.

PNC = PNC or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Tracker = PNC.ConvoEngine.PatienceTracker or {}
PNC.ConvoEngine.PatienceTracker = Tracker

Tracker.VERSION = 1
Tracker.MAX_PAIRS = 128
Tracker.DECAY_PER_MS = 0.0006 -- ~36 points per minute
Tracker.REPEAT_WINDOW_MS = 45000

local entries = {}
local ringKeys = {}
local ringHead = 1

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function nowMs(explicit)
    local n = tonumber(explicit)
    if n ~= nil then return n end
    if PNC.Core and type(PNC.Core.Now) == "function" then
        local ok, val = pcall(PNC.Core.Now)
        if ok and tonumber(val) ~= nil then return tonumber(val) end
    end
    return 0
end

local function pairKey(npcID, partnerID)
    if npcID == nil then return nil end
    return tostring(npcID) .. "|" .. tostring(partnerID or "player")
end

local function touchRing(key)
    if entries[key] ~= nil then return end
    local evicted = ringKeys[ringHead]
    if evicted ~= nil and evicted ~= key then
        entries[evicted] = nil
    end
    ringKeys[ringHead] = key
    ringHead = ringHead + 1
    if ringHead > Tracker.MAX_PAIRS then ringHead = 1 end
end

function Tracker.ClassifyLevel(score)
    score = tonumber(score) or 0
    if score >= 75 then return "fed_up" end
    if score >= 45 then return "annoyed" end
    if score >= 20 then return "mild" end
    return "calm"
end

function Tracker.IsRedundantCommand(action, orderKind)
    local act = string.upper(tostring(action or ""))
    local ord = string.lower(tostring(orderKind or ""))
    if act == "" then return false end
    if act == "FOLLOW" then return ord == "follow" end
    if act == "STAY" or act == "HOLD" then
        return ord == "stay" or ord == "guard" or ord == "camp" or ord == "patrol"
    end
    if act == "CAMP" then return ord == "camp" end
    if act == "STOP" then return ord == "" or ord == "none" end
    return false
end

function Tracker.ComputePersonalityMultiplier(opts)
    opts = type(opts) == "table" and opts or {}
    local mult = 1.0
    local rel = string.lower(tostring(opts.relationshipTier or opts.relationshipState or ""))
    local style = string.lower(tostring(opts.socialStyle or opts.speakerStyle or ""))
    local comp = tonumber(opts.compassion) or 0.5
    if rel == "ally" or rel == "trusted" or rel == "friendly" or rel == "friend" or rel == "lover"
        or style == "friendly" or style == "supportive" or comp >= 0.65
    then
        mult = 0.65
    elseif rel == "hostile" or rel == "wary" or style == "aggressive"
        or style == "withdrawn" or style == "cold" or style == "hostile"
    then
        mult = 1.35
    end
    if opts.stressed == true or opts.panicked == true or opts.inPain == true or opts.exhausted == true then
        mult = mult + 0.20
    end
    return mult
end

local function buildSnapshot(score, repeatCount, recentKey)
    score = clamp(math.floor((tonumber(score) or 0) + 0.5), 0, 100)
    local level = Tracker.ClassifyLevel(score)
    return {
        score = score,
        level = level,
        annoyed = level == "annoyed" or level == "fed_up",
        fedUp = level == "fed_up",
        repeatCount = tonumber(repeatCount) or 0,
        recentKey = recentKey,
    }
end

local function decayedScore(entry, now)
    if type(entry) ~= "table" then return 0 end
    local score = tonumber(entry.score) or 0
    local dt = math.max(0, (tonumber(now) or 0) - (tonumber(entry.updatedAt) or 0))
    return math.max(0, score - dt * Tracker.DECAY_PER_MS)
end

function Tracker.Inspect(npcID, partnerID, now)
    local key = pairKey(npcID, partnerID)
    if not key then return buildSnapshot(0, 0, nil) end
    local entry = entries[key]
    if not entry then return buildSnapshot(0, 0, nil) end
    local ts = nowMs(now)
    local score = decayedScore(entry, ts)
    local rep = 0
    if entry.recentKey and (ts - (tonumber(entry.lastIntentAt) or 0)) <= Tracker.REPEAT_WINDOW_MS then
        rep = tonumber(entry.repeatCount) or 0
    end
    return buildSnapshot(score, rep, entry.recentKey)
end

function Tracker.RecordTurn(npcID, partnerID, opts)
    opts = type(opts) == "table" and opts or {}
    local key = pairKey(npcID, partnerID)
    if not key then return buildSnapshot(0, 0, nil) end
    local ts = nowMs(opts.now)
    local entry = entries[key]
    if not entry then
        touchRing(key)
        entry = { score = 0, updatedAt = ts, recentKey = nil, repeatCount = 0, lastIntentAt = 0 }
        entries[key] = entry
    end

    local score = decayedScore(entry, ts)
    local intentKey = opts.intentKey and tostring(opts.intentKey) or nil
    if intentKey and intentKey ~= "" then
        if entry.recentKey == intentKey
            and (ts - (tonumber(entry.lastIntentAt) or 0)) <= Tracker.REPEAT_WINDOW_MS
        then
            entry.repeatCount = (tonumber(entry.repeatCount) or 1) + 1
        else
            entry.recentKey = intentKey
            entry.repeatCount = 1
        end
        entry.lastIntentAt = ts
    end

    local mult = Tracker.ComputePersonalityMultiplier(opts)
    if opts.redundantCommand == true then
        score = score + (22 * mult)
    end
    if (tonumber(entry.repeatCount) or 0) >= 2 then
        local excess = math.min(3, entry.repeatCount - 1)
        score = score + (16 * excess * mult)
    end
    if opts.playerRude == true then
        score = score + (24 * mult)
    end
    if opts.playerShouting == true then
        score = score + (14 * mult)
    end
    if opts.apology == true then
        score = score - 28
    elseif opts.playerPolite == true then
        score = score - 14
    end

    entry.score = clamp(score, 0, 100)
    entry.updatedAt = ts
    return buildSnapshot(entry.score, entry.repeatCount, entry.recentKey)
end

local function readMoodNum(tbl, key)
    if type(tbl) ~= "table" then return 0 end
    local v = tbl[key]
    if v == true then return 1 end
    return tonumber(v) or 0
end

function Tracker.ResolveMood(speaker, patience)
    speaker = type(speaker) == "table" and speaker or {}
    patience = type(patience) == "table" and patience or buildSnapshot(0, 0, nil)
    local c = type(speaker.conditionStats) == "table" and speaker.conditionStats or {}
    local n = type(speaker.needs) == "table" and speaker.needs or {}
    local m = type(speaker.moods) == "table" and speaker.moods
        or (type(speaker.runtime) == "table" and type(speaker.runtime.moods) == "table" and speaker.runtime.moods)
        or (type(speaker.social) == "table" and type(speaker.social.moods) == "table" and speaker.social.moods)
        or {}
    local h = type(speaker.health) == "table" and speaker.health or {}
    local st = type(speaker.stamina) == "table" and speaker.stamina or {}

    local panic = tonumber(c.panic) or tonumber(speaker.panic) or 0
    local stress = tonumber(c.stress) or tonumber(speaker.stress) or readMoodNum(m, "stressed")
    local pain = tonumber(c.pain) or tonumber(speaker.pain) or 0
    local fatigue = tonumber(c.fatigue) or tonumber(n.fatigue) or tonumber(speaker.fatigue) or readMoodNum(m, "tired")
    local unhappiness = tonumber(c.unhappiness) or tonumber(n.unhappiness) or readMoodNum(m, "unhappy")
    local boredom = tonumber(c.boredom) or tonumber(n.boredom) or readMoodNum(m, "bored")
    local hunger = tonumber(c.hunger) or tonumber(n.hunger) or readMoodNum(m, "hungry")
    local thirst = tonumber(c.thirst) or tonumber(n.thirst) or 0
    local bleeding = h.bleeding == true or speaker.bleeding == true

    local isPanicked = panic >= 55 or readMoodNum(m, "panicked") >= 0.5
    local isInPain = bleeding or pain >= 45
    local isStressed = stress >= 0.65
    local isTired = fatigue >= 0.72 or string.lower(tostring(st.state or "")) == "exhausted"
    local isUnhappy = unhappiness >= 0.50
    local isBored = boredom >= 0.50
    local isHungry = hunger >= 0.65 or thirst >= 0.65
    local isAnnoyed = patience.annoyed == true
    local isFedUp = patience.fedUp == true

    local style = string.lower(tostring(speaker.socialStyle or speaker.style or ""))
    local happySignal = readMoodNum(m, "happy") >= 0.5 or readMoodNum(m, "cheerful") >= 0.5
        or style == "friendly" or style == "supportive"
    local isCheerful = (not isPanicked) and (not isInPain) and (not isStressed)
        and (not isTired) and (not isUnhappy) and (not isAnnoyed) and (not isHungry)
        and unhappiness <= 0.15 and stress <= 0.20 and happySignal

    local primary = "calm"
    if isPanicked then primary = "panicked"
    elseif isInPain then primary = "in_pain"
    elseif isFedUp then primary = "fed_up"
    elseif isStressed then primary = "stressed"
    elseif isTired then primary = "tired"
    elseif isAnnoyed then primary = "annoyed"
    elseif isUnhappy then primary = "unhappy"
    elseif isHungry then primary = "hungry"
    elseif isBored then primary = "bored"
    elseif isCheerful then primary = "cheerful" end

    return {
        primary = primary,
        panicked = isPanicked,
        inPain = isInPain,
        stressed = isStressed,
        tired = isTired,
        unhappy = isUnhappy,
        bored = isBored,
        hungry = isHungry,
        cheerful = isCheerful,
        annoyed = isAnnoyed,
        fedUp = isFedUp,
        annoyanceLevel = patience.level or "calm",
        annoyanceScore = tonumber(patience.score) or 0,
        repeatCount = tonumber(patience.repeatCount) or 0,
    }
end

function Tracker.EnrichContext(ir, context)
    if type(context) ~= "table" then return nil end
    local npcState = type(context.npcState) == "table" and context.npcState or {}
    local orderKind = string.lower(tostring(npcState.orderKind or context.stateOrderKind or "none"))
    if orderKind == "" then orderKind = "none" end
    local action = ir and ir.action or nil
    local redundant = action ~= nil and Tracker.IsRedundantCommand(action, orderKind) == true
    local ext = type(ir) == "table" and type(ir.extensions) == "table" and ir.extensions or {}
    local intentKey = tostring(action or (ir and ir.subject) or (ir and ir.intent) or "")
    local pat = Tracker.RecordTurn(context.npcID, context.characterUUID or "player", {
        intentKey = intentKey,
        redundantCommand = redundant,
        playerRude = ext.playerRude == true or context.playerRude == true,
        playerShouting = ext.playerShouting == true or context.playerShouting == true,
        playerPolite = ext.playerPolite == true or context.playerPolite == true,
        apology = (ir and ir.intent == "APOLOGY") or ext.dialogueAct == "APOLOGY",
        relationshipTier = context.relationshipTier or context.relationshipState,
        socialStyle = context.socialStyle,
    })
    local md = Tracker.ResolveMood(npcState, pat)
    context.stateOrderKind = orderKind
    context.stateAlreadyFollowing = orderKind == "follow"
    context.commandRedundant = redundant
    context.npcAnnoyance = pat.level
    context.npcAnnoyed = pat.annoyed == true
    context.npcFedUp = pat.fedUp == true
    context.convoRepeatCount = pat.repeatCount
    context.moodPrimary = md.primary
    context.moodPanicked = md.panicked == true
    context.moodInPain = md.inPain == true
    context.moodStressed = md.stressed == true
    context.moodTired = md.tired == true
    context.moodUnhappy = md.unhappy == true
    context.moodBored = md.bored == true
    context.moodHungry = md.hungry == true
    context.moodCheerful = md.cheerful == true
    return pat, md
end

function Tracker.Reset()
    entries = {}
    ringKeys = {}
    ringHead = 1
end

return Tracker
