if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_Context"

local Service = PNC.Semantics.CombatTargetCallouts or {}
PNC.Semantics.CombatTargetCallouts = Service

local function finite(value)
    value = tonumber(value)
    if value == nil or value ~= value or value == math.huge or value == -math.huge then
        return nil
    end
    return value
end

Service.Finite = finite

local function playerKey(player)
    if not player then return nil end
    if type(player.getOnlineID) == "function" then
        local value = player:getOnlineID()
        if value ~= nil then return tostring(value) end
    end
    if type(player.getUsername) == "function" then
        local value = player:getUsername()
        if value and value ~= "" then return tostring(value) end
    end
    return nil
end

local function coordinate(object, method)
    if not object or type(object[method]) ~= "function" then return nil end
    return finite(object[method](object))
end

local function canHear(player, record)
    local px, py, pz = coordinate(player, "getX"), coordinate(player, "getY"), coordinate(player, "getZ")
    local nx, ny, nz = finite(record and record.x), finite(record and record.y), finite(record and record.z)
    if not px or not py or not pz or not nx or not ny or not nz then return false end
    if math.abs(pz - nz) >= 1 then return false end
    local rad = tonumber(Service.WITNESS_RADIUS) or 12
    local dx, dy = px - nx, py - ny
    if (dx * dx + dy * dy) > rad * rad then return false end
    local perc = PNC.Perception
    if perc and type(perc.CanSeeWorldObject) == "function" then
        return perc.CanSeeWorldObject(record, player) == true
    end
    return false
end

function Service.FormatTokens(text, tokens)
    local out = tostring(text or "")
    if type(tokens) ~= "table" then return out end
    for key, val in pairs(tokens) do
        if type(key) == "string" and (type(val) == "string" or type(val) == "number") then
            local rep = tostring(val)
            out = string.gsub(out, "{" .. key .. "}", function() return rep end)
        end
    end
    return out
end

function Service.ResolveSemanticLine(record, eventType, act, threatClass, eventRef, profile, tokens)
    local reactions = PNC.ConvoEngine and PNC.ConvoEngine.SocialReactions
    if type(reactions) ~= "table" or type(reactions.Resolve) ~= "function" then
        return nil, nil
    end
    local resolved = reactions.Resolve({
        eventType = eventType,
        eventID = eventRef,
        npcID = tostring(record.id),
        act = act,
        topic = "combat",
        context = {
            semanticThreatClass = threatClass,
            combatReactionStyle = Service.ResolveAllyWarnTone(record, profile),
            inCombat = true,
        },
    })
    if type(resolved) ~= "table" then return nil, nil end
    local raw = resolved.fallback or resolved.text
    local sr = PNC.ConvoEngine and PNC.ConvoEngine.SpeechRealization
    if not sr then
        local ok, mod = pcall(require, "PNC/ConvoEngine/SpeechRealization")
        if ok and type(mod) == "table" then sr = mod end
    end
    if sr and type(sr.Apply) == "function" then
        local applied = sr.Apply({
            selectionID = resolved.realizationID,
            templateID = resolved.templateID,
            fallback = raw,
            plan = resolved.responsePlan,
        }, {
            npcID = tostring(record.id),
            phraseSalt = tostring(eventRef or "") .. ":" .. tostring(record.id),
        })
        if type(applied) == "table" and type(applied.fallback) == "string" and applied.fallback ~= "" then
            raw = applied.fallback
        end
    end
    if type(raw) ~= "string" or raw == "" then return nil, nil end
    local text = type(Service.FormatTokens) == "function" and Service.FormatTokens(raw, tokens) or raw
    return text, resolved
end

function Service.DeliverBark(record, now, opts)
    local core, network = PNC.Core, PNC.Network
    local banter = PNC.ConvoEngine and PNC.ConvoEngine.CombatBanterArbiter
        or require "PNC/ConvoEngine/CombatBanterArbiter"
    if not core or type(core.ForEachPlayer) ~= "function"
        or not network or type(network.SendConversationRelationshipForNPC) ~= "function"
    then
        return 0
    end
    local sent, npcId, ref = 0, tostring(record.id), opts.eventRef
    core.ForEachPlayer(function(player)
        if not canHear(player, record) then return end
        local audience = playerKey(player)
        if not audience then return end
        if banter and type(banter.Reserve) == "function" then
            local allowed = banter.Reserve({
                streamKey = opts.streamKey or ("combat-target:" .. npcId),
                now = now,
                cooldownMs = opts.cooldownMs or Service.COOLDOWN_MS or 5000,
                maxSpeakers = opts.maxSpeakers or 1,
                speakerID = npcId,
                audienceKey = audience,
                family = opts.family or Service.FAMILY,
                familyCooldownMs = opts.familyCooldownMs or Service.COOLDOWN_MS or 5000,
                priority = opts.priority or 75,
            })
            if allowed ~= true then return end
        end
        local ctx = opts.context or {
            eventType = opts.eventType,
            eventRef = ref,
            presentationClass = opts.presentationClass or "BARK",
            transient = true,
        }
        local result = {
            source = opts.eventType,
            eventID = ref,
            npcID = npcId,
            meaningful = false,
            transientInteraction = true,
            interactionTTLHours = 10 / 3600,
            ambientFlavor = {
                eventID = ref,
                eventRef = ref,
                speechEventID = opts.speechEventID,
                text = opts.text,
                semanticOwned = true,
                eventType = opts.eventType,
                act = opts.act or "WARN",
                topic = "combat",
                factRefs = {},
                offerIDs = {},
                family = opts.family or Service.FAMILY,
                priority = opts.priority or 75,
                weight = 0.25,
                llmEligible = false,
                memoryEligible = false,
                npcID = npcId,
                mergeKey = ref .. ":" .. npcId,
                ttlMs = 6000,
                holdMs = 1500,
                context = ctx,
                presentationClass = opts.presentationClass or "BARK",
                source = {
                    kind = "semantic_speech",
                    channel = "combat",
                    eventType = opts.eventType,
                },
            },
        }
        local delivered = network.SendConversationRelationshipForNPC(
            player, npcId, opts.eventType, result
        ) == true
        if banter and type(banter.RecordPresentation) == "function" then
            banter.RecordPresentation({
                accepted = delivered,
                reason = delivered and "presentation_sent" or "presentation_transport_refused",
                at = now,
                speakerID = npcId,
                audienceKey = audience,
                family = opts.family or Service.FAMILY,
                eventRef = ref,
                presentationClass = opts.presentationClass or "BARK",
                tacticalSpatial = opts.tacticalSpatial,
                tacticalPresentation = opts.tacticalPresentation,
            })
        end
        if delivered then sent = sent + 1 end
    end)
    return sent
end

return Service
