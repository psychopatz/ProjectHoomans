-- ConvoEngine Beat Debug backend: live engine telemetry, cached variable
-- inspection, nearby actor discovery (including player), and on-demand
-- in-game beat execution for testing dialogue beats and offers.

PNC = PNC or {}
PNC.BeatDebugModel = PNC.BeatDebugModel or {}

local Model = PNC.BeatDebugModel

Model.HISTORY_LIMIT = 40
Model.history = Model.history or {}
Model.hitCounts = Model.hitCounts or {}
Model.execCounter = Model.execCounter or 0

local function safeRequire(path)
    local ok, mod = pcall(require, path)
    if ok and type(mod) == "table" then return mod end
    return nil
end

local function getCatalog()
    return (PNC.ConvoEngine and PNC.ConvoEngine.ResponseCatalog)
        or safeRequire("PNC/ConvoEngine/Dialogue/ResponseCatalog")
end

local function getLexicon()
    return (PNC.ConvoEngine and PNC.ConvoEngine.Lexicon)
        or safeRequire("PNC/ConvoEngine/Lexicon")
end

local function getSwitchCtrl()
    return (PNC.ConvoEngine and PNC.ConvoEngine.ConversationSwitchAndFarewell)
        or safeRequire("PNC/ConvoEngine/Dialogue/ConversationSwitchAndFarewell")
end

local function getPatience()
    return (PNC.ConvoEngine and PNC.ConvoEngine.PatienceTracker)
        or safeRequire("PNC/ConvoEngine/PatienceTracker")
end

local function getGroupFloor()
    return (PNC.ConvoEngine and PNC.ConvoEngine.GroupFloor)
        or safeRequire("PNC/ConvoEngine/GroupFloor")
end

local function countTable(tbl)
    local n = 0
    if type(tbl) == "table" then
        for _ in pairs(tbl) do n = n + 1 end
    end
    return n
end

local function nowMs()
    if getTimestampMs then
        local ok, v = pcall(getTimestampMs)
        if ok and tonumber(v) then return tonumber(v) end
    end
    if PNC.Core and type(PNC.Core.Now) == "function" then
        local ok, v = pcall(PNC.Core.Now)
        if ok and tonumber(v) then return tonumber(v) end
    end
    return 0
end

function Model.RecordExecution(entry)
    if type(entry) ~= "table" then return end
    local poolID = tostring(entry.poolID or "unknown")
    Model.hitCounts[poolID] = (Model.hitCounts[poolID] or 0) + 1
    table.insert(Model.history, 1, entry)
    while #Model.history > Model.HISTORY_LIMIT do
        table.remove(Model.history)
    end
end

function Model.ListBeats(filterText)
    local catalog = getCatalog()
    local pools = catalog and (catalog.POOLS or catalog.Pools or catalog.pools or (catalog.GetPools and catalog.GetPools())) or {}
    local needle = string.lower(tostring(filterText or ""))
    local out = {}
    for poolID, pool in pairs(pools) do
        local idStr = tostring(poolID)
        if needle == "" or string.find(string.lower(idStr), needle, 1, true) then
            local variants = type(pool) == "table" and (pool.variants or pool) or {}
            local vCount = type(variants) == "table" and #variants or 0
            out[#out + 1] = {
                id = idStr,
                variantCount = vCount,
                hits = Model.hitCounts[idStr] or 0,
                label = idStr,
                detail = "variants=" .. tostring(vCount) .. " | hits=" .. tostring(Model.hitCounts[idStr] or 0),
            }
        end
    end
    table.sort(out, function(a, b) return a.id < b.id end)
    return out
end

function Model.BuildOverview()
    local catalog = getCatalog()
    local lex = getLexicon()
    local pools = catalog and (catalog.POOLS or catalog.Pools or catalog.pools or (catalog.GetPools and catalog.GetPools())) or {}
    local poolCount = 0
    local variantCount = 0
    for _, pool in pairs(pools) do
        poolCount = poolCount + 1
        local variants = type(pool) == "table" and (pool.variants or pool) or {}
        if type(variants) == "table" then variantCount = variantCount + #variants end
    end
    local lexTables = lex and (lex.Tables or lex.tables) or {}
    local surface = PNC.ConvoEngine and PNC.ConvoEngine.CombatResponseSurface or nil
    local activePrompt = surface and surface.active or nil
    local inline = PNC.Conversation and PNC.Conversation.InlineChat and PNC.Conversation.InlineChat.State or nil
    local patience = getPatience()
    local floor = getGroupFloor()

    local townCatalog = safeRequire("PNC/ConvoEngine/Dialogue/WorldMapTownCatalog")
    local towns = townCatalog and type(townCatalog.GetTowns) == "function" and townCatalog.GetTowns() or {}
    local kv = {
        { label = "Registered Beat Pools", value = tostring(poolCount) },
        { label = "Total Beat Variants", value = tostring(variantCount) },
        { label = "Lexicon Tables", value = tostring(countTable(lexTables)) },
        { label = "Discovered Map Towns", value = tostring(#towns) },
        { label = "Debug Executions", value = tostring(Model.execCounter) },
        { label = "Active Prompt NPC", value = activePrompt and tostring(activePrompt.npcID or "none") or "none" },
        { label = "Active Prompt Choices", value = activePrompt and type(activePrompt.rows) == "table" and tostring(#activePrompt.rows) or "0" },
        { label = "Inline Chat Open", value = (inline and inline.part ~= nil) and "yes" or "no" },
        { label = "Inline Mode / Scope", value = tostring(inline and inline.mode or "none") .. " / " .. tostring(inline and inline.scope or "none") },
        { label = "Inline Target ID", value = tostring(inline and inline.targetID or "none") },
        { label = "Inline Quick Replies", value = tostring(inline and type(inline.activeQuickReplies) == "table" and #inline.activeQuickReplies or 0) },
    }
    if type(patience) == "table" and type(patience.State) == "table" then
        kv[#kv + 1] = { label = "Patience Tracked Pairs", value = tostring(countTable(patience.State)) }
    end
    if type(floor) == "table" and type(floor.State) == "table" then
        kv[#kv + 1] = { label = "GroupFloor Active", value = tostring(floor.State.active == true) }
        kv[#kv + 1] = { label = "GroupFloor Last Speaker", value = tostring(floor.State.lastSpeakerID or "none") }
    end
    local conv = PsychopatzCore and PsychopatzCore.Conversation or nil
    local view = conv and conv.instance or nil
    if view and view.session then
        kv[#kv + 1] = { label = "Active UI NPC", value = tostring(view.session.npcID or "none") }
        kv[#kv + 1] = { label = "Paused Actors Cached", value = tostring(countTable(view.session.pausedActors)) }
        kv[#kv + 1] = { label = "Saved Actor Logs", value = tostring(countTable(view.session.historyByActor)) }
    end

    local recent = {}
    for i = 1, #Model.history do
        local h = Model.history[i]
        recent[#recent + 1] = {
            label = tostring(h.poolID or "?") .. " [" .. tostring(h.speakerName or "?") .. "]",
            detail = tostring(h.text or ""),
        }
    end
    if #recent == 0 then
        recent[1] = { label = "No beats executed yet", detail = "Use the BEAT TESTER tab to trigger a beat." }
    end
    return kv, recent
end

function Model.CollectAvailableActors(player)
    player = player or (getSpecificPlayer and getSpecificPlayer(0)) or (getPlayer and getPlayer()) or nil
    local out = {}
    local seen = {}
    if player then
        local pName = "Player"
        if player.getDescriptor and player:getDescriptor() and player:getDescriptor().getForename then
            local ok, fn = pcall(function() return player:getDescriptor():getForename() end)
            if ok and fn and fn ~= "" then pName = tostring(fn) end
        elseif player.getUsername then
            local ok, un = pcall(player.getUsername, player)
            if ok and un and un ~= "" then pName = tostring(un) end
        end
        out[#out + 1] = {
            id = "player",
            name = pName .. " (Player)",
            rawName = pName,
            isPlayer = true,
            npcType = "player",
            body = player,
            label = pName .. " [PLAYER]",
            detail = "Local player character",
        }
        seen["player"] = true
    end

    local resolver = PNC.CompanionTargetResolver
    if player and resolver and type(resolver.CollectNearbyTargets) == "function" then
        local ok, nearby = pcall(resolver.CollectNearbyTargets, player, 25, resolver.SCOPE_SOCIAL or "social")
        if ok and type(nearby) == "table" then
            for _, cand in ipairs(nearby) do
                local id = tostring(cand and cand.id or "")
                if id ~= "" and not seen[id] then
                    seen[id] = true
                    local body = cand.zombie
                    if not body and PNC.Registry and PNC.Registry.GetLiveZombie then
                        body = PNC.Registry.GetLiveZombie(id)
                    end
                    local role = tostring(cand.npcType or (cand.colonist and "colonist") or "npc")
                    out[#out + 1] = {
                        id = id,
                        name = tostring(cand.name or id),
                        rawName = tostring(cand.name or id),
                        isPlayer = false,
                        npcType = role,
                        colonist = cand.colonist,
                        isTrader = cand.isTrader,
                        isCompanion = cand.isCompanion,
                        familyRole = cand.familyRole,
                        age = cand.age,
                        body = body,
                        source = cand,
                        label = tostring(cand.name or id) .. " [" .. role .. "]",
                        detail = "id=" .. id,
                    }
                end
            end
        end
    end
    return out
end

local function getSemanticSpeechPresentation()
    local pres = PNC.SemanticSpeechPresentation
    if type(pres) == "table" and type(pres.Receive) == "function" then return pres end
    local loaded = safeRequire("PNC/Conversation/PNC_SemanticSpeechPresentation")
    if type(loaded) == "table" and type(loaded.Receive) == "function" then return loaded end
    return PNC.SemanticSpeechPresentation
end

local function speakActor(actor, text, poolID, eventID, offerIDs, realizationID)
    if not actor or tostring(text or "") == "" then return false, "empty" end
    local line = tostring(text)

    if actor.isPlayer then
        local player = actor.body
            or (getSpecificPlayer and getSpecificPlayer(0))
            or (getPlayer and getPlayer()) or nil
        if player and PNC.PlayerSpeech and type(PNC.PlayerSpeech.Speak) == "function" then
            local ok = pcall(PNC.PlayerSpeech.Speak, player, line, {
                commandID = "beat_debug",
                eventID = tostring(eventID or ("beat_dbg:player:" .. tostring(nowMs()))),
                target = nil,
                targets = {},
                suppressSocialReaction = true,
            })
            if ok then return true, "PNC.PlayerSpeech.Speak" end
        end
        return false, "player_speech_unavailable"
    end

    -- Reuse the single canonical semantic speech presentation pipeline:
    -- it automatically delivers to Conversation UI or overhead nameplates,
    -- pumps immediately, and feeds CombatResponseSurface / insult.png when
    -- offers are present.
    local pres = getSemanticSpeechPresentation()
    if type(pres) == "table" and type(pres.Receive) == "function" then
        local npcID = tostring(actor.id or "")
        local hasOffers = type(offerIDs) == "table" and #offerIDs > 0
        local ok, accepted, reason = pcall(pres.Receive, {
            eventID = tostring(eventID or ("beat_dbg:" .. npcID .. ":" .. tostring(nowMs()))),
            eventRef = tostring(eventID or ("beat_dbg:" .. npcID .. ":" .. tostring(nowMs()))),
            eventType = "beat_debug",
            family = "beat_debug",
            npcID = npcID,
            semanticOwned = true,
            poolID = tostring(poolID or ""),
            responsePlanID = tostring(poolID or ""),
            realizationID = tostring(realizationID or poolID or "beat_debug"),
            offerIDs = hasOffers and offerIDs or nil,
            text = line,
            resolvedText = line,
            llmEligible = false,
            memoryEligible = false,
            pumpImmediately = true,
            priority = 92,
            weight = 100,
            ttlMs = 8000,
            cooldowns = { ambientMs = 0, familyMs = 0, speakerMs = 0 },
            context = {
                npcID = npcID,
                npcName = tostring(actor.name or npcID),
                presentationClass = hasOffers and "SOCIAL_PROMPT" or nil,
                offerIDs = hasOffers and offerIDs or nil,
            },
        })
        if ok and accepted == true then
            return true, "PNC.SemanticSpeechPresentation.Receive"
        end
        return false, tostring(reason or "presentation_rejected")
    end
    return false, "semantic_speech_presentation_unavailable"
end

function Model.ExecuteBeat(selectedActors, poolID, overrides)
    poolID = tostring(poolID or "")
    if poolID == "" then return { ok = false, reason = "no_beat_selected" } end
    selectedActors = type(selectedActors) == "table" and selectedActors or {}
    if #selectedActors == 0 then return { ok = false, reason = "no_actors_selected" } end

    local catalog = getCatalog()
    local lex = getLexicon()
    local switchCtrl = getSwitchCtrl()
    if not catalog or not lex then return { ok = false, reason = "convo_engine_unavailable" } end

    local speaker = selectedActors[1]
    local addressee = selectedActors[2] or selectedActors[1]
    overrides = type(overrides) == "table" and overrides or {}

    local baseCtx = {}
    for k, v in pairs(overrides) do
        if v ~= nil and v ~= "" and v ~= "(auto)" then baseCtx[k] = v end
    end
    local condCtx, tokens
    if switchCtrl and type(switchCtrl.BuildContext) == "function" then
        condCtx, tokens = switchCtrl.BuildContext(speaker, addressee, baseCtx)
    else
        condCtx = baseCtx
        tokens = { ["addressee.name"] = addressee.rawName or addressee.name }
    end

    Model.execCounter = Model.execCounter + 1
    local salt = "dbg:" .. poolID .. ":" .. tostring(Model.execCounter)
    local variant = catalog.Select(poolID, condCtx, salt)
    if not variant then
        return { ok = false, reason = "no_matching_variant", poolID = poolID }
    end

    local spokenTurns = {}
    local offersCount = 0
    local plan = type(variant.plan) == "table" and variant.plan or nil
    local offerIDs = {}
    if plan and type(plan.turns) == "table" then
        for _, t in ipairs(plan.turns) do
            for _, off in ipairs(type(t.offers) == "table" and t.offers or {}) do
                local oid = tostring(off.id or off.offerID or "")
                if oid ~= "" then offerIDs[#offerIDs + 1] = oid end
            end
        end
    end

    local deliveryChannel = "none"
    if plan and type(plan.turns) == "table" and #plan.turns > 0 then
        for i = 1, #plan.turns do
            local turn = plan.turns[i]
            local turnActor = selectedActors[((i - 1) % #selectedActors) + 1] or speaker
            local raw = turn.fallback or turn.text or variant.fallback or ""
            local line = lex.Expand(raw, condCtx, tokens, { salt = salt .. ":" .. tostring(i) })
            local _, ch = speakActor(turnActor, line, poolID, salt .. ":t" .. tostring(i), offerIDs, variant.id)
            if ch then deliveryChannel = ch end
            spokenTurns[#spokenTurns + 1] = { speaker = turnActor.name, text = line }
        end
    else
        local line = lex.Expand(variant.fallback or "", condCtx, tokens, { salt = salt })
        local _, ch = speakActor(speaker, line, poolID, salt .. ":t1", offerIDs, variant.id)
        if ch then deliveryChannel = ch end
        spokenTurns[1] = { speaker = speaker.name, text = line }
    end

    local firstText = spokenTurns[1] and spokenTurns[1].text or ""
    local result = {
        ok = true,
        poolID = poolID,
        variantID = tostring(variant.id or "default"),
        speakerName = tostring(speaker.name or speaker.id),
        addresseeName = tostring(addressee.name or addressee.id),
        channel = deliveryChannel,
        text = firstText,
        turnCount = #spokenTurns,
        offersCount = #offerIDs,
        ts = nowMs(),
    }
    Model.RecordExecution(result)
    return result
end

return Model
