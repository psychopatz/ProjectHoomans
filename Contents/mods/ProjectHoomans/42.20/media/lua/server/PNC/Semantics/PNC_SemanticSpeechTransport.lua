-- Domain-neutral semantic speech presentation transport.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

require "PNC/Semantics/PNC_SemanticSpeechTransport_Resolve"

local Transport = PNC.Semantics.SpeechTransport or {}
PNC.Semantics.SpeechTransport = Transport

Transport.VERSION = 1

local finite = Transport.Finite
local cleanText = Transport.CleanText
local copyShallow = Transport.CopyShallow
local playerKey = Transport.PlayerKey
local canHear = Transport.CanHear
local reserveNeutralCooldown = Transport.ReserveNeutralCooldown

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
    local diag = PNC.PerformanceScalingDiagnostics
    local beatAudit = lane == "beat" and diag ~= nil and diag.BeatsAuditEnabled == true
    local playerCount = 0

    core.ForEachPlayer(function(p)
        playerCount = playerCount + 1
        if type(opts.audienceFilter) == "function" then
            if opts.audienceFilter(p, rec) ~= true then
                if beatAudit then
                    diag.LogBeatsAudit("transport_drop", {
                        "npc=" .. npcId,
                        "eventType=" .. tostring(ev),
                        "poolID=" .. tostring(opts.poolID or "nil"),
                        "reason=audience_filter",
                    })
                end
                return
            end
        elseif not canHear(p, rec, witnessRadius) then
            if beatAudit then
                local px = p and p.getX and finite(p:getX())
                local py = p and p.getY and finite(p:getY())
                local pz = p and p.getZ and finite(p:getZ())
                local nx, ny, nz = finite(rec.x), finite(rec.y), finite(rec.z)
                local dist = (px and py and nx and ny)
                    and math.floor(math.sqrt((px - nx) * (px - nx) + (py - ny) * (py - ny)) * 10 + 0.5) / 10
                    or -1
                local zDiff = (pz and nz) and math.abs(pz - nz) or -1
                local perc = PNC.Perception
                local canSee = perc and type(perc.CanSeeWorldObject) == "function"
                    and perc.CanSeeWorldObject(rec, p) == true or false
                diag.LogBeatsAudit("transport_drop", {
                    "npc=" .. npcId,
                    "eventType=" .. tostring(ev),
                    "poolID=" .. tostring(opts.poolID or "nil"),
                    "reason=can_hear_false",
                    "dist=" .. tostring(dist),
                    "witnessRadius=" .. tostring(witnessRadius),
                    "zDiff=" .. tostring(zDiff),
                    "canSee=" .. tostring(canSee),
                })
            end
            return
        end
        local aud = playerKey(p)
        if not aud then
            if beatAudit then
                diag.LogBeatsAudit("transport_drop", {
                    "npc=" .. npcId,
                    "eventType=" .. tostring(ev),
                    "reason=no_player_key",
                })
            end
            return
        end
        if type(opts.preDeliver) == "function" then
            if opts.preDeliver(rec, aud, now, opts) ~= true then
                if beatAudit then
                    diag.LogBeatsAudit("transport_drop", {
                        "npc=" .. npcId,
                        "eventType=" .. tostring(ev),
                        "aud=" .. tostring(aud),
                        "reason=pre_deliver_false",
                    })
                end
                return
            end
        elseif not reserveNeutralCooldown(streamKey, fam, npcId, aud, now, cd, famCd) then
            if beatAudit then
                diag.LogBeatsAudit("transport_drop", {
                    "npc=" .. npcId,
                    "eventType=" .. tostring(ev),
                    "aud=" .. tostring(aud),
                    "streamKey=" .. tostring(streamKey),
                    "family=" .. tostring(fam),
                    "reason=transport_cooldown",
                })
            end
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

        local responsePlanID = opts.responsePlanID or ctx.responsePlanID
        local realizationID = opts.realizationID or ctx.realizationID
        local poolID = opts.poolID or ctx.poolID
        local realizationFamily = opts.realizationFamily or ctx.realizationFamily
        local flowID = opts.flowID or ctx.flowID
        local hasReplyOffers = type(opts.offerIDs) == "table" and #opts.offerIDs > 0
        local observerOnly
        if opts.observerOnly ~= nil then
            observerOnly = opts.observerOnly == true
        else
            observerOnly = not hasReplyOffers
        end
        local recipientKind = opts.recipientKind or (observerOnly and "npc" or "player")
        local ok = net.SendConversationRelationshipForNPC(p, npcId, ev, {
            lightweightBark = opts.lightweightBark == true or (opts.lightweightBark == nil and lane ~= "scene"),
            source = ev,
            eventID = ref,
            eventRef = ref,
            npcID = npcId,
            meaningful = opts.meaningful == true,
            transientInteraction = lane ~= "scene",
            interactionTTLHours = 10 / 3600,
            responsePlanID = responsePlanID,
            realizationID = realizationID,
            poolID = poolID,
            realizationFamily = realizationFamily,
            flowID = flowID,
            factRefs = opts.factRefs,
            offerIDs = opts.offerIDs,
            semanticEventFacts = opts.semanticEventFacts,
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
                responsePlanID = responsePlanID,
                realizationID = realizationID,
                poolID = poolID,
                realizationFamily = realizationFamily,
                flowID = flowID,
                factRefs = opts.factRefs or {},
                offerIDs = opts.offerIDs or {},
                semanticEventFacts = opts.semanticEventFacts,
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
                presentationState = { tts = tts, interrupt = opts.interrupt == true },
                context = ctx,
                presentationClass = pres,
                source = {
                    kind = "semantic_speech", channel = channel, lane = lane,
                    topic = topic, domain = domain, eventType = ev,
                    sceneID = sid, threadID = tid, sessionID = sid, priority = pri,
                },
            },
        }) == true

        if type(opts.postDeliver) == "function" then
            opts.postDeliver(ok, rec, aud, now, opts)
        end
        if ok then
            sent = sent + 1
        elseif beatAudit then
            diag.LogBeatsAudit("transport_drop", {
                "npc=" .. npcId,
                "eventType=" .. tostring(ev),
                "aud=" .. tostring(aud),
                "reason=network_send_false",
            })
        end
    end)

    if beatAudit and playerCount == 0 then
        diag.LogBeatsAudit("transport_drop", {
            "npc=" .. npcId,
            "eventType=" .. tostring(ev),
            "reason=no_players",
        })
    end

    return sent
end

return Transport
