if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_Context"

local Service = PNC.Semantics.CombatTargetCallouts or {}
PNC.Semantics.CombatTargetCallouts = Service

local cachedSR, cachedBanter

local function finite(v)
    v = tonumber(v)
    if v == nil or v ~= v or v == math.huge or v == -math.huge then return nil end
    return v
end
Service.Finite = finite

local function playerKey(p)
    if not p then return nil end
    if type(p.getOnlineID) == "function" then
        local v = p:getOnlineID()
        if v ~= nil then return tostring(v) end
    end
    if type(p.getUsername) == "function" then
        local v = p:getUsername()
        if v and v ~= "" then return tostring(v) end
    end
    return nil
end

local function coord(obj, method)
    return (obj and type(obj[method]) == "function") and finite(obj[method](obj)) or nil
end

local function canHear(player, record)
    local px, py, pz = coord(player, "getX"), coord(player, "getY"), coord(player, "getZ")
    local nx, ny, nz = finite(record and record.x), finite(record and record.y), finite(record and record.z)
    if not px or not py or not pz or not nx or not ny or not nz or math.abs(pz - nz) >= 1 then return false end
    local rad = tonumber(Service.WITNESS_RADIUS) or 12
    local dx, dy = px - nx, py - ny
    if (dx * dx + dy * dy) > rad * rad then return false end
    local perc = PNC.Perception
    return perc and type(perc.CanSeeWorldObject) == "function" and perc.CanSeeWorldObject(record, player) == true or false
end

function Service.FormatTokens(text, tokens)
    local out = tostring(text or "")
    if type(tokens) ~= "table" then return out end
    return (string.gsub(out, "{([%w_%.]+)}", function(key)
        local val = tokens[key]
        if val ~= nil then return tostring(val) end
    end))
end

function Service.ResolveSemanticLine(record, eventType, act, threatClass, eventRef, profile, tokens, extraContext)
    local reactions = PNC.ConvoEngine and PNC.ConvoEngine.SocialReactions
    if type(reactions) ~= "table" or type(reactions.Resolve) ~= "function" then return nil, nil end
    local resolved = reactions.Resolve({
        eventType = eventType,
        eventID = eventRef,
        npcID = tostring(record.id),
        act = act,
        topic = "combat",
        context = {
            semanticThreatClass = threatClass,
            combatReactionStyle = Service.ResolveAllyWarnTone(record, profile),
            combatReactionRole = type(extraContext) == "table" and extraContext.replyRole or nil,
            inCombat = true,
        },
    })
    if type(resolved) ~= "table" then return nil, nil end
    local raw = resolved.fallback or resolved.text
    cachedSR = cachedSR or (PNC.ConvoEngine and PNC.ConvoEngine.SpeechRealization)
    if not cachedSR then
        local ok, mod = pcall(require, "PNC/ConvoEngine/SpeechRealization")
        if ok and type(mod) == "table" then cachedSR = mod end
    end
    if cachedSR and type(cachedSR.Apply) == "function" then
        local applied = cachedSR.Apply({
            selectionID = resolved.realizationID, templateID = resolved.templateID,
            fallback = raw, plan = resolved.responsePlan,
        }, { npcID = tostring(record.id), phraseSalt = tostring(eventRef or "") .. ":" .. tostring(record.id) })
        if type(applied) == "table" and type(applied.fallback) == "string" and applied.fallback ~= "" then
            raw = applied.fallback
        end
    end
    if type(raw) ~= "string" or raw == "" then return nil, nil end
    return (type(Service.FormatTokens) == "function" and Service.FormatTokens(raw, tokens) or raw), resolved
end

function Service.DeliverBark(record, now, opts)
    local core, network = PNC.Core, PNC.Network
    cachedBanter = cachedBanter or (PNC.ConvoEngine and PNC.ConvoEngine.CombatBanterArbiter)
        or require "PNC/ConvoEngine/CombatBanterArbiter"
    if not core or type(core.ForEachPlayer) ~= "function"
        or not network or type(network.SendConversationRelationshipForNPC) ~= "function"
    then return 0 end
    local sent, npcId, ref = 0, tostring(record.id), opts.eventRef
    local presClass, fam = opts.presentationClass or "BARK", opts.family or Service.FAMILY
    local pri = opts.priority or 75
    core.ForEachPlayer(function(player)
        if not canHear(player, record) then return end
        local audience = playerKey(player)
        if not audience then return end
        if cachedBanter and type(cachedBanter.Reserve) == "function" then
            if cachedBanter.Reserve({
                streamKey = opts.streamKey or ("combat-target:" .. npcId),
                now = now, cooldownMs = opts.cooldownMs or Service.COOLDOWN_MS or 5000,
                maxSpeakers = opts.maxSpeakers or 1, speakerID = npcId, audienceKey = audience,
                family = fam, familyCooldownMs = opts.familyCooldownMs or Service.COOLDOWN_MS or 5000, priority = pri,
            }) ~= true then return end
        end
        local ctx = opts.context or { eventType = opts.eventType, eventRef = ref, presentationClass = presClass, transient = true }
        local delivered = network.SendConversationRelationshipForNPC(player, npcId, opts.eventType, {
            source = opts.eventType, eventID = ref, npcID = npcId, meaningful = false,
            transientInteraction = true, interactionTTLHours = 10 / 3600,
            ambientFlavor = {
                eventID = ref, eventRef = ref, speechEventID = opts.speechEventID, text = opts.text,
                semanticOwned = true, eventType = opts.eventType, act = opts.act or "WARN", topic = "combat",
                factRefs = {}, offerIDs = {}, family = fam, priority = pri, weight = 0.25,
                llmEligible = false, memoryEligible = false, npcID = npcId, mergeKey = ref .. ":" .. npcId,
                ttlMs = 6000, holdMs = 1500, context = ctx, presentationClass = presClass,
                source = { kind = "semantic_speech", channel = "combat", eventType = opts.eventType },
            },
        }) == true
        if cachedBanter and type(cachedBanter.RecordPresentation) == "function" then
            cachedBanter.RecordPresentation({
                accepted = delivered, reason = delivered and "presentation_sent" or "presentation_transport_refused",
                at = now, speakerID = npcId, audienceKey = audience, family = fam, eventRef = ref,
                presentationClass = presClass, tacticalSpatial = opts.tacticalSpatial,
                tacticalPresentation = opts.tacticalPresentation,
            })
        end
        if delivered then sent = sent + 1 end
    end)
    return sent
end

function Service.SendReplyBark(rec, now, ev, act, eventRef, text, resolved, toks)
    local presClass = resolved and resolved.presentationClass or "BARK"
    return Service.DeliverBark(rec, now, {
        eventType = ev, speechEventID = resolved and resolved.realizationID or ("semantic." .. ev),
        act = act, family = "combat_ally_warn_reply", eventRef = eventRef, text = text,
        priority = 75, cooldownMs = 3500, familyCooldownMs = 3500, maxSpeakers = 1,
        streamKey = "ally-warn-reply:" .. tostring(rec.id), presentationClass = presClass,
        context = {
            eventType = ev, eventRef = eventRef, presentationClass = presClass, transient = true,
            targetLabel = toks and toks["target.name"] or nil,
            targetCount = toks and tonumber(toks["target.count"]) or nil,
            locationLabel = toks and toks["scene.location"] or nil,
            callerName = toks and toks["addressee.name"] or nil,
        },
    })
end

return Service
