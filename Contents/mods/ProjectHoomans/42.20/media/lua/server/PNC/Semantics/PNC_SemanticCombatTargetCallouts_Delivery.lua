if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_Context"

local S = PNC.Semantics.CombatTargetCallouts or {}
PNC.Semantics.CombatTargetCallouts = S
local cachedSR, cachedBanter

local function finite(v)
    v = tonumber(v)
    if v == nil or v ~= v or v == math.huge or v == -math.huge then return nil end
    return v
end
S.Finite = finite

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

local function coord(o, m) return (o and type(o[m]) == "function") and finite(o[m](o)) or nil end

local function canHear(player, rec)
    local px, py, pz = coord(player, "getX"), coord(player, "getY"), coord(player, "getZ")
    local nx, ny, nz = finite(rec and rec.x), finite(rec and rec.y), finite(rec and rec.z)
    if not px or not py or not pz or not nx or not ny or not nz or math.abs(pz - nz) >= 1 then return false end
    local rad, dx, dy = tonumber(S.WITNESS_RADIUS) or 12, px - nx, py - ny
    if (dx * dx + dy * dy) > rad * rad then return false end
    local perc = PNC.Perception
    return perc and type(perc.CanSeeWorldObject) == "function" and perc.CanSeeWorldObject(rec, player) == true or false
end

function S.FormatTokens(text, tokens)
    local out = tostring(text or "")
    if type(tokens) ~= "table" then return out end
    return (string.gsub(out, "{([%w_%.]+)}", function(k)
        local val = tokens[k]
        if val ~= nil then return tostring(val) end
    end))
end

function S.ResolveSemanticLine(rec, evType, act, tClass, ref, profile, tokens, extra)
    local reactions = PNC.ConvoEngine and PNC.ConvoEngine.SocialReactions
    if type(reactions) ~= "table" or type(reactions.Resolve) ~= "function" then return nil, nil end
    local resolved = reactions.Resolve({
        eventType = evType, eventID = ref, npcID = tostring(rec.id), act = act, topic = "combat",
        context = {
            semanticThreatClass = tClass,
            combatReactionStyle = S.ResolveAllyWarnTone(rec, profile),
            combatReactionRole = type(extra) == "table" and extra.replyRole or nil,
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
        local ap = cachedSR.Apply({
            selectionID = resolved.realizationID, templateID = resolved.templateID,
            fallback = raw, plan = resolved.responsePlan,
        }, { npcID = tostring(rec.id), phraseSalt = tostring(ref or "") .. ":" .. tostring(rec.id) })
        if type(ap) == "table" and type(ap.fallback) == "string" and ap.fallback ~= "" then raw = ap.fallback end
    end
    if type(raw) ~= "string" or raw == "" then return nil, nil end
    return (type(S.FormatTokens) == "function" and S.FormatTokens(raw, tokens) or raw), resolved
end

function S.DeliverBark(rec, now, opts)
    local core, net = PNC.Core, PNC.Network
    cachedBanter = cachedBanter or (PNC.ConvoEngine and PNC.ConvoEngine.CombatBanterArbiter)
        or require "PNC/ConvoEngine/CombatBanterArbiter"
    if not core or type(core.ForEachPlayer) ~= "function"
        or not net or type(net.SendConversationRelationshipForNPC) ~= "function"
    then return 0 end
    local sent, npcId, ref = 0, tostring(rec.id), opts.eventRef
    local pres, fam = opts.presentationClass or "BARK", opts.family or S.FAMILY
    local pri, cd = opts.priority or 75, opts.cooldownMs or S.COOLDOWN_MS or 5000
    local famCd, evType = opts.familyCooldownMs or cd, opts.eventType
    core.ForEachPlayer(function(player)
        if not canHear(player, rec) then return end
        local aud = playerKey(player)
        if not aud then return end
        if cachedBanter and type(cachedBanter.Reserve) == "function" then
            if cachedBanter.Reserve({
                streamKey = opts.streamKey or ("combat-target:" .. npcId),
                now = now, cooldownMs = cd, maxSpeakers = opts.maxSpeakers or 1,
                speakerID = npcId, audienceKey = aud, family = fam, familyCooldownMs = famCd, priority = pri,
            }) ~= true then return end
        end
        local ctx = opts.context or { eventType = evType, eventRef = ref, presentationClass = pres, transient = true }
        local delivered = net.SendConversationRelationshipForNPC(player, npcId, evType, {
            lightweightBark = true, source = evType, eventID = ref, npcID = npcId, meaningful = false,
            transientInteraction = true, interactionTTLHours = 10 / 3600,
            ambientFlavor = {
                observerOnly = true, recipientKind = "npc",
                eventID = ref, eventRef = ref, speechEventID = opts.speechEventID, text = opts.text,
                semanticOwned = true, eventType = evType, act = opts.act or "WARN", topic = "combat",
                factRefs = {}, offerIDs = {}, family = fam, priority = pri, weight = 0.25,
                llmEligible = false, memoryEligible = false, npcID = npcId, mergeKey = ref .. ":" .. npcId,
                ttlMs = 6000, holdMs = 1500, context = ctx, presentationClass = pres,
                source = { kind = "semantic_speech", channel = "combat", eventType = evType },
            },
        }) == true
        if cachedBanter and type(cachedBanter.RecordPresentation) == "function" then
            cachedBanter.RecordPresentation({
                accepted = delivered, reason = delivered and "presentation_sent" or "presentation_transport_refused",
                at = now, speakerID = npcId, audienceKey = aud, family = fam, eventRef = ref,
                presentationClass = pres, tacticalSpatial = opts.tacticalSpatial,
                tacticalPresentation = opts.tacticalPresentation,
            })
        end
        if delivered then sent = sent + 1 end
    end)
    return sent
end

function S.SendReplyBark(rec, now, ev, act, ref, text, res, toks, opts)
    opts = type(opts) == "table" and opts or nil
    local pres = res and res.presentationClass or "BARK"
    return S.DeliverBark(rec, now, {
        eventType = ev, speechEventID = res and res.realizationID or ("semantic." .. ev),
        act = act, family = (opts and opts.family) or "combat_ally_warn_reply", eventRef = ref, text = text,
        priority = (opts and opts.priority) or 75, cooldownMs = (opts and opts.cooldownMs) or 3500,
        familyCooldownMs = (opts and opts.familyCooldownMs) or (opts and opts.cooldownMs) or 3500,
        maxSpeakers = 1, streamKey = (opts and opts.streamKey) or ("ally-warn-reply:" .. tostring(rec.id)),
        presentationClass = pres,
        context = {
            eventType = ev, eventRef = ref, presentationClass = pres, transient = true,
            targetLabel = toks and toks["target.name"] or nil,
            targetCount = toks and tonumber(toks["target.count"]) or nil,
            locationLabel = toks and toks["scene.location"] or nil,
            callerName = toks and toks["addressee.name"] or nil,
        },
    })
end

return S
