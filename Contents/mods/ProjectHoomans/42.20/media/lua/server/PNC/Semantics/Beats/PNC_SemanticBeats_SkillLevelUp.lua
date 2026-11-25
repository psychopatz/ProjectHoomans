-- Method-aware NPC skill level-up dialogue beats.
-- Listens to EventTypes.NPC_SKILL_LEVEL_UP and routes multi-NPC + player
-- level-up reactions through ConversationDirector with grounded skill, level,
-- and earning-method context (tv_broadcast, combat, building, exercise,
-- cooking, medical, survival, reading, general).
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Beats = PNC.Semantics.DialogueBeats or {}
PNC.Semantics.DialogueBeats = Beats

local Dir = PNC.Semantics.ConversationDirector
if Dir and type(Dir.RegisterTopicPolicy) == "function" then
    Dir.RegisterTopicPolicy("skill_level_up", {
        tier = 2,
        urgency = 56,
        salience = 72,
        saturationWindowMs = 25000,
        silenceThreshold = 36,
    })
end

local VALID_METHODS = {
    tv_broadcast = true,
    combat = true,
    building = true,
    exercise = true,
    cooking = true,
    medical = true,
    survival = true,
    reading = true,
    general = true,
}

local SKILL_DEFAULT_METHOD = {
    Aiming = "combat",
    Reloading = "combat",
    Axe = "combat",
    LongBlade = "combat",
    LongBlunt = "combat",
    ShortBlade = "combat",
    ShortBlunt = "combat",
    Spear = "combat",
    Maintenance = "combat",
    Carpentry = "building",
    Masonry = "building",
    Welding = "building",
    Carving = "building",
    Electrical = "building",
    Blacksmithing = "building",
    Glassmaking = "building",
    Pottery = "building",
    Knapping = "building",
    Fitness = "exercise",
    Strength = "exercise",
    Sprinting = "exercise",
    Nimble = "exercise",
    Lightfooted = "exercise",
    Sneaking = "exercise",
    Cooking = "cooking",
    Butchering = "cooking",
    FirstAid = "medical",
    Fishing = "survival",
    Agriculture = "survival",
    AnimalCare = "survival",
    Mechanics = "survival",
    Tailoring = "survival",
}

local function nowMs(at)
    if at ~= nil then return tonumber(at) or 0 end
    if PNC.Core and type(PNC.Core.Now) == "function" then
        return tonumber(PNC.Core.Now()) or 0
    end
    return 0
end

local function resolveSkillDisplay(skillID)
    local id = tostring(skillID or "")
    local cat = PNC.SkillCatalog
    if cat and type(cat.Find) == "function" then
        local entry = cat.Find(id)
        if type(entry) == "table" and entry.display then
            return tostring(entry.display)
        end
    end
    return id ~= "" and id or "that skill"
end

local function resolveLevelUpMethod(record, skillID, meta)
    local explicit = type(meta) == "table" and (meta.source or meta.method) or nil
    if explicit and VALID_METHODS[tostring(explicit)] then
        return tostring(explicit)
    end
    local rt = type(record) == "table" and type(record.runtime) == "table" and record.runtime or nil
    if rt and rt.lastXPSkill == skillID and rt.lastXPSource and VALID_METHODS[tostring(rt.lastXPSource)] then
        return tostring(rt.lastXPSource)
    end
    if rt and rt.target ~= nil then
        return "combat"
    end
    local order = type(record) == "table" and type(record.orderSpec) == "table" and record.orderSpec or nil
    local okind = string.lower(tostring(order and order.kind or ""))
    if string.find(okind, "build", 1, true) or string.find(okind, "construct", 1, true) or string.find(okind, "craft", 1, true) then
        return "building"
    elseif string.find(okind, "exercis", 1, true) or string.find(okind, "workout", 1, true) then
        return "exercise"
    elseif string.find(okind, "cook", 1, true) then
        return "cooking"
    elseif string.find(okind, "medic", 1, true) or string.find(okind, "bandage", 1, true) or string.find(okind, "treat", 1, true) then
        return "medical"
    elseif string.find(okind, "fish", 1, true) or string.find(okind, "farm", 1, true) or string.find(okind, "forag", 1, true) then
        return "survival"
    end
    return SKILL_DEFAULT_METHOD[tostring(skillID or "")] or "general"
end

local function findNearbyAllies(record, now)
    local sp = PNC.SpatialIndex
    local perc = PNC.Perception
    if not sp or type(sp.QueryNPCs) ~= "function" or not record.x or not record.y then
        return nil, nil
    end
    local list = sp.QueryNPCs(record.x, record.y, 12) or {}
    local tk = perc and perc.GetTeamKey and perc.GetTeamKey(record) or nil
    local hasAllyCheck = perc and type(perc.AreWarningAllies) == "function"
    local partner, third = nil, nil
    for i = 1, #list do
        local other = list[i]
        if type(other) == "table" and other.id ~= record.id and other.alive ~= false then
            local otherTk = perc and perc.GetTeamKey and perc.GetTeamKey(other) or nil
            local sameTeam = (tk and otherTk and tk == otherTk)
                or (hasAllyCheck and perc.AreWarningAllies(record, other) == true)
            if sameTeam then
                if not partner then
                    partner = other
                elseif not third then
                    third = other
                    break
                end
            end
        end
    end
    return partner, third
end

Beats.RegisterHook("progression.skill_level_up", {
    eventTypes = { "progression.skill_level_up" },
    priority = 40,
    cooldownMs = 0,
    evaluate = function(_, payload)
        local a = payload.anchor or payload.speaker
        if type(a) ~= "table" or a.alive == false then return nil end
        if type(Beats.BuildWorldThread) ~= "function" then return nil end
        local method = tostring(payload.method or "general")
        local b = payload.partner
        local c = payload.third
        return Beats.BuildWorldThread(a, b, {
            refPrefix = "levelup:" .. tostring(payload.skillID or "skill") .. ":" .. method,
            family = "progression_level_up_" .. method,
            poolID = "semantic.progression.level_up",
            eventType = "progression_level_up_beat",
            domain = "social",
            channel = "social",
            topic = "level_up_" .. method,
            openAct = "INFORM",
            replyAct = "PRAISE",
            chimeAct = "AGREE",
            openRole = method .. "_open",
            replyRole = b and (method .. "_reply") or nil,
            chimeRole = c and (method .. "_chime") or nil,
            third = c,
            priority = 40,
            delayMs = 1150,
            chimeDelayMs = 2450,
            tokens = {
                ["slot.skill.name"] = tostring(payload.skillName or "that skill"),
                ["slot.skill.level"] = tostring(payload.level or 1),
                ["slot.show.name"] = tostring(payload.showName or "that broadcast"),
                ["show.name"] = tostring(payload.showName or "that broadcast"),
            },
        })
    end,
})

function Beats.OnNPCSkillLevelUp(record, skillID, newLevel, meta, at)
    if type(record) ~= "table" or record.alive == false or record.id == nil then
        return false, "invalid_actor"
    end
    local now = nowMs(at)
    local method = resolveLevelUpMethod(record, skillID, meta)
    local skillName = resolveSkillDisplay(skillID)
    local showName = type(meta) == "table" and meta.showName or nil

    local perc = PNC.Perception
    local gKey = tostring((perc and perc.GetTeamKey and perc.GetTeamKey(record)) or record.id)
    local director = PNC.Semantics and PNC.Semantics.ConversationDirector or nil
    if director and type(director.GateEmitter) == "function" then
        local okGate, info = director.GateEmitter("skill_level_up", record, {
            scopeKey = "levelup:" .. tostring(record.id),
            groupKey = gKey,
            topic = "skill_level_up",
            tier = math.min(3, math.max(1, math.floor((tonumber(newLevel) or 1) / 3) + 1)),
            now = now,
        })
        if not okGate then
            return false, tostring(info and info.reason or "director_suppressed")
        end
    end

    local partner, third = findNearbyAllies(record, now)
    local ok, tid = Beats.Emit("progression.skill_level_up", {
        anchor = record,
        speaker = record,
        partner = partner,
        third = third,
        skillID = skillID,
        skillName = skillName,
        level = tonumber(newLevel) or 1,
        method = method,
        showName = showName,
    }, now)
    if ok and director and type(director.RecordStoryMoment) == "function" and method == "tv_broadcast" then
        director.RecordStoryMoment(gKey, {
            kind = "skill_level_up",
            topic = "post_skill_show",
            actorId = record.id,
            salience = 76,
            valence = 1,
            ttlMs = 360000,
            meta = {
                showName = showName or "Life and Living",
                episode = skillName .. " (Level " .. tostring(newLevel or 1) .. ")",
                channelName = "Life and Living TV",
                topicLabel = skillName,
                theme = "skill_show",
            },
        }, now)
    end
    return ok, tid
end

function Beats.ResetSkillLevelUpRuntime()
end

if PNC.Events and type(PNC.Events.on) == "function"
    and PNC.EventTypes and PNC.EventTypes.NPC_SKILL_LEVEL_UP
    and not Beats._SkillLevelUpSubscribed
then
    PNC.Events.on(PNC.EventTypes.NPC_SKILL_LEVEL_UP, function(record, skillID, newLevel, meta)
        Beats.OnNPCSkillLevelUp(record, skillID, newLevel, meta, nil)
    end)
    Beats._SkillLevelUpSubscribed = true
end

return Beats
