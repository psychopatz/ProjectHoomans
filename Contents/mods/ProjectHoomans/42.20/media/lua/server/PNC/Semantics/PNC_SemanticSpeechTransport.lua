-- Domain-neutral semantic speech realization and presentation transport.
-- Owns generic line realization and delivery into SocialFlavorClient without
-- stamping combat topics/channels or invoking CombatBanterArbiter on non-combat beats.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Transport = PNC.Semantics.SpeechTransport or {}
PNC.Semantics.SpeechTransport = Transport

Transport.VERSION = 1

local TokenFormatter = PNC.ConvoEngine.TokenFormatter
    or require "PNC/ConvoEngine/TokenFormatter"

local MAX_COOLDOWN_KEYS = 256
local sr = nil
local streamCooldowns = {}
local streamOrder = {}
local familyCooldowns = {}
local familyOrder = {}

local function finite(v)
    v = tonumber(v)
    if v == nil or v ~= v or v == math.huge or v == -math.huge then return nil end
    return v
end
Transport.Finite = finite

local function cleanText(v)
    if v == nil then return nil end
    local s = tostring(v)
    s = string.gsub(s, "^%s+", "")
    s = string.gsub(s, "%s+$", "")
    return s ~= "" and s or nil
end

function Transport.FirstTokenName(raw)
    return TokenFormatter.FirstTokenName(raw)
end

function Transport.FormatTokens(text, tokens)
    return TokenFormatter.Format(text, tokens)
end

function Transport.DefaultCooldowns(familyMs, speakerMs, ambientMs)
    return {
        familyMs = familyMs,
        speakerMs = speakerMs,
        ambientMs = ambientMs,
        mergeWindowMs = 0,
    }
end

local function copyShallow(source)
    local out = {}
    if type(source) ~= "table" then return out end
    for k, v in pairs(source) do
        out[k] = v
    end
    return out
end

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

local function coord(o, m)
    return (o and type(o[m]) == "function") and finite(o[m](o)) or nil
end

local function canHear(p, rec, radius)
    local px, py, pz = coord(p, "getX"), coord(p, "getY"), coord(p, "getZ")
    local nx, ny, nz = finite(rec and rec.x), finite(rec and rec.y), finite(rec and rec.z)
    if not px or not py or not pz or not nx or not ny or not nz or math.abs(pz - nz) >= 1 then
        return false
    end
    local rad, dx, dy = tonumber(radius) or 12, px - nx, py - ny
    if (dx * dx + dy * dy) > rad * rad then return false end
    local perc = PNC.Perception
    return perc and type(perc.CanSeeWorldObject) == "function"
        and perc.CanSeeWorldObject(rec, p) == true or false
end

local function setBoundedCooldown(map, order, key, untilAt)
    if map[key] == nil then
        while #order >= MAX_COOLDOWN_KEYS do
            local oldest = table.remove(order, 1)
            map[oldest] = nil
        end
        order[#order + 1] = key
    end
    map[key] = untilAt
end

local function reserveNeutralCooldown(streamKey, family, npcId, aud, now, cd, famCd)
    local sKey = aud .. "|" .. streamKey
    local fKey = aud .. "|" .. tostring(family) .. "|" .. npcId
    if cd > 0 and now < (tonumber(streamCooldowns[sKey]) or -math.huge) then
        return false
    end
    if famCd > 0 and now < (tonumber(familyCooldowns[fKey]) or -math.huge) then
        return false
    end
    if cd > 0 then setBoundedCooldown(streamCooldowns, streamOrder, sKey, now + cd) end
    if famCd > 0 then setBoundedCooldown(familyCooldowns, familyOrder, fKey, now + famCd) end
    return true
end

function Transport.ResolveLine(rec, opts)
    if type(rec) ~= "table" or rec.id == nil then return nil, nil end
    opts = type(opts) == "table" and opts or {}
    local react = PNC.ConvoEngine and PNC.ConvoEngine.SocialReactions
    if type(react) ~= "table" or type(react.Resolve) ~= "function" then return nil, nil end

    local evType = tostring(opts.eventType or "social_beat")
    local ref = opts.eventID or opts.eventRef or evType
    local act = tostring(opts.act or "REACT")
    local topic = cleanText(opts.topic or opts.domain) or evType
    local context = copyShallow(opts.context)
    local role = opts.role or opts.replyRole
    if role ~= nil then
        if context.beatRole == nil then context.beatRole = role end
        if context.combatReactionRole == nil then context.combatReactionRole = role end
    end
    if opts.inCombat ~= nil then
        context.inCombat = opts.inCombat == true
    end

    local res = react.Resolve({
        eventType = evType,
        eventID = ref,
        npcID = tostring(rec.id),
        act = act,
        topic = topic,
        poolID = opts.poolID,
        context = context,
    })
    if type(res) ~= "table" then return nil, nil end

    local raw = res.fallback or res.text
    sr = sr or (PNC.ConvoEngine and PNC.ConvoEngine.SpeechRealization)
    if sr and type(sr.Apply) == "function" then
        local ap = sr.Apply(
            { selectionID = res.realizationID, templateID = res.templateID, fallback = raw },
            { npcID = tostring(rec.id), phraseSalt = tostring(ref or "") .. ":" .. tostring(rec.id) }
        )
        if type(ap) == "table" and type(ap.fallback) == "string" and ap.fallback ~= "" then
            raw = ap.fallback
        end
    end
    if type(raw) ~= "string" or raw == "" then return nil, nil end
    local mergedTokens = copyShallow(opts.tokens)
    if mergedTokens["speaker.name"] == nil or cleanText(mergedTokens["speaker.name"]) == nil then
        mergedTokens["speaker.name"] = TokenFormatter.FirstTokenName(
            rec.name or rec.fullName or rec.displayName
        )
    end
    if mergedTokens["addressee.name"] == nil or cleanText(mergedTokens["addressee.name"]) == nil then
        local addr = type(opts.addressee) == "table" and opts.addressee or nil
        local addrAllowed = addr == nil or (addr.identityKnown ~= false and addr.isUnknown ~= true)
        local rawAddressee = (addrAllowed and addr and (addr.name or addr.fullName or addr.displayName))
            or opts.addresseeName
            or context.addresseeName
            or context.playerAddressName
            or (context.playerNameKnown ~= false and context.playerName)
            or (context.npcIdentityKnown ~= false and context.npcName)
            or context.targetName
        mergedTokens["addressee.name"] = TokenFormatter.FirstTokenName(rawAddressee)
    else
        mergedTokens["addressee.name"] = TokenFormatter.CleanName(mergedTokens["addressee.name"])
    end
    if mergedTokens["scene.location"] == nil then
        mergedTokens["scene.location"] = TokenFormatter.CleanLocation(
            opts.sceneLocation
            or opts.locationLabel
            or context.sceneLocation
            or context.locationLabel
            or context.locationName
            or context.zoneName
            or context.settlementName
            or context.roomName
            or rec.zoneName
            or rec.locationName
            or rec.settlementName
            or rec.roomName
        )
    elseif cleanText(mergedTokens["scene.location"]) == nil then
        mergedTokens["scene.location"] = nil
    end
    if mergedTokens["scene.clock"] == nil or cleanText(mergedTokens["scene.clock"]) == nil then
        mergedTokens["scene.clock"] = TokenFormatter.CleanName(
            opts.sceneClock or context.sceneClock or context.timeOfDay
        )
    end
    return Transport.FormatTokens(raw, mergedTokens), res
end

function Transport.Deliver(rec, now, opts)
    if type(rec) ~= "table" or rec.alive == false or rec.id == nil then return 0 end
    opts = type(opts) == "table" and opts or {}
    local core, net = PNC.Core, PNC.Network
    if not (core and core.ForEachPlayer and net and net.SendConversationRelationshipForNPC) then
        return 0
    end

    now = finite(now) or (type(core.Now) == "function" and finite(core.Now())) or 0
    local npcId = tostring(rec.id)
    local ref = cleanText(opts.eventRef or opts.eventID)
    if not ref then return 0 end

    local lane = (opts.lane == "scene") and "scene" or "beat"
    local ev = cleanText(opts.eventType) or (lane == "scene" and "semantic_scene" or "social_beat")
    local domain = cleanText(opts.domain or opts.topic) or (lane == "scene" and "scene" or "social")
    local topic = cleanText(opts.topic) or domain
    local channel = cleanText(opts.channel) or domain
    local pres = opts.presentationClass or "BARK"
    local fam = opts.family or (lane == "scene" and "semantic_scene" or "semantic_beat")
    local pri = tonumber(opts.priority) or (lane == "scene" and 80 or 40)
    local cd = math.max(0, tonumber(opts.cooldownMs) or 1500)
    local famCd = math.max(0, tonumber(opts.familyCooldownMs) or cd)
    local tid = (lane == "beat") and (cleanText(opts.threadID) or ref) or nil
    local sid = (lane == "scene") and (cleanText(opts.sceneID) or ref) or nil
    local convID = cleanText(opts.conversationID) or (lane == "scene" and sid or nil)
    local cCds = opts.clientCooldowns or Transport.DefaultCooldowns(2500, 2500, 700)
    local streamKey = cleanText(opts.streamKey) or (channel .. ":" .. npcId)
    local witnessRadius = tonumber(opts.witnessRadius) or 12
    local tts = opts.tts ~= false
    local act = opts.act or "REACT"
    local sent = 0

    core.ForEachPlayer(function(p)
        if type(opts.audienceFilter) == "function" then
            if opts.audienceFilter(p, rec) ~= true then return end
        elseif not canHear(p, rec, witnessRadius) then
            return
        end
        local aud = playerKey(p)
        if not aud then return end
        if type(opts.preDeliver) == "function" then
            if opts.preDeliver(rec, aud, now, opts) ~= true then return end
        elseif not reserveNeutralCooldown(streamKey, fam, npcId, aud, now, cd, famCd) then
            return
        end

        local ctx = copyShallow(opts.context)
        ctx.eventType = ctx.eventType or ev
        ctx.eventRef = ctx.eventRef or ref
        ctx.presentationClass = ctx.presentationClass or pres
        ctx.lane = lane
        ctx.domain = ctx.domain or domain
        ctx.topic = ctx.topic or topic
        if lane == "beat" then
            ctx.threadID = ctx.threadID or tid
            if ctx.transient == nil then ctx.transient = true end
        else
            ctx.sceneID = ctx.sceneID or sid
        end

        local observerOnly = opts.observerOnly ~= false
        local recipientKind = opts.recipientKind or (observerOnly and "npc" or "player")
        local ok = net.SendConversationRelationshipForNPC(p, npcId, ev, {
            lightweightBark = opts.lightweightBark ~= nil and (opts.lightweightBark == true) or (lane ~= "scene"),
            source = ev,
            eventID = ref,
            npcID = npcId,
            meaningful = opts.meaningful == true,
            transientInteraction = lane ~= "scene",
            interactionTTLHours = 10 / 3600,
            ambientFlavor = {
                observerOnly = observerOnly,
                recipientKind = recipientKind,
                eventID = ref,
                eventRef = ref,
                lane = lane,
                threadID = tid,
                sceneID = sid,
                conversationID = convID,
                speechEventID = opts.speechEventID or ("semantic." .. channel .. "." .. ev),
                text = opts.text,
                semanticOwned = true,
                eventType = ev,
                act = act,
                topic = topic,
                domain = domain,
                factRefs = opts.factRefs or {},
                offerIDs = opts.offerIDs or {},
                family = fam,
                priority = pri,
                weight = tonumber(opts.weight) or (lane == "scene" and 100 or 0.25),
                llmEligible = opts.llmEligible == true,
                memoryEligible = opts.memoryEligible == true,
                npcID = npcId,
                mergeKey = opts.mergeKey or (ref .. ":" .. npcId),
                ttlMs = tonumber(opts.ttlMs) or 9000,
                holdMs = opts.holdMs,
                interrupt = opts.interrupt == true,
                cooldowns = cCds,
                presentationState = {
                    tts = tts,
                    interrupt = opts.interrupt == true,
                },
                context = ctx,
                presentationClass = pres,
                source = {
                    kind = "semantic_speech",
                    channel = channel,
                    lane = lane,
                    topic = topic,
                    domain = domain,
                    eventType = ev,
                    sceneID = sid,
                    threadID = tid,
                    sessionID = sid,
                    priority = pri,
                },
            },
        }) == true

        if type(opts.postDeliver) == "function" then
            opts.postDeliver(ok, rec, aud, now, opts)
        end
        if ok then sent = sent + 1 end
    end)

    return sent
end

function Transport.ResetRuntime()
    streamCooldowns = {}
    streamOrder = {}
    familyCooldowns = {}
    familyOrder = {}
end

return Transport
