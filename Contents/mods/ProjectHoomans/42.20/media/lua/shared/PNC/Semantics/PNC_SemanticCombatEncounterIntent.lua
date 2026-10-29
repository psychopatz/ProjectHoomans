-- Runtime-only team intent for the current zombie-horde encounter.
-- This is not a durable attack policy and never writes ModData.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Service = PNC.Semantics.CombatEncounterIntent or {}
PNC.Semantics.CombatEncounterIntent = Service

Service.VERSION = 1
Service.Teams = Service.Teams or {}
Service.Notifier = Service.Notifier or nil

local ALLOWED = {
    undecided = true,
    engage = true,
    avoid = true,
    hold = true,
}

local function ownerKey(record)
    if not record then return nil end
    local onlineID = tonumber(record.ownerOnlineID)
    if onlineID ~= nil then return "id:" .. tostring(onlineID) end
    local username = tostring(record.ownerUsername or "")
    if username ~= "" then return "user:" .. username end
    return nil
end

local function followOrderKind()
    return tostring(PNC.Const and PNC.Const.ORDER_FOLLOW or "follow")
end

local function isFollower(record)
    if not record or record.alive == false or not ownerKey(record) then
        return false
    end
    local orderKind = tostring(
        record.orderSpec and record.orderSpec.kind or ""
    )
    local activeJob = tostring(record.activeJob or "")
    local activeBehavior = tostring(record.activeBehavior or "")
    return orderKind == followOrderKind()
        or activeJob == "FollowOwner"
        or string.sub(activeBehavior, 1, 12) == "FollowOwner:"
end

local function memberCount(state)
    local count = 0
    for _ in pairs(state and state.members or {}) do count = count + 1 end
    return count
end

local function notify(record, state, reason)
    local callback = Service.Notifier
    if type(callback) ~= "function" then return false end
    local ok = pcall(callback, record, state, reason)
    return ok == true
end

function Service.SetNotifier(callback)
    Service.Notifier = type(callback) == "function" and callback or nil
    return Service.Notifier ~= nil
end

local function teamFor(record, create)
    local key = ownerKey(record)
    if not key then return nil, nil end
    local state = Service.Teams[key]
    if not state and create then
        state = {
            ownerKey = key,
            active = false,
            intent = "undecided",
            members = {},
            revision = 0,
        }
        Service.Teams[key] = state
    end
    return state, key
end

function Service.OwnerKey(record)
    return ownerKey(record)
end

function Service.IsFollower(record)
    return isFollower(record)
end

function Service.MatchesOwner(record, player)
    if not record or not player then return false end
    local onlineID = player.getOnlineID
        and tonumber(player:getOnlineID()) or nil
    if onlineID ~= nil and tonumber(record.ownerOnlineID) ~= nil then
        return onlineID == tonumber(record.ownerOnlineID)
    end
    local username = player.getUsername
        and tostring(player:getUsername() or "") or ""
    return username ~= ""
        and tostring(record.ownerUsername or "") == username
end

function Service.OnHordeTransition(record, phase, episodeID, now)
    if not isFollower(record) then return nil, "not_follower" end
    local state = teamFor(record, true)
    local npcID = tostring(record.id or "")
    phase = tostring(phase or "")
    now = tonumber(now) or 0
    if npcID == "" then return nil, "npc_id_missing" end

    if phase == "cleared" or phase == "clear" then
        state.members[npcID] = nil
        if memberCount(state) <= 0 then
            state.active = false
            state.intent = "undecided"
            state.spokespersonID = nil
            state.lastPromptEventRef = state.promptEventRef
            state.promptEventRef = nil
            state.resolvedBy = nil
            state.resolvedAt = nil
            state.clearedAt = now
            state.revision = (tonumber(state.revision) or 0) + 1
            notify(record, state, "team_cleared")
        end
        return state, state.active and "member_cleared" or "team_cleared"
    end

    if phase == "started" then
        state.members[npcID] = tostring(episodeID or "")
        if state.active ~= true then
            state.active = true
            state.intent = "undecided"
            state.startedAt = now
            state.spokespersonID = npcID
            state.promptNPCID = npcID
            state.promptEventRef = tostring(episodeID or "")
            state.resolvedBy = nil
            state.resolvedAt = nil
            state.revision = (tonumber(state.revision) or 0) + 1
            return state, "team_started"
        end
        return state, "member_joined"
    end

    if state.active == true then
        state.members[npcID] = state.members[npcID]
            or tostring(episodeID or "")
        state.lastTransition = phase
        state.lastTransitionAt = now
    end
    return state, state.active and "team_active" or "team_inactive"
end

function Service.GetForRecord(record)
    local state = teamFor(record, false)
    return state
end

function Service.IsPromptSpeaker(record, eventRef)
    local state = teamFor(record, false)
    return state ~= nil
        and state.active == true
        and state.intent == "undecided"
        and tostring(state.spokespersonID or "")
            == tostring(record and record.id or "")
        and tostring(state.promptEventRef or "")
            == tostring(eventRef or "")
end

function Service.Resolve(record, intent, expectedEventRef, source, now)
    intent = string.lower(tostring(intent or ""))
    if not ALLOWED[intent] or intent == "undecided" then
        return false, "invalid_encounter_intent"
    end
    local state = teamFor(record, false)
    if not state or state.active ~= true then
        return false, "encounter_inactive"
    end
    if expectedEventRef ~= nil and tostring(expectedEventRef) ~= ""
        and tostring(expectedEventRef)
            ~= tostring(state.promptEventRef or "")
    then
        return false, "encounter_prompt_stale"
    end
    state.intent = intent
    state.resolvedBy = tostring(source or "semantic")
    state.resolvedAt = tonumber(now) or 0
    state.revision = (tonumber(state.revision) or 0) + 1
    notify(record, state, "intent_resolved")
    return true, intent, state
end

function Service.ObserveOwnerEngaged(record, ownerEngaged, now)
    local state = teamFor(record, false)
    if not state or state.active ~= true then return nil, "encounter_inactive" end
    if state.intent == "undecided" and ownerEngaged == true then
        Service.Resolve(
            record,
            "engage",
            state.promptEventRef,
            "owner_combat",
            now
        )
        return "engage", "owner_combat"
    end
    return state.intent, "unchanged"
end

function Service.IntentFor(record)
    local state = teamFor(record, false)
    if not state or state.active ~= true then return nil end
    return state.intent
end

function Service.Snapshot(record)
    local state = teamFor(record, false)
    if not state then return nil end
    return {
        ownerKey = state.ownerKey,
        active = state.active == true,
        intent = tostring(state.intent or "undecided"),
        spokespersonID = state.spokespersonID,
        promptNPCID = state.promptNPCID,
        promptEventRef = state.promptEventRef,
        lastPromptEventRef = state.lastPromptEventRef,
        revision = tonumber(state.revision) or 0,
        memberCount = memberCount(state),
        resolvedBy = state.resolvedBy,
        resolvedAt = state.resolvedAt,
    }
end

function Service.ResetRuntime()
    Service.Teams = {}
end

return Service
