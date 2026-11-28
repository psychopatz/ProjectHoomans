-- Lightweight server-authoritative NPC-to-NPC social exchange service.
--
-- Drives visible overhead exchanges between nearby idle NPCs (Colonist<->Colonist,
-- Colonist<->Neutral, Neutral<->Neutral) using existing Beats.StartThread,
-- PsychopatzSocial / PNC.Relationships, Kinsey-aware romance promotion, and
-- PNC.SocialWitness hearsay propagation.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then
    return
end

PNC = PNC or {}
PNC.NPCSocialExchange = PNC.NPCSocialExchange or {}

local Service = PNC.NPCSocialExchange

Service.SCAN_INTERVAL_MS = 12000
Service.GLOBAL_COOLDOWN_MS = 25000
Service.PAIR_COOLDOWN_HOURS = 2.0
Service.EXCHANGE_RADIUS = 5.5
Service.PLAYER_HEAR_RADIUS = 16
Service.MAX_ANCHORS_PER_SCAN = 4
Service.MAX_PAIR_COOLDOWNS = 64

Service.State = Service.State or {
    nextScanAtMs = 0,
    nextGlobalExchangeAtMs = 0,
    pairCooldowns = {},
    pairOrder = {},
    tickHookInstalled = false,
}

local function nowMs(explicit)
    if tonumber(explicit) then return math.max(0, tonumber(explicit)) end
    if PNC.Core and type(PNC.Core.Now) == "function" then
        return math.max(0, tonumber(PNC.Core.Now()) or 0)
    end
    if getTimeInMillis then return math.max(0, tonumber(getTimeInMillis()) or 0) end
    return 0
end

local function worldAgeHours(explicit)
    if tonumber(explicit) then return math.max(0, tonumber(explicit)) end
    if getGameTime and getGameTime() and getGameTime().getWorldAgeHours then
        return math.max(0, tonumber(getGameTime():getWorldAgeHours()) or 0)
    end
    return 0
end

local function npcKey(id)
    if PNC.EntityRef and type(PNC.EntityRef.ForNPC) == "function" then
        local key = PNC.EntityRef.ForNPC(id)
        if type(key) == "string" and key ~= "" then return key end
    end
    return "npc:" .. tostring(id)
end

local function pairKey(idA, idB)
    local a, b = tostring(idA or ""), tostring(idB or "")
    if a < b then return a .. "|" .. b end
    return b .. "|" .. a
end

local function rememberPairCooldown(idA, idB, untilHour)
    local st = Service.State
    local key = pairKey(idA, idB)
    if st.pairCooldowns[key] == nil then
        st.pairOrder[#st.pairOrder + 1] = key
        while #st.pairOrder > Service.MAX_PAIR_COOLDOWNS do
            local oldest = table.remove(st.pairOrder, 1)
            st.pairCooldowns[oldest] = nil
        end
    end
    st.pairCooldowns[key] = untilHour
end

local function isPairOnCooldown(idA, idB, worldAge)
    local untilHour = Service.State.pairCooldowns[pairKey(idA, idB)]
    return untilHour ~= nil and worldAge < untilHour
end

local function isHostileRecord(record)
    local tc = string.lower(tostring(record and record.tacticalClass or ""))
    if tc == "hostile" then return true end
    local h = record and record.hostility or nil
    if type(h) == "string" then
        local lh = string.lower(h)
        return lh == "hostile" or lh == "enemy"
    end
    return type(h) == "table" and h.hostile == true
end

local function factionsHostile(recA, recB)
    local fA = recA and recA.affiliation and recA.affiliation.factionID or nil
    local fB = recB and recB.affiliation and recB.affiliation.factionID or nil
    if not fA or not fB or fA == "" or fB == "" or fA == fB then
        return false
    end
    local factions = PNC.Factions
    if not factions or type(factions.GetRelation) ~= "function" then
        return false
    end
    local rel = factions.GetRelation(fA, fB)
    if type(rel) ~= "table" then return false end
    local state = string.lower(tostring(rel.state or rel.stance or ""))
    return rel.atWar == true or state == "hostile" or state == "enemy"
end

function Service.IsEligibleParticipant(record)
    if type(record) ~= "table" or record.id == nil then return false end
    if record.alive == false or record.available == false then return false end
    if isHostileRecord(record) then return false end
    local health = record.health
    if type(health) == "table" and (health.state == "dead" or health.state == "incapacitated") then
        return false
    end
    local rt = record.runtime
    if type(rt) == "table" then
        if rt.available == false or rt.inCombat == true or rt.fleeing == true
            or rt.target ~= nil or rt.attackAction ~= nil
        then
            return false
        end
        local inCombatUntil = tonumber(rt.inCombatUntil) or 0
        if inCombatUntil > 0 and nowMs() < inCombatUntil then
            return false
        end
        if rt.conversationActive == true or rt.inConversation == true then
            return false
        end
    end
    return true
end

local function displayName(record)
    local name = tostring(record and (record.name or (record.identity and record.identity.name)) or "")
    if name == "" then return "Survivor" end
    return name
end

local function firstName(record)
    local full = displayName(record)
    return string.match(full, "^(%S+)") or full
end

local function edgeFor(record, targetKey)
    return record and record.social and record.social.relationships
        and record.social.relationships[targetKey] or nil
end

local function resolveProfile(record)
    if PNC.SocialProfiles and type(PNC.SocialProfiles.GetNPCProfile) == "function" then
        local prof = PNC.SocialProfiles.GetNPCProfile(record and record.id)
        if prof then return prof end
    end
    return record and record.social and record.social.personality or {}
end

local function clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

local function applyExchangeDeltas(record, targetKey, deltas, at)
    local Types = PNC.RelationshipTypes
    local Relationships = PNC.Relationships
    local Internal = Relationships and Relationships.Internal or nil
    if not Types or type(Types.NormalizeSocialState) ~= "function" then return nil end
    local social = Types.NormalizeSocialState(
        record.social, record.identitySeed, record.archetypeID
    )
    local rel = Types.NormalizeRelationship(social.relationships[targetKey], targetKey)
    if not rel then return nil end
    rel.approval = clamp((tonumber(rel.approval) or 0) + (deltas.approval or 0), -100, 100)
    rel.respect = clamp((tonumber(rel.respect) or 0) + (deltas.respect or 0), -100, 100)
    rel.familiarity = clamp((tonumber(rel.familiarity) or 0) + (deltas.familiarity or 0), 0, 100)
    rel.lastInteractionAt = at
    if rel.firstMetAt == nil then rel.firstMetAt = at end
    if rel.state == "unknown" then rel.state = "neutral" end
    if rel.approval >= 35 and rel.familiarity >= 25 and rel.state == "neutral" then
        rel.state = "friend"
    end
    social.relationships[targetKey] = rel
    if Relationships and type(Relationships.PruneNPCRelationships) == "function" then
        Relationships.PruneNPCRelationships(social, targetKey)
    end
    if Internal and type(Internal.commit) == "function" then
        Internal.commit(record, social, targetKey, rel, true, at, {
            kind = "npc_social_exchange",
        })
    else
        record.social = social
    end
    return rel
end

local function emitExchangeBeat(recA, recB, stage, tokens, now)
    local Beats = PNC.SemanticDialogueBeats
    if not Beats or type(Beats.StartThread) ~= "function" then
        return false
    end
    local poolID = "semantic.social.npc_exchange." .. tostring(stage)
    local threadID = "npc_social:" .. stage .. ":" .. pairKey(recA.id, recB.id)
        .. ":" .. tostring(math.floor(now))
    local openTokens = type(tokens) == "table" and tokens or {}
    openTokens["speaker.name"] = displayName(recA)
    local replyTokens = type(tokens) == "table" and {} or {}
    for k, v in pairs(openTokens) do replyTokens[k] = v end
    replyTokens["speaker.name"] = displayName(recB)
    local plan = {
        threadID = threadID,
        eventRef = threadID,
        ttlMs = 7000,
        opening = {
            speaker = recA,
            addressee = recB,
            addresseeName = firstName(recB),
            eventType = "npc_social_" .. stage,
            family = "npc_social_exchange",
            poolID = poolID,
            role = "open",
            domain = "social",
            topic = "social_" .. stage,
            tokens = openTokens,
            priority = 24,
            cooldownMs = 4000,
            familyCooldownMs = 4000,
        },
        replies = {
            {
                speaker = recB,
                addressee = recA,
                addresseeName = firstName(recA),
                eventType = "npc_social_" .. stage,
                family = "npc_social_exchange",
                poolID = poolID,
                role = "reply",
                domain = "social",
                topic = "social_" .. stage,
                tokens = replyTokens,
                delayMs = 1500,
                priority = 24,
                cooldownMs = 4000,
                familyCooldownMs = 4000,
            },
        },
    }
    return Beats.StartThread(plan, now) ~= nil
end

---Executes one bounded social exchange between two eligible NPCs.
function Service.TryExchange(recA, recB, opts)
    opts = type(opts) == "table" and opts or {}
    if not Service.IsEligibleParticipant(recA) or not Service.IsEligibleParticipant(recB) then
        return false, "participant_ineligible"
    end
    if tostring(recA.id) == tostring(recB.id) then
        return false, "same_participant"
    end
    if factionsHostile(recA, recB) then
        return false, "factions_hostile"
    end
    local keyA, keyB = npcKey(recA.id), npcKey(recB.id)
    local edgeAB = edgeFor(recA, keyB)
    local edgeBA = edgeFor(recB, keyA)
    if (edgeAB and (edgeAB.state == "enemy" or edgeAB.state == "rival"))
        or (edgeBA and (edgeBA.state == "enemy" or edgeBA.state == "rival"))
    then
        return false, "standing_hostile"
    end

    local now = nowMs(opts.nowMs)
    local worldAge = worldAgeHours(opts.worldAgeHours)
    if not opts.ignoreCooldown then
        if now < (tonumber(Service.State.nextGlobalExchangeAtMs) or 0) then
            return false, "global_cooldown"
        end
        if isPairOnCooldown(recA.id, recB.id, worldAge) then
            return false, "pair_cooldown"
        end
    end

    local Relationships = PNC.Relationships
    local ProfileMath = PNC.SocialProfileMath
    local chem = 0
    if ProfileMath and type(ProfileMath.PersonalityChemistry) == "function" then
        chem = ProfileMath.PersonalityChemistry(resolveProfile(recA), resolveProfile(recB))
    end
    local approvalGain = math.max(-1, math.floor(2.5 + chem * 3 + 0.5))
    local respectGain = math.max(0, math.floor(1.5 + chem * 2 + 0.5))

    local knowsA = edgeAB and edgeAB.knowsName == true
    local knowsB = edgeBA and edgeBA.knowsName == true
    local stage
    local exchangeTokens = {}
    local hearsayPropagated = false

    -- Stage 1: Exchange names / introductions
    if not knowsA or not knowsB then
        stage = "intro"
        if Relationships and type(Relationships.MarkKnownName) == "function" then
            Relationships.MarkKnownName(recA.id, keyB, worldAge)
            Relationships.MarkKnownName(recB.id, keyA, worldAge)
        end
        applyExchangeDeltas(recA, keyB, {
            approval = math.max(1, approvalGain),
            respect = respectGain,
            familiarity = 5,
        }, worldAge)
        applyExchangeDeltas(recB, keyA, {
            approval = math.max(1, approvalGain),
            respect = respectGain,
            familiarity = 5,
        }, worldAge)
    else
        -- Stage 3 check: Organic lover promotion for mature friends
        local bondAB = edgeAB and edgeAB.bond and edgeAB.bond.class or "none"
        local bondBA = edgeBA and edgeBA.bond and edgeBA.bond.class or "none"
        local promotedLover = false
        if bondAB == "friend" and bondBA == "friend"
            and Relationships
            and type(Relationships.EvaluateNPCRomancePromotion) == "function"
        then
            promotedLover = Relationships.EvaluateNPCRomancePromotion(
                recA.id, recB.id, worldAge
            ) == true
        end

        if promotedLover then
            stage = "lover"
        else
            -- Stage 2: Acquaintance small talk + hearsay gossip + friend promotion
            applyExchangeDeltas(recA, keyB, {
                approval = approvalGain,
                respect = respectGain,
                familiarity = 4,
            }, worldAge)
            applyExchangeDeltas(recB, keyA, {
                approval = approvalGain,
                respect = respectGain,
                familiarity = 4,
            }, worldAge)

            local newFriend = false
            local evalBond = Relationships and Relationships.Internal
                and Relationships.Internal.EvaluateDurableBond or nil
            if type(evalBond) == "function" then
                if evalBond(recA, keyB, worldAge) == true then newFriend = true end
                if evalBond(recB, keyA, worldAge) == true then newFriend = true end
            end

            local Witness = PNC.SocialWitness
            if Witness and type(Witness.PropagateHearsay) == "function" then
                local res = Witness.PropagateHearsay(recA, recB, { worldAgeHours = worldAge })
                if res and res.propagated == true then
                    hearsayPropagated = true
                else
                    local resBack = Witness.PropagateHearsay(recB, recA, { worldAgeHours = worldAge })
                    hearsayPropagated = resBack and resBack.propagated == true or false
                end
            end

            local worldTopic = nil
            local WKG = PsychopatzCore and PsychopatzCore.WorldKnowledge or nil
            if not newFriend and not hearsayPropagated
                and WKG and type(WKG.QueryConversationTopics) == "function"
            then
                local topics = WKG.QueryConversationTopics(
                    recA.actorID or recA.id,
                    {
                        npcID = recA.id,
                        identitySeed = recA.identitySeed,
                        x = recA.x,
                        y = recA.y,
                        worldDay = math.floor(worldAge / 24),
                        worldHour = worldAge,
                    },
                    { limit = 1 }
                )
                if type(topics) == "table" and topics[1] then
                    worldTopic = topics[1]
                end
            end

            if newFriend then
                stage = "friend"
            elseif hearsayPropagated or worldTopic then
                stage = "gossip"
                exchangeTokens["slot.gossip_time"] = (worldTopic and worldTopic.timeLabel) or "earlier"
                exchangeTokens["slot.gossip_location"] = (worldTopic and worldTopic.locationLabel) or "nearby"
                exchangeTokens["slot.gossip_headline"] = (worldTopic and worldTopic.subjectLabel) or ""
            else
                stage = "chat"
            end
        end
    end

    rememberPairCooldown(recA.id, recB.id, worldAge + Service.PAIR_COOLDOWN_HOURS)
    Service.State.nextGlobalExchangeAtMs = now + Service.GLOBAL_COOLDOWN_MS
    local spoke = emitExchangeBeat(recA, recB, stage, exchangeTokens, now)
    return true, stage, {
        spoke = spoke,
        hearsayPropagated = hearsayPropagated,
        chemistry = chem,
    }
end

local function distanceSq(a, b)
    local ax, ay, az = tonumber(a.x), tonumber(a.y), tonumber(a.z) or 0
    local bx, by, bz = tonumber(b.x), tonumber(b.y), tonumber(b.z) or 0
    if not ax or not ay or not bx or not by or math.abs(az - bz) >= 1 then
        return math.huge
    end
    local dx, dy = ax - bx, ay - by
    return dx * dx + dy * dy
end

function Service.Update(explicitNowMs, explicitWorldAge)
    local now = nowMs(explicitNowMs)
    local st = Service.State
    if now < (tonumber(st.nextScanAtMs) or 0) then return false, "scan_throttled" end
    st.nextScanAtMs = now + Service.SCAN_INTERVAL_MS
    if now < (tonumber(st.nextGlobalExchangeAtMs) or 0) then
        return false, "global_cooldown"
    end
    local core = PNC.Core
    local spatial = PNC.SpatialIndex
    if not core or type(core.ForEachPlayer) ~= "function"
        or not spatial or type(spatial.QueryNPCs) ~= "function"
    then
        return false, "dependencies_unavailable"
    end

    local worldAge = worldAgeHours(explicitWorldAge)
    local pairRadiusSq = Service.EXCHANGE_RADIUS * Service.EXCHANGE_RADIUS
    local triggered = false
    local triggeredStage = nil

    core.ForEachPlayer(function(player)
        if triggered or not player then return end
        if player.isDead and player:isDead() then return end
        local px = player.getX and tonumber(player:getX()) or nil
        local py = player.getY and tonumber(player:getY()) or nil
        if not px or not py then return end
        local nearby = spatial.QueryNPCs(px, py, Service.PLAYER_HEAR_RADIUS)
        if type(nearby) ~= "table" or #nearby < 2 then return end
        local checked = 0
        for i = 1, #nearby do
            if triggered or checked >= Service.MAX_ANCHORS_PER_SCAN then break end
            local recA = nearby[i]
            if Service.IsEligibleParticipant(recA) then
                checked = checked + 1
                for j = i + 1, #nearby do
                    local recB = nearby[j]
                    if Service.IsEligibleParticipant(recB)
                        and distanceSq(recA, recB) <= pairRadiusSq
                        and not isPairOnCooldown(recA.id, recB.id, worldAge)
                    then
                        local ok, stage = Service.TryExchange(recA, recB, {
                            nowMs = now,
                            worldAgeHours = worldAge,
                        })
                        if ok then
                            triggered = true
                            triggeredStage = stage
                            break
                        end
                    end
                end
            end
        end
    end)

    return triggered, triggeredStage
end

if not Service.State.tickHookInstalled then
    local TickRegistry = PNC.Server and PNC.Server.TickRegistry
        or require "PNC/Server/Server/PNC_Server_TickRegistry"
    if TickRegistry and type(TickRegistry.Register) == "function" then
        Service.State.tickHookInstalled = true
        TickRegistry.Register("social_exchange", {
            phase = "finish",
            priority = 80,
            pump = function() Service.Update() end,
        })
    elseif Events and Events.OnTick and type(Events.OnTick.Add) == "function" then
        Service.State.tickHookInstalled = true
        Events.OnTick.Add(function()
            Service.Update()
        end)
    end
end

return Service
