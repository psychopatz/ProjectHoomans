-- Bounded actor-agnostic shared conversational floor for multi-party ("V" group
-- talk & NPC-to-NPC scenes) turn bidding, mechanic execution scoping, and 1-hop
-- cross-NPC interjections. O(1) floor lookup, zero OnTick loops.

PNC = PNC or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Floor = PNC.ConvoEngine.GroupFloor or {}
PNC.ConvoEngine.GroupFloor = Floor

Floor.VERSION = 1
Floor.MAX_FLOORS = 32
Floor.MAX_HISTORY = 8
Floor.MAX_RECENT_SPEAKERS = 6

local Patience = require "PNC/ConvoEngine/PatienceTracker"

local floors = {}
local ringKeys = {}
local ringHead = 1

local function touchFloor(groupID)
    local key = tostring(groupID or "default")
    local existing = floors[key]
    if existing then return existing end
    local evicted = ringKeys[ringHead]
    if evicted ~= nil and evicted ~= key then
        floors[evicted] = nil
    end
    ringKeys[ringHead] = key
    ringHead = ringHead + 1
    if ringHead > Floor.MAX_FLOORS then ringHead = 1 end
    local fresh = {
        groupID = key,
        turnCount = 0,
        lastSpeakerID = nil,
        lastSpeakerName = nil,
        lastSpeakerIsNPC = false,
        lastAddresseeID = nil,
        lastIntent = nil,
        lastAction = nil,
        lastSubject = nil,
        lastTopic = nil,
        lastOutcome = nil,
        lastMood = "calm",
        lastSpeakerAnnoyed = false,
        lastSpeakerFedUp = false,
        lastSpeakerInjured = false,
        lastWasInterjection = false,
        recentSpeakers = {},
        history = {},
    }
    floors[key] = fresh
    return fresh
end

local function pushRecentSpeaker(list, speakerID)
    if speakerID == nil then return end
    local sid = tostring(speakerID)
    for i = #list, 1, -1 do
        if list[i] == sid then table.remove(list, i) end
    end
    list[#list + 1] = sid
    while #list > Floor.MAX_RECENT_SPEAKERS do
        table.remove(list, 1)
    end
end

function Floor.Get(groupID)
    local key = tostring(groupID or "default")
    return floors[key]
end

function Floor.RecordTurn(groupID, turn)
    turn = type(turn) == "table" and turn or {}
    local f = touchFloor(groupID)
    f.turnCount = f.turnCount + 1
    f.lastSpeakerID = turn.speakerID
    f.lastSpeakerName = turn.speakerName or (turn.speakerID and tostring(turn.speakerID) or nil)
    f.lastSpeakerIsNPC = turn.speakerIsPlayer ~= true and turn.speakerID ~= nil
    f.lastAddresseeID = turn.addresseeID
    f.lastIntent = turn.intent
    f.lastAction = turn.action
    f.lastSubject = turn.subject
    f.lastTopic = turn.topic
    f.lastOutcome = turn.outcome
    f.lastMood = turn.moodPrimary or "calm"
    f.lastSpeakerAnnoyed = turn.npcAnnoyed == true
    f.lastSpeakerFedUp = turn.npcFedUp == true
    f.lastSpeakerInjured = turn.speakerInjured == true
    f.lastWasInterjection = turn.isInterjection == true
    pushRecentSpeaker(f.recentSpeakers, turn.speakerID)
    f.history[#f.history + 1] = {
        speakerID = turn.speakerID,
        speakerName = f.lastSpeakerName,
        intent = turn.intent,
        action = turn.action,
        subject = turn.subject,
        outcome = turn.outcome,
        isInterjection = f.lastWasInterjection,
    }
    while #f.history > Floor.MAX_HISTORY do
        table.remove(f.history, 1)
    end
    return f
end

local function scoreCandidate(p, turn, addressing, floor)
    if type(p) ~= "table" or p.id == nil or p.alive == false then return -1 end
    if p.isPlayer == true then return -1 end
    local score = 10
    local pid = tostring(p.id)
    local action = string.upper(tostring(turn.action or ""))
    local subject = string.upper(tostring(turn.subject or ""))
    local orderKind = string.lower(tostring(p.orderKind or "none"))

    if addressing and addressing.vocative and tostring(addressing.targetID or "") == pid then
        score = score + 60
    elseif addressing and addressing.implicitTargetID and tostring(addressing.implicitTargetID) == pid then
        score = score + 20
    elseif floor and floor.lastSpeakerID and tostring(floor.lastSpeakerID) == pid then
        score = score + 12
    end

    if action ~= "" then
        local redundant = Patience.IsRedundantCommand(action, orderKind)
        if not redundant then
            score = score + 25
        else
            score = score + 4
        end
    end

    if subject == "HEALTH" or subject == "WELLBEING" or subject == "MEDICAL" then
        if p.isInjured == true or p.moodInPain == true or p.moodTired == true then
            score = score + 25
        end
    end

    if p.socialStyle == "friendly" or p.moodCheerful == true then
        score = score + 4
    elseif p.socialStyle == "withdrawn" then
        score = score - 4
    end
    return score
end

local function resolveSideWithSpeaker(interjector, speakerID, relLookup)
    if type(relLookup) == "function" then
        local ok, tier = pcall(relLookup, interjector.id, speakerID)
        if ok and tier ~= nil then
            local t = string.lower(tostring(tier))
            if t == "hostile" or t == "wary" or t == "enemy" or t == "rival" then
                return false
            end
            if t == "ally" or t == "trusted" or t == "friendly" or t == "friend" or t == "lover" then
                return true
            end
        end
    end
    return interjector.socialStyle ~= "withdrawn" and interjector.socialStyle ~= "hostile"
end

function Floor.PickInterjection(groupID, participants, primaryTurn, opts)
    opts = type(opts) == "table" and opts or {}
    primaryTurn = type(primaryTurn) == "table" and primaryTurn or {}
    -- Strict 1-hop cap: never chain an interjection onto another interjection.
    if primaryTurn.isInterjection == true then return nil end
    if type(participants) ~= "table" or #participants < 2 then return nil end

    local speakerID = tostring(primaryTurn.speakerID or "")
    local bestActor = nil
    local bestKind = nil
    local bestScore = 0
    local bestSide = true

    for i = 1, #participants do
        local p = participants[i]
        if type(p) == "table" and p.id ~= nil and p.alive ~= false
            and p.isPlayer ~= true and tostring(p.id) ~= speakerID
        then
            local side = resolveSideWithSpeaker(p, speakerID, opts.relLookup)
            local kind = nil
            local s = 0
            if primaryTurn.npcFedUp == true or primaryTurn.npcAnnoyed == true then
                if p.socialStyle == "friendly" or p.socialStyle == "supportive" then
                    kind = "calm_down"
                    s = 30
                elseif side then
                    kind = "back_up"
                    s = 26
                else
                    kind = "disagree"
                    s = 22
                end
            elseif primaryTurn.speakerInjured == true or primaryTurn.moodPrimary == "in_pain"
                or primaryTurn.moodPrimary == "panicked"
            then
                if side or p.socialStyle == "friendly" or p.socialStyle == "supportive" then
                    kind = "concern"
                    s = 28
                end
            elseif primaryTurn.groupBroadcast == true then
                kind = "chime_in"
                s = 18
            elseif not side and (primaryTurn.outcome == "rejected" or primaryTurn.outcome == "redundant") then
                kind = "disagree"
                s = 16
            end

            if kind and s > bestScore then
                bestScore = s
                bestActor = p
                bestKind = kind
                bestSide = side
            end
        end
    end

    if not bestActor then return nil end
    return {
        actor = bestActor,
        actorID = bestActor.id,
        kind = bestKind,
        sideWithSpeaker = bestSide,
        context = {
            groupSize = #participants,
            groupBroadcast = primaryTurn.groupBroadcast == true,
            floorSpeakerIsNPC = primaryTurn.speakerIsPlayer ~= true,
            floorInterjectionKind = bestKind,
            floorSideWithSpeaker = bestSide,
            floorSpeakerAnnoyed = primaryTurn.npcAnnoyed == true or primaryTurn.npcFedUp == true,
            floorSpeakerInjured = primaryTurn.speakerInjured == true,
        },
        tokens = {
            ["floor.speaker_name"] = primaryTurn.speakerName or tostring(primaryTurn.speakerID or ""),
        },
    }
end

function Floor.SelectResponders(groupID, participants, turn, opts)
    opts = type(opts) == "table" and opts or {}
    turn = type(turn) == "table" and turn or {}
    participants = type(participants) == "table" and participants or {}
    local floor = Floor.Get(groupID)
    local addressing = opts.addressing or turn.addressing or nil
    local scope = (addressing and addressing.broadcast) and "group"
        or ((addressing and addressing.vocative) and "single" or "default")

    local best = nil
    local bestScore = -1
    local executors = {}
    local action = string.upper(tostring(turn.action or ""))

    for i = 1, #participants do
        local p = participants[i]
        if type(p) == "table" and p.id ~= nil and p.alive ~= false and p.isPlayer ~= true then
            local s = scoreCandidate(p, turn, addressing, floor)
            if s > bestScore then
                bestScore = s
                best = p
            end
            if scope == "group" then
                if action == "" or not Patience.IsRedundantCommand(action, p.orderKind) then
                    executors[#executors + 1] = p.id
                end
            elseif scope == "single" and addressing and tostring(addressing.targetID or "") == tostring(p.id) then
                executors[#executors + 1] = p.id
            end
        end
    end

    if #executors == 0 and best then
        executors[1] = best.id
    end

    local interjection = nil
    if best and #participants >= 2 and opts.allowInterjection ~= false then
        interjection = Floor.PickInterjection(groupID, participants, {
            speakerID = best.id,
            speakerName = best.name or best.fullName,
            speakerIsPlayer = false,
            groupBroadcast = scope == "group",
            npcAnnoyed = best.npcAnnoyed == true,
            npcFedUp = best.npcFedUp == true,
            speakerInjured = best.isInjured == true,
            moodPrimary = best.moodPrimary,
            outcome = turn.outcome,
            isInterjection = false,
        }, opts)
    end

    return {
        scope = scope,
        primary = best,
        primaryID = best and best.id or nil,
        executors = executors,
        interjection = interjection,
    }
end

function Floor.Reset()
    floors = {}
    ringKeys = {}
    ringHead = 1
end

return Floor
