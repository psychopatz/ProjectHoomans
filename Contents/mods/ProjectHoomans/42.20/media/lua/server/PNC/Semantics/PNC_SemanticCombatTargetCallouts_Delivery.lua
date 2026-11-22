if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_Context"

local S = PNC.Semantics.CombatTargetCallouts or {}
PNC.Semantics.CombatTargetCallouts = S
local sr, banter

local function finite(v)
    v = tonumber(v)
    if v == nil or v ~= v or v == math.huge or v == -math.huge then return nil end
    return v
end
S.Finite = finite

local function playerKey(p)
    if not p then return nil end
    if type(p.getOnlineID) == "function" then local v = p:getOnlineID(); if v ~= nil then return tostring(v) end end
    if type(p.getUsername) == "function" then local v = p:getUsername(); if v and v ~= "" then return tostring(v) end end
    return nil
end

local function coord(o, m) return (o and type(o[m]) == "function") and finite(o[m](o)) or nil end

local function canHear(p, rec)
    local px, py, pz = coord(p, "getX"), coord(p, "getY"), coord(p, "getZ")
    local nx, ny, nz = finite(rec and rec.x), finite(rec and rec.y), finite(rec and rec.z)
    if not px or not py or not pz or not nx or not ny or not nz or math.abs(pz - nz) >= 1 then return false end
    local rad, dx, dy = tonumber(S.WITNESS_RADIUS) or 12, px - nx, py - ny
    if (dx * dx + dy * dy) > rad * rad then return false end
    local perc = PNC.Perception
    return perc and type(perc.CanSeeWorldObject) == "function" and perc.CanSeeWorldObject(rec, p) == true or false
end

function S.FormatTokens(text, tokens)
    local out = tostring(text or "")
    if type(tokens) ~= "table" then return out end
    return (string.gsub(out, "{([%w_%.]+)}", function(k) if tokens[k] ~= nil then return tostring(tokens[k]) end end))
end

function S.ResolveSemanticLine(rec, evType, act, tClass, ref, profile, tokens, extra)
    local react = PNC.ConvoEngine and PNC.ConvoEngine.SocialReactions
    if type(react) ~= "table" or type(react.Resolve) ~= "function" then return nil, nil end
    local res = react.Resolve({
        eventType = evType, eventID = ref, npcID = tostring(rec.id), act = act, topic = "combat",
        context = {
            semanticThreatClass = tClass, combatReactionStyle = S.ResolveAllyWarnTone(rec, profile),
            combatReactionRole = type(extra) == "table" and extra.replyRole or nil, inCombat = true,
        },
    })
    if type(res) ~= "table" then return nil, nil end
    local raw = res.fallback or res.text
    sr = sr or (PNC.ConvoEngine and PNC.ConvoEngine.SpeechRealization)
    if not sr then local ok, m = pcall(require, "PNC/ConvoEngine/SpeechRealization"); if ok and type(m) == "table" then sr = m end end
    if sr and type(sr.Apply) == "function" then
        local ap = sr.Apply(
            { selectionID = res.realizationID, templateID = res.templateID, fallback = raw },
            { npcID = tostring(rec.id), phraseSalt = tostring(ref or "") .. ":" .. tostring(rec.id) }
        )
        if type(ap) == "table" and type(ap.fallback) == "string" and ap.fallback ~= "" then raw = ap.fallback end
    end
    if type(raw) ~= "string" or raw == "" then return nil, nil end
    return (S.FormatTokens and S.FormatTokens(raw, tokens) or raw), res
end

local function cds(f, s, a) return { familyMs = f, speakerMs = s, ambientMs = a, mergeWindowMs = 0 } end

function S.DeliverBark(rec, now, opts)
    local core, net = PNC.Core, PNC.Network
    banter = banter or (PNC.ConvoEngine and PNC.ConvoEngine.CombatBanterArbiter) or require "PNC/ConvoEngine/CombatBanterArbiter"
    if not (core and core.ForEachPlayer and net and net.SendConversationRelationshipForNPC) then return 0 end
    local sent, npcId, ref = 0, tostring(rec.id), opts.eventRef
    local pres, fam = opts.presentationClass or "BARK", opts.family or S.FAMILY
    local pri, cd = opts.priority or 62, opts.cooldownMs or S.COOLDOWN_MS or 5000
    local famCd, ev, tid = opts.familyCooldownMs or cd, opts.eventType, opts.threadID or ref
    local cCds = opts.clientCooldowns or cds(2500, 2500, 700)
    core.ForEachPlayer(function(p)
        if not canHear(p, rec) then return end
        local aud = playerKey(p)
        if not aud then return end
        if banter and banter.Reserve and banter.Reserve({
            streamKey = opts.streamKey or ("combat-target:" .. npcId), now = now, cooldownMs = cd,
            maxSpeakers = opts.maxSpeakers or 1, speakerID = npcId, audienceKey = aud, family = fam,
            familyCooldownMs = famCd, priorityHoldMs = opts.priorityHoldMs or 700, priority = pri,
        }) ~= true then return end
        local ctx = opts.context or { eventType = ev, eventRef = ref, threadID = tid, presentationClass = pres, transient = true }
        if ctx.threadID == nil then ctx.threadID = tid end
        local ok = net.SendConversationRelationshipForNPC(p, npcId, ev, {
            lightweightBark = true, source = ev, eventID = ref, npcID = npcId, meaningful = false,
            transientInteraction = true, interactionTTLHours = 10 / 3600,
            ambientFlavor = {
                observerOnly = true, recipientKind = "npc", eventID = ref, eventRef = ref, threadID = tid,
                speechEventID = opts.speechEventID, text = opts.text, semanticOwned = true, eventType = ev,
                act = opts.act or "WARN", topic = "combat", factRefs = {}, offerIDs = {}, family = fam,
                priority = pri, weight = 0.25, llmEligible = false, memoryEligible = false, npcID = npcId,
                mergeKey = ref .. ":" .. npcId, ttlMs = opts.ttlMs or 9000, holdMs = opts.holdMs,
                interrupt = opts.interrupt == true, cooldowns = cCds,
                context = ctx, presentationClass = pres, source = { kind = "semantic_speech", channel = "combat", eventType = ev },
            },
        }) == true
        if banter and banter.RecordPresentation then
            banter.RecordPresentation({
                accepted = ok, reason = ok and "presentation_sent" or "presentation_transport_refused",
                at = now, speakerID = npcId, audienceKey = aud, family = fam, eventRef = ref,
                presentationClass = pres, tacticalSpatial = opts.tacticalSpatial, tacticalPresentation = opts.tacticalPresentation,
            })
        end
        if ok then sent = sent + 1 end
    end)
    return sent
end

function S.SendReplyBark(rec, now, ev, act, ref, text, res, toks, opts, threadId)
    opts = type(opts) == "table" and opts or nil
    local pres, tid = res and res.presentationClass or "BARK", threadId or (opts and opts.threadID) or ref
    return S.DeliverBark(rec, now, {
        eventType = ev, speechEventID = res and res.realizationID or ("semantic." .. ev), act = act,
        family = (opts and opts.family) or "combat_ally_warn_reply", eventRef = ref, text = text, threadID = tid,
        priority = (opts and opts.priority) or 62, priorityHoldMs = (opts and opts.priorityHoldMs) or 700,
        holdMs = opts and opts.holdMs or nil, ttlMs = (opts and opts.ttlMs) or 9000,
        cooldownMs = (opts and opts.cooldownMs) or 3500,
        familyCooldownMs = (opts and opts.familyCooldownMs) or (opts and opts.cooldownMs) or 3500,
        clientCooldowns = (opts and opts.clientCooldowns) or cds(1500, 2000, 400),
        maxSpeakers = 1, streamKey = (opts and opts.streamKey) or ("ally-warn-reply:" .. tostring(rec.id)),
        presentationClass = pres,
        context = {
            eventType = ev, eventRef = ref, threadID = tid, presentationClass = pres, transient = true,
            targetLabel = toks and toks["target.name"] or nil, targetCount = toks and tonumber(toks["target.count"]) or nil,
            locationLabel = toks and toks["scene.location"] or nil, callerName = toks and toks["addressee.name"] or nil,
        },
    })
end

return S
