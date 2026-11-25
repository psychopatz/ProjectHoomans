-- Final-Kill & Post-Skirmish Relief / Applause Dialogue Beat.
-- Event-driven, zero per-frame scans (O(1) single-timestamp guard when idle).
-- Actor-agnostic (NPC solo, NPC squad, or Player slayer) and archetype-flavored
-- (companion/colonist, guard, trader, neutral, hostile) with threat-type &
-- intensity awareness (straggler, couple, horde, hostile_human, wounded_close_call).
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Beats = PNC.Semantics.DialogueBeats or {}
PNC.Semantics.DialogueBeats = Beats

local SETTLE_MS = 2200
local RETRY_DEFER_MS = 1500
local MAX_DEFERS = 4
local TEAM_COOLDOWN_MS = 35000
local MAX_TRACKED_TEAMS = 32
local ALLY_RADIUS_SQ = 14 * 14

local pendingSkirmishes = {}
local pendingOrder = {}
local teamCooldowns, teamCooldownOrder = {}, {}
local nextResolveAt = 0

local function nowMs(at)
    if at ~= nil then return tonumber(at) or 0 end
    return PNC.Core and type(PNC.Core.Now) == "function" and tonumber(PNC.Core.Now()) or 0
end

local function lruPut(map, order, key, val)
    if map[key] == nil then
        while #order >= MAX_TRACKED_TEAMS do
            local oldest = table.remove(order, 1)
            map[oldest] = nil
        end
        order[#order + 1] = key
    end
    map[key] = val
end

local function removeOrder(order, key)
    for i = #order, 1, -1 do
        if order[i] == key then
            table.remove(order, i)
            return
        end
    end
end

local function recomputeNextResolveAt()
    local minAt = 0
    for i = 1, #pendingOrder do
        local s = pendingSkirmishes[pendingOrder[i]]
        if s and s.resolveAt and (minAt == 0 or s.resolveAt < minAt) then
            minAt = s.resolveAt
        end
    end
    nextResolveAt = minAt
end

local function playerEntityKey(p)
    if not p then return nil end
    if PNC.PlayerCharacters and type(PNC.PlayerCharacters.GetEntityKey) == "function" then
        local k = PNC.PlayerCharacters.GetEntityKey(p)
        if k and tostring(k) ~= "" then return tostring(k) end
    end
    local oid = p.getOnlineID and p:getOnlineID() or nil
    if oid ~= nil and tonumber(oid) and tonumber(oid) >= 0 then return "player:" .. tostring(oid) end
    local uname = p.getUsername and p:getUsername() or nil
    return (uname and tostring(uname) ~= "") and ("player:" .. tostring(uname)) or "player:local"
end

local function playerDisplayName(p)
    if not p then return "boss" end
    local desc = p.getDescriptor and p:getDescriptor() or nil
    local fore = desc and desc.getForename and tostring(desc:getForename() or "") or ""
    if fore ~= "" then return fore end
    local disp = p.getDisplayName and tostring(p:getDisplayName() or "") or ""
    if disp ~= "" then return disp end
    local uname = p.getUsername and tostring(p:getUsername() or "") or ""
    return uname ~= "" and uname or "boss"
end

local function isLiveNPC(rec)
    if type(rec) ~= "table" or rec.id == nil or rec.alive == false then return false end
    if rec.departed == true or rec.removed == true then return false end
    local live = tostring(PNC.Const and PNC.Const.PRESENCE_LIVE or "live")
    if rec.presenceState ~= nil and tostring(rec.presenceState) ~= live then return false end
    return true
end

local function isInActiveFight(rec, now)
    local rt = type(rec) == "table" and rec.runtime or nil
    if type(rt) ~= "table" then return false end
    if rt.target ~= nil or rt.attackAction ~= nil or rt.combatTarget ~= nil then
        return true
    end
    return now < (tonumber(rt.inCombatUntil) or 0)
end

local function wasDamagedDuringSkirmish(rec, startedAt)
    if type(rec) ~= "table" then return false end
    local h = type(rec.health) == "table" and rec.health or nil
    if not h then return false end
    if h.bleeding == true or tostring(h.state or "") == "incapacitated" then return true end
    if tonumber(h.recentDamageUntil) and tonumber(h.recentDamageUntil) >= startedAt then return true end
    if tonumber(h.lastDamagedAt) and tonumber(h.lastDamagedAt) >= startedAt then return true end
    if tonumber(h.hp) and tonumber(h.hp) < 65 then return true end
    return false
end

-- Resolves speaker archetype flavor cleanly from existing record fields.
function Beats.ResolveArchetypeFlavor(rec)
    if type(rec) ~= "table" then return "companion" end
    local tc = string.lower(tostring(rec.tacticalClass or ""))
    local arch = string.lower(tostring(rec.archetypeID or ""))
    local role = string.lower(tostring(
        (rec.affiliation and (rec.affiliation.role or rec.affiliation.communityRole))
        or rec.communityRole or rec.role or ""
    ))
    if tc == "hostile" or rec.isHostile == true or arch == "bandit" or arch == "raider" then
        return "hostile"
    end
    if role == "guard" or arch == "guard" or arch == "soldier" or arch == "police" or arch == "cop" then
        return "guard"
    end
    if role == "trader" or arch == "trader" or arch == "merchant" or rec.isTrader == true then
        return "trader"
    end
    local isCol = (PNC.Types and PNC.Types.IsColonist and PNC.Types.IsColonist(rec) == true)
        or tc == "colonist" or rec.recruited == true
        or (rec.ownerUsername ~= nil and tostring(rec.ownerUsername) ~= "")
        or (rec.ownerOnlineID ~= nil)
    if isCol then return "companion" end
    return "neutral"
end

local function resolveTeamKey(slayer, slayerKind)
    if slayerKind == "player" then
        local oid = slayer.getOnlineID and slayer:getOnlineID() or nil
        if oid ~= nil and tonumber(oid) and tonumber(oid) >= 0 then
            return "owner:" .. tostring(oid)
        end
        local uname = slayer.getUsername and slayer:getUsername() or nil
        return "owner:" .. tostring(uname or "local")
    end
    local perc = PNC.Perception
    if perc and type(perc.GetTeamKey) == "function" then
        local tk = perc.GetTeamKey(slayer)
        if tk and tostring(tk) ~= "" then return tostring(tk) end
    end
    return "actor:" .. tostring(slayer and slayer.id or "")
end

local function findNearbyAllies(teamKey, anchorX, anchorY, anchorZ, excludeId)
    local out = {}
    local sp = PNC.SpatialIndex
    local list = (sp and type(sp.QueryNPCs) == "function")
        and (sp.QueryNPCs(anchorX, anchorY, 14) or {})
        or nil
    local perc = PNC.Perception
    local function consider(rec)
        if not isLiveNPC(rec) then return end
        if excludeId ~= nil and tostring(rec.id) == tostring(excludeId) then return end
        if math.abs((tonumber(rec.z) or 0) - anchorZ) >= 1 then return end
        local dx = (tonumber(rec.x) or 0) - anchorX
        local dy = (tonumber(rec.y) or 0) - anchorY
        if (dx * dx + dy * dy) > ALLY_RADIUS_SQ then return end
        local rKey = perc and type(perc.GetTeamKey) == "function" and perc.GetTeamKey(rec) or nil
        if rKey == teamKey then
            out[#out + 1] = rec
        end
    end
    if list then
        for i = 1, #list do consider(list[i]) end
    elseif PNC.Registry and type(PNC.Registry.ForEach) == "function" then
        PNC.Registry.ForEach(consider)
    end
    return out
end

-- O(1) event hook called on every NPC or Player kill.
function Beats.ObserveCombatKill(slayer, victimKind, at, opts)
    if not slayer then return false end
    opts = type(opts) == "table" and opts or {}
    local now = nowMs(at)
    local isPlayer = (opts.isPlayer == true) or (type(slayer) ~= "table") or (slayer.id == nil and slayer.getUsername ~= nil)
    local slayerKind = isPlayer and "player" or "npc"
    if not isPlayer and not isLiveNPC(slayer) then return false end

    local teamKey = opts.teamKey or resolveTeamKey(slayer, slayerKind)
    local sx = isPlayer and (slayer.getX and slayer:getX() or 0) or (tonumber(slayer.x) or 0)
    local sy = isPlayer and (slayer.getY and slayer:getY() or 0) or (tonumber(slayer.y) or 0)
    local sz = isPlayer and (slayer.getZ and slayer:getZ() or 0) or (tonumber(slayer.z) or 0)

    local s = pendingSkirmishes[teamKey]
    if not s then
        s = {
            teamKey = teamKey,
            startedAt = now,
            killCount = 0,
            hasHumanKill = false,
            anyDamaged = false,
            injuredName = nil,
            defers = 0,
        }
        lruPut(pendingSkirmishes, pendingOrder, teamKey, s)
    end
    s.killCount = s.killCount + 1
    if tostring(victimKind or "") == "hostile_human" or tostring(victimKind or "") == "bandit" then
        s.hasHumanKill = true
    end
    s.slayerKind = slayerKind
    s.slayerId = isPlayer and playerEntityKey(slayer) or tostring(slayer.id)
    s.slayerName = isPlayer and playerDisplayName(slayer) or tostring(slayer.name or slayer.fullName or "friend")
    s.slayerRef = slayer
    s.x, s.y, s.z = sx, sy, sz
    s.lastKillAt = now
    s.resolveAt = now + SETTLE_MS
    s.defers = 0
    if not isPlayer and wasDamagedDuringSkirmish(slayer, s.startedAt) then
        s.anyDamaged = true
        s.injuredName = s.slayerName
    end
    if nextResolveAt == 0 or s.resolveAt < nextResolveAt then
        nextResolveAt = s.resolveAt
    end
    return true
end

local function classifyIntensity(skirmish)
    if skirmish.anyDamaged == true then return "wounded_close_call" end
    if skirmish.hasHumanKill == true then return "hostile_human" end
    if (tonumber(skirmish.killCount) or 0) >= 4 then return "horde" end
    if (tonumber(skirmish.killCount) or 0) >= 2 then return "couple" end
    return "straggler"
end

local function resolveSoloRole(flavor, intensity)
    if flavor == "guard" or flavor == "trader" or flavor == "hostile" or flavor == "neutral" then
        if intensity == "wounded_close_call" then
            return "solo_" .. flavor .. "_wounded"
        elseif intensity == "horde" or intensity == "hostile_human" then
            return "solo_" .. flavor .. "_heavy"
        end
        return "solo_" .. flavor
    end
    return "solo_" .. intensity
end

local function resolveAllyRole(flavor, intensity)
    if flavor == "guard" then return "ally_guard_" .. (intensity == "wounded_close_call" and "wounded" or "clear") end
    if flavor == "trader" then return "ally_trader_" .. (intensity == "wounded_close_call" and "wounded" or "relief") end
    if flavor == "hostile" then return "ally_hostile_bravado" end
    if flavor == "neutral" then return "ally_neutral_" .. (intensity == "wounded_close_call" and "wounded" or "relief") end
    if intensity == "wounded_close_call" then return "ally_wounded_relief" end
    if intensity == "hostile_human" then return "ally_applaud_human" end
    if intensity == "horde" then return "ally_applaud_horde" end
    if intensity == "couple" then return "ally_applaud_couple" end
    return "ally_applaud_straggler"
end

local function resolveSlayerReplyRole(flavor, intensity)
    if flavor == "hostile" then return "slayer_reply_hostile" end
    if flavor == "guard" then return "slayer_reply_guard" end
    if intensity == "wounded_close_call" then return "slayer_reply_wounded" end
    if intensity == "horde" or intensity == "hostile_human" then return "slayer_reply_heavy" end
    return "slayer_reply"
end

local function deliverLine(speaker, addressee, role, act, tokens, now, delayMs, threadID, priority)
    local Transport = PNC.Semantics and PNC.Semantics.SpeechTransport or nil
    if not Transport or type(Transport.ResolveLine) ~= "function" or type(Transport.Deliver) ~= "function" then
        return false
    end
    local ref = threadID .. ":" .. tostring(speaker.id) .. ":" .. tostring(role)
    local ctx = {
        beatRole = role,
        finalKillRole = role,
        topic = "post_combat_relief",
        inCombat = false,
    }
    local text, res = Transport.ResolveLine(speaker, {
        eventType = "post_combat_final_kill",
        eventID = ref,
        act = act or "REACT",
        topic = "post_combat_relief",
        poolID = "semantic.combat.final_kill",
        role = role,
        tokens = tokens,
        context = ctx,
        inCombat = false,
    })
    if not text then return false end
    local sent = Transport.Deliver(speaker, now + (tonumber(delayMs) or 0), {
        eventType = "post_combat_final_kill",
        speechEventID = res and res.realizationID or ("semantic.combat.final_kill." .. role),
        act = act or "REACT",
        domain = "combat",
        topic = "post_combat_relief",
        channel = "social",
        family = "post_combat_final_kill",
        priority = tonumber(priority) or 58,
        priorityHoldMs = 1200,
        cooldownMs = 1500,
        familyCooldownMs = 1500,
        ttlMs = 8000,
        clientCooldowns = { familyMs = 1200, speakerMs = 1500, ambientMs = 400, mergeWindowMs = 0 },
        responsePlanID = res and res.responsePlanID or nil,
        realizationID = res and res.realizationID or nil,
        poolID = res and res.poolID or "semantic.combat.final_kill",
        lightweightBark = true,
        observerOnly = true,
        eventRef = ref,
        threadID = threadID,
        streamKey = "finalkill:" .. tostring(speaker.id),
        text = text,
        presentationClass = res and res.presentationClass or "BARK",
        context = ctx,
        addressee = addressee,
    })
    return (tonumber(sent) or 0) > 0
end

local function applyApplauseRelationship(ally, skirmish, intensity, now)
    local relSvc = PNC.Relationships or PNC.RelationshipService
    if not relSvc or type(relSvc.ApplyConversationEffect) ~= "function" then return end
    local targetKey = skirmish.slayerKind == "player"
        and skirmish.slayerId
        or ("npc:" .. tostring(skirmish.slayerId))
    local heavy = (intensity == "wounded_close_call" or intensity == "horde" or intensity == "hostile_human")
    local worldHours = PNC.Core and type(PNC.Core.NowWorldAgeHours) == "function"
        and PNC.Core.NowWorldAgeHours() or 0
    pcall(relSvc.ApplyConversationEffect, tostring(ally.id), targetKey, {
        approval = heavy and 2 or 1,
        respect = heavy and 2 or 1,
        familiarity = 1,
        memoryType = "skirmish_survived_together",
        interactionType = "skirmish_survived_together",
        tags = { combat = true, relief = true },
    }, {
        worldAgeHours = worldHours,
        sourceSystem = "final_kill_beat",
        eventID = "final_kill:" .. tostring(ally.id) .. ":" .. tostring(math.floor(now)),
    })
end

local function resolveSkirmish(skirmish, now)
    local slayer = nil
    if skirmish.slayerKind == "npc" then
        local reg = PNC.Registry
        slayer = reg and type(reg.Get) == "function" and reg.Get(skirmish.slayerId) or skirmish.slayerRef
        if not isLiveNPC(slayer) then return true end
        if isInActiveFight(slayer, now) then return false end
        if wasDamagedDuringSkirmish(slayer, skirmish.startedAt) then
            skirmish.anyDamaged = true
            skirmish.injuredName = skirmish.slayerName
        end
    end

    local allies = findNearbyAllies(
        skirmish.teamKey,
        skirmish.x,
        skirmish.y,
        skirmish.z,
        skirmish.slayerKind == "npc" and skirmish.slayerId or nil
    )
    for i = 1, #allies do
        if isInActiveFight(allies[i], now) then
            return false -- squad still fighting; defer
        end
        if wasDamagedDuringSkirmish(allies[i], skirmish.startedAt) then
            skirmish.anyDamaged = true
            if not skirmish.injuredName then
                skirmish.injuredName = tostring(allies[i].name or allies[i].fullName or "one of us")
            end
        end
    end

    -- Team cooldown check
    if now < (tonumber(teamCooldowns[skirmish.teamKey]) or 0) then
        return true
    end

    local intensity = classifyIntensity(skirmish)
    local anchorSpeaker = (skirmish.slayerKind == "npc" and #allies == 0) and slayer or allies[1]
    if not anchorSpeaker then return true end

    local isHeavy = (intensity == "wounded_close_call" or intensity == "horde" or intensity == "hostile_human")
    local Dir = PNC.Semantics and PNC.Semantics.ConversationDirector or nil
    if Dir and type(Dir.EvaluateCandidate) == "function" and not isHeavy then
        local ok = Dir.EvaluateCandidate({
            speaker = anchorSpeaker,
            scopeKey = skirmish.teamKey,
            topic = "post_combat_relief",
            tier = intensity == "couple" and 2 or 1,
            urgency = intensity == "couple" and 54 or 38,
            salience = intensity == "couple" and 60 or 44,
            saturationWindowMs = 25000,
            silenceThreshold = intensity == "couple" and 44 or 54,
            markOnAdmit = false,
            now = now,
        })
        if not ok then return true end
    end

    local tokens = {
        ["addressee.name"] = skirmish.slayerName or "friend",
        ["slot.kill.count"] = tostring(skirmish.killCount or 1),
        ["slot.injured.name"] = tostring(skirmish.injuredName or "someone"),
    }
    local threadID = "finalkill:" .. tostring(skirmish.teamKey) .. ":" .. tostring(math.floor(now))
    local spoke = false

    if #allies == 0 and skirmish.slayerKind == "npc" and slayer then
        -- Solo NPC slayer expression
        local flavor = Beats.ResolveArchetypeFlavor(slayer)
        local role = resolveSoloRole(flavor, intensity)
        spoke = deliverLine(slayer, nil, role, "REACT", tokens, now, 0, threadID, isHeavy and 64 or 52)
    else
        -- Squad / Group reaction (actor-agnostic: works for NPC OR Player slayer!)
        local ally1 = allies[1]
        local flavor1 = Beats.ResolveArchetypeFlavor(ally1)
        local allyRole = resolveAllyRole(flavor1, intensity)
        spoke = deliverLine(
            ally1,
            skirmish.slayerKind == "npc" and slayer or nil,
            allyRole,
            "PRAISE",
            tokens,
            now,
            0,
            threadID,
            isHeavy and 66 or 56
        )
        if spoke then
            applyApplauseRelationship(ally1, skirmish, intensity, now)
            if skirmish.slayerKind == "npc" and slayer then
                local sFlavor = Beats.ResolveArchetypeFlavor(slayer)
                local sRole = resolveSlayerReplyRole(sFlavor, intensity)
                local replyTokens = {
                    ["addressee.name"] = tostring(ally1.name or ally1.fullName or "friend"),
                    ["slot.kill.count"] = tokens["slot.kill.count"],
                    ["slot.injured.name"] = tokens["slot.injured.name"],
                }
                deliverLine(slayer, ally1, sRole, "ACK", replyTokens, now, 1300, threadID, 58)
            end
            local chimeAlly = (skirmish.slayerKind == "player") and allies[2] or (isHeavy and allies[2] or nil)
            if chimeAlly then
                local chimeRole = (intensity == "wounded_close_call") and "ally_relief_wounded_chime" or "ally_relief_chime"
                deliverLine(chimeAlly, nil, chimeRole, "REACT", tokens, now, skirmish.slayerKind == "player" and 1300 or 2600, threadID, 54)
            end
        end
    end

    if spoke then
        lruPut(teamCooldowns, teamCooldownOrder, skirmish.teamKey, now + TEAM_COOLDOWN_MS)
        if Dir then
            if type(Dir.MarkSpoken) == "function" then
                Dir.MarkSpoken(skirmish.teamKey, "post_combat_relief", isHeavy and 2 or 1, now, anchorSpeaker.id)
            end
            if type(Dir.RecordStoryMoment) == "function" then
                Dir.RecordStoryMoment(skirmish.teamKey, {
                    kind = "skirmish_survived",
                    topic = "post_combat_relief",
                    actorId = anchorSpeaker.id,
                    salience = isHeavy and 74 or 52,
                    meta = { intensity = intensity, killCount = skirmish.killCount },
                }, now)
            end
        end
    end
    return true
end

-- Called from Beats.Tick: single integer compare when idle (zero overhead).
function Beats.TickFinalKillResolutions(at)
    if nextResolveAt == 0 then return 0 end
    local now = nowMs(at)
    if now < nextResolveAt then return 0 end

    local resolved = 0
    for i = #pendingOrder, 1, -1 do
        local key = pendingOrder[i]
        local s = pendingSkirmishes[key]
        if not s then
            table.remove(pendingOrder, i)
        elseif now >= (tonumber(s.resolveAt) or 0) then
            local done = resolveSkirmish(s, now)
            if done or (s.defers or 0) >= MAX_DEFERS then
                pendingSkirmishes[key] = nil
                removeOrder(pendingOrder, key)
                resolved = resolved + 1
            else
                s.defers = (s.defers or 0) + 1
                s.resolveAt = now + RETRY_DEFER_MS
            end
        end
    end
    recomputeNextResolveAt()
    return resolved
end

function Beats.ResetFinalKillRuntime()
    pendingSkirmishes = {}
    pendingOrder = {}
    teamCooldowns, teamCooldownOrder = {}, {}
    nextResolveAt = 0
end

return Beats
