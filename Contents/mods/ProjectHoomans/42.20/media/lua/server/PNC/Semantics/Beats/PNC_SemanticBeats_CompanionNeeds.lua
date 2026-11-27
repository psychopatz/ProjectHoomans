-- Companion moodle awareness, follow-through acknowledgment, and actor-agnostic
-- follower-to-leader need requests with Yes/No branching (works for both player
-- leaders and NPC group leaders).
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Beats = PNC.Semantics.DialogueBeats or {}
PNC.Semantics.DialogueBeats = Beats

local CHECK_COOLDOWN_MS = 10000
local SUGGEST_COOLDOWN_MS = 180000
local NEED_REQUEST_COOLDOWN_MS = 180000
local NEED_CRITICAL_COOLDOWN_MS = 90000
local SELF_NEED_COOLDOWN_MS = 150000
local SELF_NEED_CRITICAL_COOLDOWN_MS = 75000
local SUGGEST_WATCH_TTL_MS = 90000
local NEED_REQUEST_TTL_MS = 60000
local KNOX_BRANCH_TTL_MS = 75000
local KNOX_FX_COOLDOWN_MS = { light = 30000, medium = 18000, critical = 12000 }
local BREAK_SIT_DURATION_MS = 25000
local MAX_TRACKED_KEYS = 32

local INTENSITY_RANK = {
    light = 1,
    medium = 2,
    critical = 3,
}

local lastCheckAt = 0
local suggestCooldowns, suggestOrder = {}, {}
local requestCooldowns, requestOrder = {}, {}
local selfNeedCooldowns, selfNeedOrder = {}, {}
local knoxFxCooldowns, knoxFxOrder = {}, {}
local pendingSuggestions = {} -- leaderKey -> { advisorId, need, initialSeverity, suggestedAt, expiresAt }
local pendingNeedRequests = {} -- leaderKey -> { requestId, requesterId, leaderKind, leaderKey, leaderId, need, severity, intensity, createdAt, expiresAt }
local pendingKnoxBranches = {} -- listenerKey -> { branchId, infectedId, stage, listenerKind, listenerKey, listenerName, createdAt, expiresAt }
local requestSeq = 0

local NEED_REQUEST_FRONTIER = {
    { id = "need_req_yes", speechAct = "ACCEPT", decision = "yes", stance = "stance_positive", priority = 14 },
    { id = "need_req_no",  speechAct = "REFUSE", decision = "no",  stance = "stance_negative", priority = 10 },
}

local KNOX_BRANCH_FRONTIER = {
    { id = "knox_comfort",  speechAct = "ACCEPT",  decision = "comfort",  stance = "stance_positive", priority = 15 },
    { id = "knox_distance", speechAct = "CLARIFY", decision = "distance", stance = "stance_neutral",  priority = 13 },
    { id = "knox_confront", speechAct = "REFUSE",  decision = "confront", stance = "stance_negative", priority = 11 },
}

local function nowMs(at)
    if at ~= nil then return tonumber(at) or 0 end
    return PNC.Core and type(PNC.Core.Now) == "function" and tonumber(PNC.Core.Now()) or 0
end

local function lruPut(map, order, key, val)
    if map[key] == nil then
        while #order >= MAX_TRACKED_KEYS do
            local oldest = table.remove(order, 1)
            map[oldest] = nil
        end
        order[#order + 1] = key
    end
    map[key] = val
end

local function safeCall(obj, methodName, ...)
    local fn = obj and obj[methodName]
    if type(fn) ~= "function" then return nil end
    local ok, val = pcall(fn, obj, ...)
    if ok then return val end
    return nil
end

local function playerEntityKey(player)
    if not player then return nil end
    if PNC.PlayerCharacters and type(PNC.PlayerCharacters.GetEntityKey) == "function" then
        local k = PNC.PlayerCharacters.GetEntityKey(player)
        if k and tostring(k) ~= "" then return tostring(k) end
    end
    local oid = safeCall(player, "getOnlineID")
    if oid ~= nil and tonumber(oid) and tonumber(oid) >= 0 then
        return "player:" .. tostring(oid)
    end
    local uname = safeCall(player, "getUsername")
    return (uname and tostring(uname) ~= "") and ("player:" .. tostring(uname)) or "player:local"
end

local function playerDisplayName(player)
    if not player then return "boss" end
    local desc = safeCall(player, "getDescriptor")
    local fore = desc and safeCall(desc, "getForename")
    if fore and tostring(fore) ~= "" then return tostring(fore) end
    local disp = safeCall(player, "getDisplayName")
    if disp and tostring(disp) ~= "" then return tostring(disp) end
    local uname = safeCall(player, "getUsername")
    if uname and tostring(uname) ~= "" then return tostring(uname) end
    return "boss"
end

local function isCalmNPC(rec, now)
    if type(rec) ~= "table" or rec.id == nil or rec.alive == false then return false end
    local live = tostring(PNC.Const and PNC.Const.PRESENCE_LIVE or "live")
    if rec.presenceState ~= nil and tostring(rec.presenceState) ~= live then return false end
    local hState = rec.health and string.lower(tostring(rec.health.state or "normal")) or "normal"
    if hState == "downed" or hState == "unconscious" or hState == "dead" or hState == "incapacitated" then
        return false
    end
    local rt = type(rec.runtime) == "table" and rec.runtime or nil
    if rt and (rt.target ~= nil or rt.attackAction ~= nil or rt.combatTarget ~= nil
        or now < (tonumber(rt.inCombatUntil) or 0))
    then
        return false
    end
    return true
end

local function distanceSq(ax, ay, bx, by)
    local dx = (tonumber(ax) or 0) - (tonumber(bx) or 0)
    local dy = (tonumber(ay) or 0) - (tonumber(by) or 0)
    return dx * dx + dy * dy
end

-- Actor-agnostic leader resolution: supports both player owners and NPC group leaders.
function Beats.ResolveLeaderForCompanion(record)
    if type(record) ~= "table" or record.id == nil then return nil end
    local common = PNC.BehaviorCommon
    local orderKind = tostring(record.orderSpec and record.orderSpec.kind or "")
    local isFollowingOwner = (orderKind == tostring(PNC.Const and PNC.Const.ORDER_FOLLOW or "follow"))
        or (record.runtime and record.runtime.followOrderActive == true)
    if isFollowingOwner and common and type(common.GetOwner) == "function" then
        local owner = common.GetOwner(record)
        if owner and safeCall(owner, "isDead") ~= true then
            return {
                kind = "player",
                actor = owner,
                key = playerEntityKey(owner),
                id = playerEntityKey(owner),
                name = playerDisplayName(owner),
                x = safeCall(owner, "getX") or 0,
                y = safeCall(owner, "getY") or 0,
                z = safeCall(owner, "getZ") or 0,
            }
        end
    end
    local leaderId = record.leaderId or record.groupLeaderId
    if not leaderId and record.groupId and PNC.AbstractGroupManager
        and type(PNC.AbstractGroupManager.GetGroup) == "function"
    then
        local grp = PNC.AbstractGroupManager.GetGroup(record.groupId)
        leaderId = grp and grp.leaderId or nil
    end
    if leaderId and tostring(leaderId) ~= tostring(record.id) then
        local reg = PNC.Registry
        local leader = reg and type(reg.Get) == "function" and reg.Get(leaderId) or nil
        if type(leader) == "table" and leader.alive ~= false then
            return {
                kind = "npc",
                actor = leader,
                key = "npc:" .. tostring(leader.id),
                id = tostring(leader.id),
                name = tostring(leader.name or leader.fullName or "boss"),
                x = tonumber(leader.x) or 0,
                y = tonumber(leader.y) or 0,
                z = tonumber(leader.z) or 0,
            }
        end
    end
    return nil
end

local function readPlayerMoodleLevel(player, fieldName)
    local moodles = safeCall(player, "getMoodles")
    if not moodles then return 0 end
    local mType = type(MoodleType) == "table" and MoodleType[fieldName] or nil
    if mType ~= nil then
        local lvl = safeCall(moodles, "getMoodleLevel", mType)
        if tonumber(lvl) then return tonumber(lvl) end
    end
    -- Fallback for mock/test harnesses using string keys
    local lvl = safeCall(moodles, "getMoodleLevel", fieldName)
    return tonumber(lvl) or 0
end

local function readNPCNeed(record, key)
    if type(record) ~= "table" then return 0 end
    if PNC.IndividualNeeds and type(PNC.IndividualNeeds.Get) == "function" then
        local v = tonumber(PNC.IndividualNeeds.Get(record, key))
        if v ~= nil then return v end
    end
    local needs = type(record.needs) == "table" and record.needs or nil
    if needs and tonumber(needs[key]) ~= nil then
        return tonumber(needs[key])
    end
    local cond = type(record.conditionStats) == "table" and record.conditionStats or nil
    return cond and tonumber(cond[key]) or 0
end

local function readNPCAilmentSeverity(record, ailmentId)
    if type(record) ~= "table" then return 0 end
    local wb = PNC.NPCWounds and PNC.NPCWounds.WholeBody or nil
    if wb and type(wb.GetSeverity) == "function" then
        local ok, v = pcall(wb.GetSeverity, record, ailmentId)
        if ok and tonumber(v) ~= nil then return tonumber(v) end
    end
    local ailments = record.health and record.health.body and record.health.body.wholeBodyAilments
        or (record.bodyHealth and record.bodyHealth.wholeBodyAilments)
        or nil
    if type(ailments) ~= "table" then return 0 end
    local entry = ailments[ailmentId]
    if type(entry) == "table" then
        return tonumber(entry.severity) or (entry.active == true and 1 or 0)
    end
    return tonumber(entry) or 0
end

local function intensityFromPlayerMoodle(level)
    level = tonumber(level) or 0
    if level >= 4 then return "critical" end
    if level >= 3 then return "medium" end
    if level >= 2 then return "light" end
    return nil
end

local function cooldownAllows(map, key, intensity, now)
    local entry = map[key]
    if entry == nil then return true end
    if type(entry) == "number" then
        return now >= entry
    end
    local untilAt = tonumber(entry.untilAt) or 0
    if now >= untilAt then return true end
    local prevRank = INTENSITY_RANK[tostring(entry.intensity or "light")] or 1
    local curRank = INTENSITY_RANK[tostring(intensity or "light")] or 1
    return curRank > prevRank
end

local function setIntensityCooldown(map, order, key, untilAt, intensity)
    lruPut(map, order, key, {
        untilAt = untilAt,
        intensity = tostring(intensity or "light"),
    })
end

function Beats.ClassifyNeedIntensity(needKind, value, ailmentSeverity)
    local v = tonumber(value) or 0
    local a = tonumber(ailmentSeverity) or 0
    if needKind == "eat" or needKind == "hunger" then
        if v >= 0.70 or a >= 0.01 then return "critical" end
        if v >= 0.45 then return "medium" end
        if v >= 0.25 then return "light" end
        return nil
    elseif needKind == "drink" or needKind == "thirst" then
        if v >= 0.84 or a >= 0.01 then return "critical" end
        if v >= 0.55 then return "medium" end
        if v >= 0.25 then return "light" end
        return nil
    elseif needKind == "sleep" then
        if v >= 0.85 then return "critical" end
        if v >= 0.72 then return "medium" end
        return nil
    elseif needKind == "sit" or needKind == "fatigue" then
        if v >= 0.85 then return "critical" end
        if v >= 0.60 then return "medium" end
        if v >= 0.45 then return "light" end
        return nil
    elseif needKind == "cold" then
        local c = math.max(v, a)
        if c >= 0.70 then return "critical" end
        if c >= 0.35 then return "medium" end
        if c >= 0.15 then return "light" end
        return nil
    elseif needKind == "drop_load" or needKind == "encumbrance" then
        if v >= 0.90 then return "critical" end
        if v >= 0.75 then return "medium" end
        if v >= 0.60 then return "light" end
        return nil
    elseif needKind == "rest" or needKind == "pain" or needKind == "sickness" then
        local p = math.max(v, a)
        if p >= 0.70 then return "critical" end
        if p >= 0.40 then return "medium" end
        if p >= 0.20 then return "light" end
        return nil
    elseif needKind == "bleed" or needKind == "bleeding" then
        local b = math.max(v, a)
        if b >= 0.65 then return "critical" end
        if b >= 0.30 then return "medium" end
        if b >= 0.05 then return "light" end
        return nil
    elseif needKind == "knox" then
        local k = math.max(v, a)
        if k >= 0.85 then return "critical" end
        if k >= 0.45 then return "medium" end
        if k >= 0.20 then return "light" end
        return nil
    end
    return nil
end

local function readNPCKnoxStage(record)
    if type(record) ~= "table" then return nil, 0 end
    local body = record.health and record.health.body or record.bodyHealth or nil
    local inf = type(body) == "table" and type(body.infection) == "table" and body.infection or nil
    local knoxFever = readNPCAilmentSeverity(record, "knox_fever")
    if inf and inf.active == true then
        local stage = string.lower(tostring(inf.stage or ""))
        local prog = tonumber(inf.progress) or 0
        if stage == "terminal" or prog >= 0.85 or knoxFever >= 0.75 then
            return "critical", math.max(prog, knoxFever, 0.90)
        elseif stage == "fever" or stage == "nauseous" or prog >= 0.45 or knoxFever >= 0.30 then
            return "medium", math.max(prog, knoxFever, 0.55)
        elseif stage == "queasy" or prog >= 0.20 or knoxFever >= 0.05 then
            return "light", math.max(prog, knoxFever, 0.25)
        end
    elseif knoxFever >= 0.05 then
        local tier = knoxFever >= 0.75 and "critical" or (knoxFever >= 0.30 and "medium" or "light")
        return tier, knoxFever
    end
    return nil, 0
end

local function pumpKnoxSymptomFX(record, intensity, now)
    if type(record) ~= "table" or record.id == nil or not intensity then return false end
    local Perf = PNC.Semantics and PNC.Semantics.SpeechPerformance or nil
    if not Perf or type(Perf.Perform) ~= "function" then return false end
    local cdMs = KNOX_FX_COOLDOWN_MS[intensity] or 25000
    local key = tostring(record.id)
    local nextAt = tonumber(knoxFxCooldowns[key]) or 0
    if now < nextAt then return false end
    local spec
    if intensity == "critical" then
        local useSnarl = (math.floor(now / 1000) % 2) == 1
        spec = {
            anim = useSnarl and "PNC_Anim_PainHead" or "PNC_Anim_Sneeze",
            animDurationMs = 2800,
            voice = useSnarl and "zombie_snarl" or "zombie_growl",
            reason = "knox_symptom_critical",
        }
    elseif intensity == "medium" then
        local useSneeze = (math.floor(now / 1000) % 2) == 0
        spec = {
            anim = useSneeze and "PNC_Anim_Sneeze" or "PNC_Anim_Cough",
            animDurationMs = 2400,
            voice = useSneeze and "sneeze_heavy" or "cough",
            reason = "knox_symptom_medium",
        }
    else
        spec = {
            anim = "PNC_Anim_Sneeze",
            animDurationMs = 2000,
            voice = "sneeze",
            reason = "knox_symptom_light",
        }
    end
    local ok = Perf.Perform(record, spec, now)
    if ok then
        lruPut(knoxFxCooldowns, knoxFxOrder, key, now + cdMs)
    end
    return ok == true
end

-- Inspects either a player's PZ moodles or an NPC leader's canonical IndividualNeeds ([0,1]).
-- Note: NPCs do not have PZ Java Moodles; only players are queried via getMoodles().
function Beats.InspectLeaderMoodles(leader)
    if type(leader) ~= "table" or not leader.actor then return nil end
    local best = nil
    local function consider(need, moodle, severity, intensity)
        if severity <= 0 or not intensity then return end
        if not best or severity > best.severity then
            best = { need = need, moodle = moodle, severity = severity, intensity = intensity }
        end
    end
    if leader.kind == "player" then
        local p = leader.actor
        local endur = readPlayerMoodleLevel(p, "ENDURANCE")
        if endur >= 2 then consider("sit", "exhausted", endur + 0.5, intensityFromPlayerMoodle(endur)) end
        local tired = readPlayerMoodleLevel(p, "TIRED")
        if tired >= 2 then consider("sleep", "tired", tired + 0.3, intensityFromPlayerMoodle(tired)) end
        local hungry = readPlayerMoodleLevel(p, "HUNGRY")
        if hungry >= 2 then consider("eat", "hungry", hungry, intensityFromPlayerMoodle(hungry)) end
        local thirst = readPlayerMoodleLevel(p, "THIRST")
        if thirst >= 2 then consider("drink", "thirsty", thirst + 0.2, intensityFromPlayerMoodle(thirst)) end
        local heavy = readPlayerMoodleLevel(p, "HEAVY_LOAD")
        if heavy >= 2 then consider("drop_load", "overencumbered", heavy - 0.2, intensityFromPlayerMoodle(heavy)) end
        local pain = readPlayerMoodleLevel(p, "PAIN")
        local sick = readPlayerMoodleLevel(p, "SICK")
        if pain >= 2 or sick >= 2 then
            local peak = math.max(pain, sick)
            consider("rest", pain >= sick and "in_pain" or "sick", peak + 0.1, intensityFromPlayerMoodle(peak))
        end
        return best
    end
    local fatigue = readNPCNeed(leader.actor, "fatigue")
    local hunger = readNPCNeed(leader.actor, "hunger")
    local thirst = readNPCNeed(leader.actor, "thirst")
    local starv = readNPCAilmentSeverity(leader.actor, "starvation")
    local dehyd = readNPCAilmentSeverity(leader.actor, "dehydration")
    local cold = readNPCAilmentSeverity(leader.actor, "cold")
    local sleepTier = Beats.ClassifyNeedIntensity("sleep", fatigue)
    if sleepTier then
        consider("sleep", "tired", (INTENSITY_RANK[sleepTier] or 2) + fatigue, sleepTier)
    else
        local sitTier = Beats.ClassifyNeedIntensity("sit", fatigue)
        if sitTier then
            consider("sit", "exhausted", (INTENSITY_RANK[sitTier] or 1) + fatigue, sitTier)
        end
    end
    local thirstTier = Beats.ClassifyNeedIntensity("drink", thirst, dehyd)
    if thirstTier then
        consider("drink", "thirsty", (INTENSITY_RANK[thirstTier] or 1) + thirst + 0.2, thirstTier)
    end
    local hungerTier = Beats.ClassifyNeedIntensity("eat", hunger, starv)
    if hungerTier then
        consider("eat", "hungry", (INTENSITY_RANK[hungerTier] or 1) + hunger + 0.1, hungerTier)
    end
    local coldTier = Beats.ClassifyNeedIntensity("cold", 0, cold)
    if coldTier then
        consider("cold", "cold", (INTENSITY_RANK[coldTier] or 1) + cold, coldTier)
    end
    return best
end

local function inspectSelfNeed(record)
    if type(record) ~= "table" then return nil end
    local fatigue = readNPCNeed(record, "fatigue")
    local hunger = readNPCNeed(record, "hunger")
    local thirst = readNPCNeed(record, "thirst")
    local starv = readNPCAilmentSeverity(record, "starvation")
    local dehyd = readNPCAilmentSeverity(record, "dehydration")
    local cold = readNPCAilmentSeverity(record, "cold")
    local knoxTier, knoxProg = readNPCKnoxStage(record)
    local cond = type(record.conditionStats) == "table" and record.conditionStats or {}
    local health = type(record.health) == "table" and record.health or {}
    local bleedRate = tonumber(health.bleedingRate) or (health.bleeding == true and 0.5 or 0)
    local painVal = math.max(tonumber(cond.pain) or 0, tonumber(health.pain) or 0, tonumber(cond.sickness) or 0)
    local encVal = tonumber(cond.encumbrance) or tonumber(record.encumbranceRatio)
        or (cond.overencumbered == true and 0.80 or 0)

    local best = nil
    local function consider(need, needType, severity, intensity)
        if not intensity then return end
        if not best or severity > best.severity then
            best = { need = need, needType = needType, severity = severity, intensity = intensity }
        end
    end
    if knoxTier then
        consider("knox", "knox", (INTENSITY_RANK[knoxTier] or 1) * 1.35 + knoxProg, knoxTier)
    end
    local bleedTier = Beats.ClassifyNeedIntensity("bleed", bleedRate)
    if bleedTier then
        consider("bleed", "bleed", (INTENSITY_RANK[bleedTier] or 1) * 1.25 + bleedRate, bleedTier)
    end
    local sleepTier = Beats.ClassifyNeedIntensity("sleep", fatigue)
    if sleepTier then
        consider("sleep", "fatigue", (INTENSITY_RANK[sleepTier] or 2) * 1.1 + fatigue, sleepTier)
    else
        local sitTier = Beats.ClassifyNeedIntensity("sit", fatigue)
        if sitTier then
            consider("sit", "fatigue", (INTENSITY_RANK[sitTier] or 1) * 1.0 + fatigue, sitTier)
        end
    end
    local thirstTier = Beats.ClassifyNeedIntensity("drink", thirst, dehyd)
    if thirstTier then
        consider("drink", "thirst", (INTENSITY_RANK[thirstTier] or 1) * 1.15 + math.max(thirst, dehyd), thirstTier)
    end
    local hungerTier = Beats.ClassifyNeedIntensity("eat", hunger, starv)
    if hungerTier then
        consider("eat", "hunger", (INTENSITY_RANK[hungerTier] or 1) * 1.12 + math.max(hunger, starv), hungerTier)
    end
    local coldTier = Beats.ClassifyNeedIntensity("cold", 0, cold)
    if coldTier then
        consider("cold", "cold", (INTENSITY_RANK[coldTier] or 1) * 1.08 + cold, coldTier)
    end
    local restTier = Beats.ClassifyNeedIntensity("rest", painVal)
    if restTier then
        consider("rest", "pain", (INTENSITY_RANK[restTier] or 1) * 1.05 + painVal, restTier)
    end
    local encTier = Beats.ClassifyNeedIntensity("drop_load", encVal)
    if encTier then
        consider("drop_load", "encumbrance", (INTENSITY_RANK[encTier] or 1) * 0.95 + encVal, encTier)
    end
    return best
end

local function findNearbyListener(rec)
    local best = nil
    local bestDistSq = (12 * 12) + 1
    local rz = tonumber(rec.z) or 0
    local function considerPlayer(p)
        if not p or safeCall(p, "isDead") == true then return end
        local pz = tonumber(safeCall(p, "getZ")) or 0
        if math.abs(rz - pz) >= 1 then return end
        local px = tonumber(safeCall(p, "getX")) or 0
        local py = tonumber(safeCall(p, "getY")) or 0
        local dSq = distanceSq(rec.x, rec.y, px, py)
        if dSq <= (12 * 12) and dSq < bestDistSq then
            bestDistSq = dSq
            best = {
                kind = "player",
                actor = p,
                key = playerEntityKey(p),
                name = playerDisplayName(p),
            }
        end
    end
    if type(getOnlinePlayers) == "function" then
        local ok, players = pcall(getOnlinePlayers)
        if ok and players and type(players.size) == "function" then
            local n = tonumber(players:size()) or 0
            for i = 0, n - 1 do
                considerPlayer(players:get(i))
            end
        end
    end
    if not best and type(getSpecificPlayer) == "function" then
        local ok, p = pcall(getSpecificPlayer, 0)
        if ok and p then considerPlayer(p) end
    end
    if not best and PNC.BehaviorCommon and type(PNC.BehaviorCommon.GetOwner) == "function" then
        local owner = PNC.BehaviorCommon.GetOwner(rec)
        if owner then considerPlayer(owner) end
    end
    return best
end

local function isSameTeam(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    if a.factionId ~= nil and b.factionId ~= nil and tostring(a.factionId) == tostring(b.factionId) then
        return true
    end
    if a.groupId ~= nil and b.groupId ~= nil and tostring(a.groupId) == tostring(b.groupId) then
        return true
    end
    if a.settlementId ~= nil and b.settlementId ~= nil and tostring(a.settlementId) == tostring(b.settlementId) then
        return true
    end
    if a.recruited == true and b.recruited == true then
        return true
    end
    return false
end

local function isHostilePair(a, b)
    if type(b) ~= "table" then return false end
    local role = string.lower(tostring(b.role or b.archetype or ""))
    if role == "bandit" or role == "raider" or role == "hostile" then
        return not isSameTeam(a, b)
    end
    return false
end

local function findNearbyReassurancePartners(rec, now)
    local reg = PNC.Registry
    if not reg or type(reg.ForEach) ~= "function" then return nil, nil end
    local rz = tonumber(rec.z) or 0
    local primary, primaryScore = nil, -1
    local secondary, secondaryScore = nil, -1
    reg.ForEach(function(other)
        if type(other) ~= "table" or other.id == nil or tostring(other.id) == tostring(rec.id) then
            return
        end
        if not isCalmNPC(other, now) or isHostilePair(rec, other) then return end
        if math.abs((tonumber(other.z) or 0) - rz) >= 1 then return end
        local dSq = distanceSq(rec.x, rec.y, other.x, other.y)
        if dSq > (12 * 12) then return end
        local score = (isSameTeam(rec, other) and 1000 or 100) - dSq
        if score > primaryScore then
            secondary, secondaryScore = primary, primaryScore
            primary, primaryScore = other, score
        elseif score > secondaryScore then
            secondary, secondaryScore = other, score
        end
    end)
    return primary, secondary
end

if type(Beats.RegisterHook) == "function" then
    Beats.RegisterHook("npc.self_need_distress", {
        eventTypes = { "npc.self_need_distress" },
        priority = 54,
        cooldownMs = 0,
        evaluate = function(_, payload)
            if type(Beats.BuildWorldThread) ~= "function" then return nil end
            local a = payload and payload.speaker or nil
            if type(a) ~= "table" or a.alive == false then return nil end
            local need = tostring(payload.need or "eat")
            local intensity = tostring(payload.intensity or "medium")
            local isKnox = need == "knox"
            local openRole = isKnox and ("self_knox_" .. intensity) or ("self_" .. need)
            local replyRole = isKnox and ("react_knox_" .. intensity) or ("reassure_" .. need)
            local b = payload.partner
            local c = intensity == "critical" and payload.third or nil
            return Beats.BuildWorldThread(a, b, {
                refPrefix = "self_need:" .. need .. ":" .. intensity,
                family = "npc_self_need_" .. need,
                poolID = "semantic.companion.need_request",
                eventType = isKnox and "npc_knox_distress_beat" or "npc_self_need_beat",
                domain = isKnox and "medical" or "social",
                channel = isKnox and "medical" or "social",
                topic = isKnox and "knox_distress" or "companion_need_request",
                openAct = "INFORM",
                openRole = openRole,
                replyAct = isKnox and "REACT" or "REASSURE",
                replyRole = replyRole,
                chimeAct = isKnox and "REACT" or "REASSURE",
                chimeRole = isKnox and "react_knox_chime" or "reassure_chime",
                third = c,
                delayMs = 1350,
                priority = intensity == "critical" and 64 or 52,
                tokens = {
                    ["slot.need"] = need,
                },
                context = {
                    needType = payload.needType or need,
                    needUrgency = intensity,
                },
            })
        end,
    })
end

local function speakCompanionLine(speaker, addressee, poolID, role, act, topic, leaderName, now, opts)
    local Transport = PNC.Semantics and PNC.Semantics.SpeechTransport or nil
    if not Transport or type(Transport.ResolveLine) ~= "function" or type(Transport.Deliver) ~= "function" then
        return false, nil
    end
    opts = type(opts) == "table" and opts or {}
    local ref = tostring(opts.refPrefix or "comp_need") .. ":" .. tostring(speaker.id) .. ":" .. tostring(math.floor(now))
    local tokens = {
        ["addressee.name"] = tostring(leaderName or "boss"),
        ["slot.need"] = tostring(opts.need or "rest"),
    }
    local ctx = {
        beatRole = role,
        companionNeedRole = role,
        topic = topic,
        inCombat = false,
        needType = opts.needType or opts.need,
        needUrgency = opts.intensity or opts.needUrgency,
    }
    local text, res = Transport.ResolveLine(speaker, {
        eventType = opts.eventType or "companion_need_beat",
        eventID = ref,
        act = act or "SUGGEST",
        topic = topic,
        poolID = poolID,
        role = role,
        tokens = tokens,
        context = ctx,
        inCombat = false,
    })
    if not text then return false, nil end
    local sent = Transport.Deliver(speaker, now, {
        eventType = opts.eventType or "companion_need_beat",
        speechEventID = res and res.realizationID or (poolID .. "." .. tostring(role)),
        act = act or "SUGGEST",
        domain = "social",
        topic = topic,
        channel = "social",
        family = opts.family or "companion_need",
        priority = tonumber(opts.priority) or 52,
        priorityHoldMs = 1200,
        cooldownMs = 1500,
        familyCooldownMs = 1500,
        ttlMs = 8000,
        clientCooldowns = { familyMs = 1200, speakerMs = 1500, ambientMs = 400, mergeWindowMs = 0 },
        responsePlanID = res and res.responsePlanID or nil,
        realizationID = res and res.realizationID or nil,
        poolID = res and res.poolID or poolID,
        lightweightBark = true,
        observerOnly = true,
        eventRef = ref,
        threadID = opts.threadID or ref,
        streamKey = "compneed:" .. tostring(speaker.id),
        text = text,
        presentationClass = res and res.presentationClass or "BARK",
        context = ctx,
        addressee = addressee,
    })
    return (tonumber(sent) or 0) > 0, text
end

local function applyPairRelationshipDelta(actorA, leader, approval, respect, memoryType, now)
    local relSvc = PNC.Relationships or PNC.RelationshipService
    if not relSvc or type(relSvc.ApplyConversationEffect) ~= "function" then return false end
    local targetKey = leader.kind == "player" and leader.key or ("npc:" .. tostring(leader.id))
    local worldHours = PNC.Core and type(PNC.Core.NowWorldAgeHours) == "function"
        and PNC.Core.NowWorldAgeHours() or 0
    local ok = pcall(relSvc.ApplyConversationEffect, tostring(actorA.id), targetKey, {
        approval = approval,
        respect = respect,
        familiarity = 1,
        memoryType = memoryType,
        interactionType = memoryType,
        tags = { companion = true, needs = true },
    }, {
        worldAgeHours = worldHours,
        sourceSystem = "companion_needs",
        eventID = memoryType .. ":" .. tostring(actorA.id) .. ":" .. tostring(math.floor(now)),
    })
    return ok == true
end

-- Called when a leader sits down (from MirrorSit) or satisfies a suggested moodle.
function Beats.OnLeaderActionObserved(leaderOrActor, actionType, at)
    local now = nowMs(at)
    local leaderKey = nil
    local leaderName = "boss"
    local leaderKind = "player"
    local leaderId = nil
    if type(leaderOrActor) == "string" then
        leaderKey = leaderOrActor
    elseif type(leaderOrActor) == "table" and leaderOrActor.id ~= nil and leaderOrActor.alive ~= nil then
        leaderKey = "npc:" .. tostring(leaderOrActor.id)
        leaderKind = "npc"
        leaderId = tostring(leaderOrActor.id)
        leaderName = tostring(leaderOrActor.name or leaderOrActor.fullName or "boss")
    elseif leaderOrActor ~= nil then
        leaderKey = playerEntityKey(leaderOrActor)
        leaderName = playerDisplayName(leaderOrActor)
    end
    if not leaderKey then return false end
    local watch = pendingSuggestions[leaderKey]
    if not watch or now > (tonumber(watch.expiresAt) or 0) then
        pendingSuggestions[leaderKey] = nil
        return false
    end
    local matches = (watch.need == actionType)
        or (actionType == "sit" and (watch.need == "sit" or watch.need == "rest"))
    if not matches then return false end
    pendingSuggestions[leaderKey] = nil
    local reg = PNC.Registry
    local advisor = reg and type(reg.Get) == "function" and reg.Get(watch.advisorId) or nil
    if not isCalmNPC(advisor, now) then return false end
    local ackRole = "ack_" .. tostring(watch.need)
    local ok, text = speakCompanionLine(
        advisor,
        leaderKind == "npc" and leaderOrActor or nil,
        "semantic.companion.moodle_suggest",
        ackRole,
        "ACK",
        "companion_moodle_care",
        watch.leaderName or leaderName,
        now,
        { family = "companion_moodle_ack", need = watch.need, priority = 54 }
    )
    if ok then
        applyPairRelationshipDelta(advisor, {
            kind = leaderKind,
            key = leaderKey,
            id = leaderId or leaderKey,
        }, 1, 1, "companion_advice_followed", now)
    end
    return ok, text
end

function Beats.GetPendingCompanionNeedRequest(leaderKey, at)
    if not leaderKey then return nil end
    local now = nowMs(at)
    local req = pendingNeedRequests[tostring(leaderKey)]
    if not req then return nil end
    if now > (tonumber(req.expiresAt) or 0) then
        pendingNeedRequests[tostring(leaderKey)] = nil
        return nil
    end
    return req
end

function Beats.GetPendingKnoxBranch(listenerKey, at)
    if not listenerKey then return nil end
    local now = nowMs(at)
    local br = pendingKnoxBranches[tostring(listenerKey)]
    if not br then return nil end
    if now > (tonumber(br.expiresAt) or 0) then
        pendingKnoxBranches[tostring(listenerKey)] = nil
        return nil
    end
    return br
end

function Beats.BuildPlayerKnoxBranchChoices(listenerKeyOrActor, npcId, at)
    local key = type(listenerKeyOrActor) == "string" and listenerKeyOrActor or playerEntityKey(listenerKeyOrActor)
    if not key then return nil end
    local br = Beats.GetPendingKnoxBranch(key, at)
    if not br then return nil end
    if npcId ~= nil and tostring(br.infectedId) ~= tostring(npcId) then
        return nil
    end
    local comfortLabel = (type(getTextOrNull) == "function" and getTextOrNull("IGUI_PNC_Knox_Comfort")) or "Hang in there, I'm staying with you"
    local distanceLabel = (type(getTextOrNull) == "function" and getTextOrNull("IGUI_PNC_Knox_Distance")) or "Keep your distance, stay back"
    local confrontLabel = (type(getTextOrNull) == "function" and getTextOrNull("IGUI_PNC_Knox_Confront")) or "You're turning — get away from us!"
    return {
        {
            id = "knox_comfort:" .. tostring(br.branchId),
            label = comfortLabel,
            text = "comfort",
            utterance = "comfort",
            intent = "ACCEPT",
            speechAct = "ACCEPT",
            stance = "stance_positive",
            topic = "knox_distress",
            priority = 99,
            source = "knox_distress_branch",
        },
        {
            id = "knox_distance:" .. tostring(br.branchId),
            label = distanceLabel,
            text = "distance",
            utterance = "distance",
            intent = "CLARIFY",
            speechAct = "CLARIFY",
            stance = "stance_neutral",
            topic = "knox_distress",
            priority = 97,
            source = "knox_distress_branch",
        },
        {
            id = "knox_confront:" .. tostring(br.branchId),
            label = confrontLabel,
            text = "confront",
            utterance = "confront",
            intent = "REFUSE",
            speechAct = "REFUSE",
            stance = "stance_negative",
            topic = "knox_distress",
            priority = 95,
            source = "knox_distress_branch",
        },
    }
end

function Beats.ResolveKnoxBranchChoice(listenerKey, decision, opts)
    opts = type(opts) == "table" and opts or {}
    local now = nowMs(opts.now)
    local br = Beats.GetPendingKnoxBranch(listenerKey, now)
    if not br then return false, "no_pending_knox_branch" end
    pendingKnoxBranches[tostring(listenerKey)] = nil

    local norm = string.lower(tostring(decision or ""))
    local stance = "distance"
    if norm == "comfort" or norm == "yes" or norm == "accept" or norm == "stance_positive" or norm == "reassure" then
        stance = "comfort"
    elseif norm == "confront" or norm == "no" or norm == "refuse" or norm == "stance_negative" or norm == "back_off" then
        stance = "confront"
    end

    local reg = PNC.Registry
    local infected = reg and type(reg.Get) == "function" and reg.Get(br.infectedId) or nil
    if not infected or infected.alive == false then
        return false, "infected_unavailable"
    end

    local _, replyText = speakCompanionLine(
        infected,
        br.listenerKind == "npc" and br.listenerActor or nil,
        "semantic.companion.need_request",
        "knox_reply_" .. stance,
        stance == "comfort" and "THANK" or "REACT",
        "knox_distress",
        br.listenerName or "friend",
        now,
        {
            family = "knox_branch_outcome",
            need = "knox",
            needType = "knox",
            intensity = br.stage or "medium",
            priority = 62,
        }
    )

    local dApp = stance == "comfort" and 2 or (stance == "confront" and -2 or 0)
    local dRep = stance == "comfort" and 1 or (stance == "confront" and -1 or 0)
    if dApp ~= 0 or dRep ~= 0 then
        applyPairRelationshipDelta(
            infected,
            { kind = br.listenerKind, key = br.listenerKey, id = br.listenerId or br.listenerKey },
            dApp,
            dRep,
            "knox_distress_" .. stance,
            now
        )
    end
    return true, {
        stance = stance,
        stage = br.stage,
        infectedId = br.infectedId,
        replyText = replyText,
        role = "knox_reply_" .. stance,
        topic = "knox_distress",
    }
end

function Beats.TryResolvePlayerNeedReply(leaderKeyOrActor, npcId, decision, at)
    local key = type(leaderKeyOrActor) == "string" and leaderKeyOrActor or playerEntityKey(leaderKeyOrActor)
    if not key then return false, nil end
    local knoxBr = Beats.GetPendingKnoxBranch(key, at)
    if knoxBr and (npcId == nil or tostring(knoxBr.infectedId) == tostring(npcId)) then
        return Beats.ResolveKnoxBranchChoice(key, decision, { now = at })
    end
    local req = Beats.GetPendingCompanionNeedRequest(key, at)
    if not req then return false, nil end
    if npcId ~= nil and tostring(req.requesterId) ~= tostring(npcId) then
        return false, nil
    end
    return Beats.ResolveCompanionNeedRequest(key, decision, { now = at })
end

function Beats.BuildPlayerNeedRequestChoices(leaderKeyOrActor, npcId, at)
    local knoxChoices = Beats.BuildPlayerKnoxBranchChoices(leaderKeyOrActor, npcId, at)
    if knoxChoices then return knoxChoices end
    local key = type(leaderKeyOrActor) == "string" and leaderKeyOrActor or playerEntityKey(leaderKeyOrActor)
    if not key then return nil end
    local req = Beats.GetPendingCompanionNeedRequest(key, at)
    if not req then return nil end
    if npcId ~= nil and tostring(req.requesterId) ~= tostring(npcId) then
        return nil
    end
    local yesLabel = (type(getTextOrNull) == "function" and getTextOrNull("IGUI_PNC_NeedReq_Yes")) or "Yes, take a break"
    local noLabel = (type(getTextOrNull) == "function" and getTextOrNull("IGUI_PNC_NeedReq_No")) or "Not now, keep moving"
    return {
        {
            id = "companion_need_yes:" .. tostring(req.requestId),
            label = yesLabel,
            text = "yes",
            utterance = "yes",
            intent = "ACCEPT",
            speechAct = "ACCEPT",
            topic = "companion_need_request",
            priority = 98,
            source = "companion_need_request",
        },
        {
            id = "companion_need_no:" .. tostring(req.requestId),
            label = noLabel,
            text = "no",
            utterance = "no",
            intent = "REFUSE",
            speechAct = "REFUSE",
            topic = "companion_need_request",
            priority = 96,
            source = "companion_need_request",
        },
    }
end

-- Resolves a pending follower-to-leader need request with branching Yes/No.
-- Works identically for both player leaders (UI/chat reply) and NPC group leaders.
function Beats.ResolveCompanionNeedRequest(leaderKey, decision, opts)
    opts = type(opts) == "table" and opts or {}
    local now = nowMs(opts.now)
    local req = Beats.GetPendingCompanionNeedRequest(leaderKey, now)
    if not req then return false, "no_pending_request" end
    pendingNeedRequests[tostring(leaderKey)] = nil

    local norm = string.lower(tostring(decision or ""))
    local approved = (norm == "yes" or norm == "accept" or norm == "agree" or norm == "approve" or decision == true)
    local reg = PNC.Registry
    local requester = reg and type(reg.Get) == "function" and reg.Get(req.requesterId) or nil
    if not requester or requester.alive == false then
        return false, "requester_unavailable"
    end
    local leaderRec = req.leaderKind == "npc"
        and reg and type(reg.Get) == "function" and reg.Get(req.leaderId) or nil

    -- If an NPC leader is resolving autonomously, speak the leader's Yes/No line first.
    local leaderText = nil
    if req.leaderKind == "npc" and leaderRec and isCalmNPC(leaderRec, now) then
        local lRole = approved and "leader_approve" or "leader_deny"
        local lAct = approved and "ACCEPT" or "REFUSE"
        local _, txt = speakCompanionLine(
            leaderRec,
            requester,
            "semantic.companion.need_request",
            lRole,
            lAct,
            "companion_need_request",
            tostring(requester.name or requester.fullName or "friend"),
            now,
            { family = "companion_need_decision", need = req.need, priority = 56 }
        )
        leaderText = txt
    end

    -- Apply gameplay effect on Yes
    if approved then
        requester.runtime = requester.runtime or {}
        if req.need == "sit" or req.need == "sleep" or req.need == "rest" then
            requester.runtime.companionBreakSitUntil = now + BREAK_SIT_DURATION_MS
            local body = reg and type(reg.GetLiveZombie) == "function" and reg.GetLiveZombie(requester.id) or nil
            local mirrorSit = PNC.BehaviorCompanion and PNC.BehaviorCompanion.Internal
                and PNC.BehaviorCompanion.Internal.MirrorSit or nil
            if body and mirrorSit and type(mirrorSit.TryStart) == "function" then
                mirrorSit.TryStart(requester, body, nil, 0, nil, nil, false, nil, now)
            end
        end
    end

    -- Follower reacts to Yes or No
    local replyRole = approved and "requester_approved" or "requester_denied"
    local replyAct = approved and "THANK" or "REACT"
    local _, replyText = speakCompanionLine(
        requester,
        leaderRec,
        "semantic.companion.need_request",
        replyRole,
        replyAct,
        "companion_need_request",
        req.leaderName or "boss",
        now + (leaderText and 1300 or 0),
        { family = "companion_need_outcome", need = req.need, priority = 55 }
    )

    -- Organic relationship / stance impact
    local Dir = PNC.Semantics and PNC.Semantics.ConversationDirector or nil
    if req.leaderKind == "npc" and leaderRec and Dir and type(Dir.EvaluateStanceImpact) == "function" then
        Dir.EvaluateStanceImpact(
            leaderRec,
            requester,
            {},
            "companion_need_request",
            approved and "ACCEPT" or "REFUSE",
            { now = now, topicInstanceKey = req.requestId }
        )
    else
        local dApp = approved and 2 or ((tonumber(req.severity) or 0) >= 2.5 and -2 or -1)
        local dRep = approved and 1 or ((tonumber(req.severity) or 0) >= 2.5 and -1 or 0)
        applyPairRelationshipDelta(
            requester,
            { kind = req.leaderKind, key = req.leaderKey, id = req.leaderId },
            dApp,
            dRep,
            approved and "companion_need_approved" or "companion_need_denied",
            now
        )
    end

    return true, {
        approved = approved,
        need = req.need,
        requesterId = req.requesterId,
        leaderText = leaderText,
        replyText = replyText,
    }
end

local function checkWatchedPlayerMoodles(leader, now)
    local watch = pendingSuggestions[leader.key]
    if not watch then return false end
    if now > (tonumber(watch.expiresAt) or 0) then
        pendingSuggestions[leader.key] = nil
        return false
    end
    if leader.kind ~= "player" then return false end
    local p = leader.actor
    local satisfied = false
    if watch.need == "eat" then
        satisfied = readPlayerMoodleLevel(p, "FOOD_EATEN") >= 1
            or readPlayerMoodleLevel(p, "HUNGRY") < (tonumber(watch.initialSeverity) or 2)
    elseif watch.need == "drink" then
        satisfied = readPlayerMoodleLevel(p, "THIRST") < (tonumber(watch.initialSeverity) or 2)
    elseif watch.need == "drop_load" then
        satisfied = readPlayerMoodleLevel(p, "HEAVY_LOAD") < (tonumber(watch.initialSeverity) or 2)
    elseif watch.need == "sleep" then
        satisfied = safeCall(p, "isAsleep") == true
            or readPlayerMoodleLevel(p, "TIRED") < (tonumber(watch.initialSeverity) or 2)
    elseif watch.need == "sit" or watch.need == "rest" then
        local mirrorSit = PNC.BehaviorCompanion and PNC.BehaviorCompanion.Internal
            and PNC.BehaviorCompanion.Internal.MirrorSit or nil
        if mirrorSit and mirrorSit.IsActorSeated(p) then satisfied = true end
    end
    if satisfied then
        return Beats.OnLeaderActionObserved(p, watch.need, now)
    end
    return false
end

function Beats.CheckCompanionNeeds(at)
    local now = nowMs(at)
    if now < (lastCheckAt + CHECK_COOLDOWN_MS) then return false end
    lastCheckAt = now

    local reg = PNC.Registry
    if not reg or type(reg.ForEach) ~= "function" then return false end
    local Dir = PNC.Semantics and PNC.Semantics.ConversationDirector or nil

    local acted = false
    reg.ForEach(function(rec)
        if not isCalmNPC(rec, now) then return end
        -- Frequent Knox symptom SFX/animations (sneeze -> heavy sneeze/cough -> zombie growl)
        local knoxTier = readNPCKnoxStage(rec)
        if knoxTier then
            pumpKnoxSymptomFX(rec, knoxTier, now)
        end
        if acted then return end
        local leader = Beats.ResolveLeaderForCompanion(rec)
        if leader and leader.key then
            if math.abs((tonumber(rec.z) or 0) - (tonumber(leader.z) or 0)) < 1
                and distanceSq(rec.x, rec.y, leader.x, leader.y) <= (12 * 12)
            then
                -- 1) Check if leader followed through on a previous companion suggestion
                if checkWatchedPlayerMoodles(leader, now) then
                    acted = true
                    return
                end

                -- 2) Companion observes leader's moodles & suggests an action
                if not pendingSuggestions[leader.key] then
                    local moodleHit = Beats.InspectLeaderMoodles(leader)
                    if moodleHit then
                        local cdKey = tostring(rec.id) .. ":" .. leader.key .. ":" .. moodleHit.need
                        if cooldownAllows(suggestCooldowns, cdKey, moodleHit.intensity, now) then
                            local ok = speakCompanionLine(
                                rec,
                                leader.kind == "npc" and leader.actor or nil,
                                "semantic.companion.moodle_suggest",
                                "suggest_" .. moodleHit.need,
                                "SUGGEST",
                                "companion_moodle_care",
                                leader.name,
                                now,
                                {
                                    family = "companion_moodle_suggest",
                                    need = moodleHit.need,
                                    intensity = moodleHit.intensity,
                                    priority = moodleHit.intensity == "critical" and 58 or 52,
                                }
                            )
                            if ok then
                                local cd = moodleHit.intensity == "critical" and NEED_CRITICAL_COOLDOWN_MS or SUGGEST_COOLDOWN_MS
                                setIntensityCooldown(suggestCooldowns, suggestOrder, cdKey, now + cd, moodleHit.intensity)
                                if leader.kind == "npc" and leader.id ~= nil then
                                    setIntensityCooldown(
                                        selfNeedCooldowns, selfNeedOrder,
                                        tostring(leader.id) .. ":" .. moodleHit.need,
                                        now + cd, moodleHit.intensity
                                    )
                                end
                                pendingSuggestions[leader.key] = {
                                    advisorId = rec.id,
                                    leaderName = leader.name,
                                    need = moodleHit.need,
                                    initialSeverity = moodleHit.severity,
                                    intensity = moodleHit.intensity,
                                    suggestedAt = now,
                                    expiresAt = now + SUGGEST_WATCH_TTL_MS,
                                }
                                if type(Beats.AuditLog) == "function" then
                                    Beats.AuditLog("companion_need_suggest", {
                                        "speaker=" .. tostring(rec.id),
                                        "leader=" .. tostring(leader.key),
                                        "need=" .. tostring(moodleHit.need),
                                        "intensity=" .. tostring(moodleHit.intensity),
                                    })
                                end
                                acted = true
                                return
                            end
                        end
                    end
                end

                -- 3) Companion has their own need -> requests permission from leader (Yes / No branching)
                if not pendingNeedRequests[leader.key] then
                    local selfNeed = inspectSelfNeed(rec)
                    if selfNeed and selfNeed.need ~= "knox" then
                        local rCdKey = tostring(rec.id) .. ":" .. selfNeed.need
                        if cooldownAllows(requestCooldowns, rCdKey, selfNeed.intensity, now) then
                            local ok = speakCompanionLine(
                                rec,
                                leader.kind == "npc" and leader.actor or nil,
                                "semantic.companion.need_request",
                                "request_" .. selfNeed.need,
                                "REQUEST",
                                "companion_need_request",
                                leader.name,
                                now,
                                {
                                    family = "companion_need_request",
                                    need = selfNeed.need,
                                    needType = selfNeed.needType,
                                    intensity = selfNeed.intensity,
                                    priority = selfNeed.intensity == "critical" and 62 or 55,
                                }
                            )
                            if ok then
                                requestSeq = requestSeq + 1
                                local reqId = "comp_req:" .. tostring(rec.id) .. ":" .. tostring(requestSeq)
                                local cd = selfNeed.intensity == "critical" and NEED_CRITICAL_COOLDOWN_MS or NEED_REQUEST_COOLDOWN_MS
                                setIntensityCooldown(requestCooldowns, requestOrder, rCdKey, now + cd, selfNeed.intensity)
                                pendingNeedRequests[leader.key] = {
                                    requestId = reqId,
                                    requesterId = rec.id,
                                    leaderKind = leader.kind,
                                    leaderKey = leader.key,
                                    leaderId = leader.id,
                                    leaderName = leader.name,
                                    need = selfNeed.need,
                                    severity = selfNeed.severity,
                                    intensity = selfNeed.intensity,
                                    createdAt = now,
                                    expiresAt = now + NEED_REQUEST_TTL_MS,
                                    frontier = NEED_REQUEST_FRONTIER,
                                }
                                if type(Beats.AuditLog) == "function" then
                                    Beats.AuditLog("companion_need_request", {
                                        "speaker=" .. tostring(rec.id),
                                        "leader=" .. tostring(leader.key),
                                        "need=" .. tostring(selfNeed.need),
                                        "intensity=" .. tostring(selfNeed.intensity),
                                    })
                                end
                                -- If leader is an NPC, evaluate the Yes/No frontier autonomously!
                                if leader.kind == "npc" and leader.actor then
                                    local chosen = Dir and type(Dir.SelectSuggestionForNPC) == "function"
                                        and Dir.SelectSuggestionForNPC(leader.actor, rec, NEED_REQUEST_FRONTIER, {
                                            now = now,
                                            sceneTension = 0,
                                        }) or NEED_REQUEST_FRONTIER[1]
                                    local decision = chosen and chosen.decision or "yes"
                                    Beats.ResolveCompanionNeedRequest(leader.key, decision, { now = now + 1200 })
                                end
                                acted = true
                                return
                            end
                        end
                    end
                end
            end
            if not knoxTier then return end
        end

        -- 4) First-person NPC need distress + nearby NPC reassurance (works for colonists,
        -- faction members, group leaders, and any nearby survivor)
        local selfNeed = inspectSelfNeed(rec)
        if not selfNeed then return end
        local listener = findNearbyListener(rec)
        local partner, third = findNearbyReassurancePartners(rec, now)
        if not listener and not partner then return end
        local sCdKey = tostring(rec.id) .. ":" .. selfNeed.need
        if not cooldownAllows(selfNeedCooldowns, sCdKey, selfNeed.intensity, now) then return end
        local ok = false
        local isKnox = selfNeed.need == "knox"
        local openRole = isKnox and ("self_knox_" .. selfNeed.intensity) or ("self_" .. selfNeed.need)
        local replyRole = isKnox and ("react_knox_" .. selfNeed.intensity) or ("reassure_" .. selfNeed.need)
        if type(Beats.Emit) == "function" and type(Beats.BuildWorldThread) == "function" then
            ok = Beats.Emit("npc.self_need_distress", {
                speaker = rec,
                partner = partner,
                third = third,
                need = selfNeed.need,
                needType = selfNeed.needType,
                intensity = selfNeed.intensity,
            }, now) == true
        else
            local addresseeName = (partner and tostring(partner.name or partner.fullName or ""))
                or (listener and listener.name) or "friend"
            ok = speakCompanionLine(
                rec,
                partner,
                "semantic.companion.need_request",
                openRole,
                "INFORM",
                isKnox and "knox_distress" or "companion_need_request",
                addresseeName,
                now,
                {
                    family = isKnox and "npc_knox_distress" or "npc_self_need",
                    need = selfNeed.need,
                    needType = selfNeed.needType,
                    intensity = selfNeed.intensity,
                    priority = selfNeed.intensity == "critical" and 64 or 52,
                }
            )
            if ok and partner then
                speakCompanionLine(
                    partner,
                    rec,
                    "semantic.companion.need_request",
                    replyRole,
                    isKnox and "REACT" or "REASSURE",
                    isKnox and "knox_distress" or "companion_need_request",
                    tostring(rec.name or rec.fullName or "friend"),
                    now + 1350,
                    {
                        family = isKnox and "npc_knox_react" or "npc_self_need_reassure",
                        need = selfNeed.need,
                        needType = selfNeed.needType,
                        intensity = selfNeed.intensity,
                        priority = selfNeed.intensity == "critical" and 62 or 48,
                    }
                )
            end
        end
        if ok then
            local cd = selfNeed.intensity == "critical" and SELF_NEED_CRITICAL_COOLDOWN_MS or SELF_NEED_COOLDOWN_MS
            setIntensityCooldown(selfNeedCooldowns, selfNeedOrder, sCdKey, now + cd, selfNeed.intensity)
            if isKnox then
                requestSeq = requestSeq + 1
                local brId = "knox_br:" .. tostring(rec.id) .. ":" .. tostring(requestSeq)
                if listener and listener.key then
                    pendingKnoxBranches[listener.key] = {
                        branchId = brId,
                        infectedId = rec.id,
                        stage = selfNeed.intensity,
                        listenerKind = "player",
                        listenerKey = listener.key,
                        listenerId = listener.key,
                        listenerName = listener.name,
                        createdAt = now,
                        expiresAt = now + KNOX_BRANCH_TTL_MS,
                        frontier = KNOX_BRANCH_FRONTIER,
                    }
                elseif partner and partner.id ~= nil then
                    local pKey = "npc:" .. tostring(partner.id)
                    pendingKnoxBranches[pKey] = {
                        branchId = brId,
                        infectedId = rec.id,
                        stage = selfNeed.intensity,
                        listenerKind = "npc",
                        listenerKey = pKey,
                        listenerId = tostring(partner.id),
                        listenerActor = partner,
                        listenerName = tostring(partner.name or partner.fullName or "friend"),
                        createdAt = now,
                        expiresAt = now + KNOX_BRANCH_TTL_MS,
                        frontier = KNOX_BRANCH_FRONTIER,
                    }
                    local chosen = Dir and type(Dir.SelectSuggestionForNPC) == "function"
                        and Dir.SelectSuggestionForNPC(partner, rec, KNOX_BRANCH_FRONTIER, {
                            now = now,
                            sceneTension = selfNeed.intensity == "critical" and 0.8 or 0.4,
                        }) or KNOX_BRANCH_FRONTIER[1]
                    Beats.ResolveKnoxBranchChoice(pKey, chosen and chosen.decision or "distance", { now = now + 2600 })
                end
            end
            if partner and partner.id ~= nil then
                setIntensityCooldown(
                    suggestCooldowns, suggestOrder,
                    tostring(partner.id) .. ":npc:" .. tostring(rec.id) .. ":" .. selfNeed.need,
                    now + cd, selfNeed.intensity
                )
            end
            if type(Beats.AuditLog) == "function" then
                Beats.AuditLog("npc_self_need", {
                    "speaker=" .. tostring(rec.id),
                    "partner=" .. tostring(partner and partner.id or "none"),
                    "listener=" .. tostring(listener and listener.key or "none"),
                    "need=" .. tostring(selfNeed.need),
                    "intensity=" .. tostring(selfNeed.intensity),
                })
            end
            acted = true
        end
    end)
    return acted
end

function Beats.ResetCompanionNeedsRuntime()
    lastCheckAt = 0
    suggestCooldowns, suggestOrder = {}, {}
    requestCooldowns, requestOrder = {}, {}
    selfNeedCooldowns, selfNeedOrder = {}, {}
    knoxFxCooldowns, knoxFxOrder = {}, {}
    pendingSuggestions = {}
    pendingNeedRequests = {}
    pendingKnoxBranches = {}
    requestSeq = 0
end

local Dir = PNC.Semantics and PNC.Semantics.ConversationDirector or nil
if Dir and type(Dir.RegisterTopicAxis) == "function" then
    Dir.RegisterTopicAxis("companion_moodle_care", "compassion")
    Dir.RegisterTopicAxis("companion_need_request", "compassion")
    Dir.RegisterTopicAxis("knox_distress", "compassion")
end

return Beats
