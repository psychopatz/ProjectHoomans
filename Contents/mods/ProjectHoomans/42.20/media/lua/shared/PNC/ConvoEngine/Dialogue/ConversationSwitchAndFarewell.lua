-- Unified, actor-agnostic conversation opening, 2-second speaker-switch handoff
-- (with per-actor log preservation & discourse resumption), and standardized
-- goodbye controller shared by Conversation UI, headless inputbox, and NPC scenes.

PNC = PNC or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Controller = PNC.ConvoEngine.ConversationSwitchAndFarewell or {}
PNC.ConvoEngine.ConversationSwitchAndFarewell = Controller

Controller.VERSION = 1
Controller.SWITCH_DELAY_MS = 2000

local Catalog = PNC.ConvoEngine.ResponseCatalog or require "PNC/ConvoEngine/Dialogue/ResponseCatalog"
local Lex = PNC.ConvoEngine.Lexicon or require "PNC/ConvoEngine/Lexicon"
local Patience = PNC.ConvoEngine.PatienceTracker or require "PNC/ConvoEngine/PatienceTracker"

local pendingSwitches = {}
local tickRegistered = false

local function nowMs(explicit)
    local n = tonumber(explicit)
    if n ~= nil then return n end
    if getTimestampMs then
        local ok, val = pcall(getTimestampMs)
        if ok and tonumber(val) ~= nil then return tonumber(val) end
    end
    if PNC.Core and type(PNC.Core.Now) == "function" then
        local ok, val = pcall(PNC.Core.Now)
        if ok and tonumber(val) ~= nil then return tonumber(val) end
    end
    return 0
end

local function copyList(src)
    local out = {}
    if type(src) ~= "table" then return out end
    for i = 1, #src do out[i] = src[i] end
    return out
end

local function resolveIdentityAxes(actor, context)
    actor = type(actor) == "table" and actor or {}
    context = type(context) == "table" and context or {}
    local rawRole = string.lower(tostring(context.actorRole or actor.npcType or actor.role or ""))
    local role = "survivor"
    if rawRole == "trader" or actor.isTrader == true then role = "trader"
    elseif rawRole == "bandit" or rawRole == "raider" or actor.isHostile == true then role = "bandit"
    elseif rawRole == "looter" then role = "looter"
    elseif rawRole == "guard" or rawRole == "soldier" then role = "guard"
    elseif actor.colonist == true or rawRole == "colonist" then role = "colonist"
    elseif actor.isCompanion == true or actor.isPlayerCompanion == true or rawRole == "companion" then role = "companion"
    elseif rawRole ~= "" then role = rawRole end

    local rawBond = string.lower(tostring(
        context.relBond or context.familyRole or actor.familyRole or context.relationshipState or ""
    ))
    local bond = "stranger"
    local kinTitle = context["rel.kin_title"]
    if rawBond == "lover" or rawBond == "partner" or rawBond == "romantic" then bond = "lover"
    elseif rawBond == "spouse" or rawBond == "wife" or rawBond == "husband" then bond = "spouse"
    elseif rawBond == "father" or rawBond == "dad" then bond = "parent"; kinTitle = kinTitle or "Dad"
    elseif rawBond == "mother" or rawBond == "mom" then bond = "parent"; kinTitle = kinTitle or "Mom"
    elseif rawBond == "parent" then
        bond = "parent"
        kinTitle = kinTitle or ((actor.isFemale == true or actor.female == true) and "Mom" or "Dad")
    elseif rawBond == "son" or rawBond == "daughter" or rawBond == "child" then bond = "child"
    elseif rawBond == "brother" or rawBond == "sister" or rawBond == "sibling" then bond = "sibling"
    elseif rawBond == "family" or rawBond == "relative" then bond = "family"
    elseif rawBond == "hostile" or rawBond == "enemy" or rawBond == "rival" then bond = "rival"
    elseif rawBond == "ally" or rawBond == "trusted" or rawBond == "friendly" or rawBond == "friend" or rawBond == "member" then
        bond = "friend"
    end

    local age = tonumber(actor.age or context.actorAge)
    local ageBand = string.lower(tostring(context.actorAgeBand or actor.ageBand or ""))
    if ageBand == "" then
        if age ~= nil then
            if age < 22 then ageBand = "youth"
            elseif age >= 55 then ageBand = "elder"
            else ageBand = "adult" end
        else
            ageBand = "adult"
        end
    end
    return role, bond, kinTitle, ageBand
end

function Controller.BuildContext(actor, partner, baseContext)
    actor = type(actor) == "table" and actor or {}
    partner = type(partner) == "table" and partner or {}
    local ctx = {}
    if type(baseContext) == "table" then
        for k, v in pairs(baseContext) do ctx[k] = v end
    end
    local role, bond, kinTitle, ageBand = resolveIdentityAxes(actor, ctx)
    local pat = type(Patience) == "table" and Patience.Inspect
        and Patience.Inspect(actor.id, partner.id or ctx.characterUUID or "player", ctx.now)
        or { level = "calm", annoyed = false, fedUp = false }
    local md = type(Patience) == "table" and Patience.ResolveMood
        and Patience.ResolveMood(actor, pat) or { primary = "calm" }

    ctx.actorRole = role
    ctx.relBond = bond
    ctx.actorAgeBand = ageBand
    ctx.npcAnnoyance = ctx.npcAnnoyance or pat.level
    ctx.npcAnnoyed = ctx.npcAnnoyed == true or pat.annoyed == true
    ctx.npcFedUp = ctx.npcFedUp == true or pat.fedUp == true
    ctx.moodPrimary = ctx.moodPrimary or md.primary
    ctx.moodPanicked = ctx.moodPanicked == true or md.panicked == true
    ctx.moodInPain = ctx.moodInPain == true or md.inPain == true
    ctx.moodStressed = ctx.moodStressed == true or md.stressed == true
    ctx.moodTired = ctx.moodTired == true or md.tired == true
    ctx.moodUnhappy = ctx.moodUnhappy == true or md.unhappy == true
    ctx.moodBored = ctx.moodBored == true or md.bored == true
    ctx.moodHungry = ctx.moodHungry == true or md.hungry == true
    ctx.moodCheerful = ctx.moodCheerful == true or md.cheerful == true

    local tokens = type(ctx.tokens) == "table" and ctx.tokens or {}
    if partner.name and not tokens["addressee.name"] then
        tokens["addressee.name"] = tostring(partner.name)
    elseif actor.name and not tokens["speaker.name"] then
        tokens["speaker.name"] = tostring(actor.name)
    end
    if kinTitle then tokens["rel.kin_title"] = kinTitle end
    if ctx["state.job"] then tokens["state.job"] = ctx["state.job"] end
    if ctx["place.name"] then tokens["place.name"] = ctx["place.name"] end
    return ctx, tokens
end

local function realizePool(poolID, condCtx, tokens, salt)
    local variant = Catalog.Select(poolID, condCtx, salt)
    if not variant then return "", nil end
    local text = Lex.Expand(variant.fallback or "", condCtx, tokens, { salt = salt })
    return text, variant
end

function Controller.ResolveOpeningLine(session, actor, partner, baseContext, salt)
    local ctx, tokens = Controller.BuildContext(actor, partner, baseContext)
    local actorID = actor and actor.id and tostring(actor.id) or nil
    local paused = type(session) == "table" and type(session.pausedActors) == "table"
        and actorID ~= nil and session.pausedActors[actorID] == true
    local poolID = paused and "semantic.conversation.resume" or "semantic.greeting"
    if paused and type(session.pausedActors) == "table" then
        session.pausedActors[actorID] = nil
    end
    local text, variant = realizePool(poolID, ctx, tokens, salt or ("open:" .. tostring(actorID or "")))
    return text, poolID, variant
end

function Controller.ResolvePauseSwitch(actor, partner, baseContext, salt)
    local ctx, tokens = Controller.BuildContext(actor, partner, baseContext)
    local sayText = realizePool("semantic.conversation.pause_switch.say", ctx, tokens, (salt or "sw") .. ":say")
    local ackText = realizePool("semantic.conversation.pause_switch.ack", ctx, tokens, (salt or "sw") .. ":ack")
    return sayText, ackText
end

function Controller.ResolveFarewell(actor, partner, baseContext, salt)
    local ctx, tokens = Controller.BuildContext(actor, partner, baseContext)
    local playerLine = realizePool("semantic.conversation.farewell.player", ctx, tokens, (salt or "bye") .. ":p")
    local npcReply = realizePool("semantic.conversation.farewell.reply", ctx, tokens, (salt or "bye") .. ":r")
    return {
        playerLine = playerLine,
        npcReply = npcReply,
        choiceSpec = {
            id = "goodbye",
            semanticRole = "farewell",
            isFarewell = true,
            variant = "danger",
            text = playerLine,
            response = npcReply,
            order = 999,
        },
    }
end

local function appendLog(view, speaker, text, speakerKind)
    if type(view) ~= "table" or tostring(text or "") == "" then return end
    if type(view.appendMessage) == "function" then
        pcall(view.appendMessage, view, speaker, text)
    elseif view.session and type(view.session.queueMessage) == "function" then
        pcall(view.session.queueMessage, view.session, speakerKind or "npc", text)
    else
        view.messages = view.messages or {}
        view.messages[#view.messages + 1] = { speaker = speaker, text = text }
    end
end

local function readLogMessages(view)
    if type(view) ~= "table" then return {} end
    if type(view.getMessages) == "function" then
        return copyList(view:getMessages())
    end
    if view.historyPart and type(view.historyPart.messages) == "table" then
        return copyList(view.historyPart.messages)
    end
    return copyList(view.messages)
end

local function writeLogMessages(view, messages)
    if type(view) ~= "table" then return end
    local cloned = copyList(messages)
    if type(view.setMessages) == "function" then
        pcall(view.setMessages, view, cloned)
    elseif view.historyPart and type(view.historyPart.setMessages) == "function" then
        pcall(view.historyPart.setMessages, view.historyPart, cloned)
    else
        view.messages = cloned
    end
end

function Controller.ResolveSpeakerRoster(view)
    local ctx = type(view) == "table" and view.spec and view.spec.context or nil
    local activeID = tostring(
        (view and view.session and view.session.npcID)
        or (view and view.spec and view.spec.npcID)
        or (ctx and ctx.entry and ctx.entry.id)
        or ""
    )
    local roster = {}
    if ctx and type(ctx.speakerRoster) == "table" and #ctx.speakerRoster > 0 then
        roster = ctx.speakerRoster
    elseif view and view.groupConversation and type(view.groupConversation.members) == "table" then
        for _, m in ipairs(view.groupConversation.members) do
            if m and m.entry then roster[#roster + 1] = m.entry end
        end
    elseif PNC.CompanionTargetResolver and type(PNC.CompanionTargetResolver.CollectNearbyTargets) == "function" then
        local player = (ctx and ctx.player) or (getSpecificPlayer and getSpecificPlayer(0)) or (getPlayer and getPlayer()) or nil
        if player then
            local ok, nearby = pcall(PNC.CompanionTargetResolver.CollectNearbyTargets, player)
            if ok and type(nearby) == "table" then
                for _, cand in ipairs(nearby) do
                    if cand and cand.id then roster[#roster + 1] = cand end
                end
            end
        end
    end
    local currentIndex = 1
    if activeID ~= "" then
        for i = 1, #roster do
            if tostring(roster[i] and roster[i].id or "") == activeID then
                currentIndex = i
                break
            end
        end
    end
    return roster, currentIndex
end

local function executeSwitch(req)
    local view = req.view
    local session = req.session
    if type(view) ~= "table" or type(session) ~= "table" then return false end
    session.historyByActor = session.historyByActor or {}
    session.pausedActors = session.pausedActors or {}

    local currentID = tostring(req.fromActorID or "")
    local nextActor = req.toActor
    local nextID = tostring(nextActor and nextActor.id or "")
    if nextID == "" then return false end

    if currentID ~= "" then
        session.historyByActor[currentID] = readLogMessages(view)
        session.pausedActors[currentID] = true
    end

    if type(req.applySwitch) == "function" then
        req.applySwitch(nextActor, req.toIndex)
    end

    local saved = session.historyByActor[nextID]
    if type(saved) == "table" and #saved > 0 then
        writeLogMessages(view, saved)
    else
        writeLogMessages(view, {})
    end

    local line, poolID = Controller.ResolveOpeningLine(
        session, nextActor, req.partner, req.nextContext, "switch:" .. nextID
    )
    if line ~= "" then
        appendLog(view, nextActor.name or nextID, line, "npc")
    end
    session.activeActorID = nextID
    session.pendingSpeakerSwitch = nil
    return true, poolID
end

function Controller.TickPendingSwitches(explicitNow)
    if #pendingSwitches == 0 then return 0 end
    local ts = nowMs(explicitNow)
    local executed = 0
    for i = #pendingSwitches, 1, -1 do
        local req = pendingSwitches[i]
        if ts >= (tonumber(req.executeAt) or 0) then
            table.remove(pendingSwitches, i)
            executeSwitch(req)
            executed = executed + 1
        end
    end
    return executed
end

local function ensureTickHook()
    if tickRegistered then return end
    if Events and Events.OnTick and type(Events.OnTick.Add) == "function" then
        Events.OnTick.Add(function()
            if #pendingSwitches > 0 then
                Controller.TickPendingSwitches()
            end
        end)
        tickRegistered = true
    end
end

function Controller.RequestSpeakerSwitch(view, direction, opts)
    opts = type(opts) == "table" and opts or {}
    if type(view) ~= "table" then return false, "view_unavailable" end
    local session = view.session or opts.session
    if type(session) ~= "table" then
        session = {}
        view.session = session
    end
    local roster = opts.roster
    if type(roster) ~= "table" or #roster < 2 then
        return false, "insufficient_participants"
    end
    local curIdx = tonumber(opts.currentIndex) or 1
    local step = (tonumber(direction) or 1) < 0 and -1 or 1
    local nextIdx = curIdx + step
    if nextIdx < 1 then nextIdx = #roster
    elseif nextIdx > #roster then nextIdx = 1 end

    local curActor = roster[curIdx]
    local nextActor = roster[nextIdx]
    if not nextActor then return false, "target_unavailable" end

    -- Interruptible: if a 2-second handoff is already pending, cancel it and jump immediately.
    if session.pendingSpeakerSwitch then
        for i = #pendingSwitches, 1, -1 do
            if pendingSwitches[i] == session.pendingSpeakerSwitch then
                table.remove(pendingSwitches, i)
            end
        end
        local jumpReq = {
            view = view,
            session = session,
            fromActorID = curActor and curActor.id,
            toActor = nextActor,
            toIndex = nextIdx,
            partner = opts.partner,
            nextContext = opts.nextContext,
            applySwitch = opts.applySwitch,
        }
        return executeSwitch(jumpReq), "switched_immediate"
    end

    local sayLine, ackLine = Controller.ResolvePauseSwitch(
        curActor, opts.partner, opts.currentContext, "sw:" .. tostring(curActor and curActor.id or "")
    )
    appendLog(view, opts.speakerLabel or "YOU", sayLine, "player")
    appendLog(view, (curActor and curActor.name) or "NPC", ackLine, "npc")

    local ts = nowMs(opts.now)
    local delay = tonumber(opts.delayMs) or Controller.SWITCH_DELAY_MS
    local req = {
        view = view,
        session = session,
        fromActorID = curActor and curActor.id,
        toActor = nextActor,
        toIndex = nextIdx,
        partner = opts.partner,
        nextContext = opts.nextContext,
        applySwitch = opts.applySwitch,
        executeAt = ts + delay,
    }
    session.pendingSpeakerSwitch = req
    pendingSwitches[#pendingSwitches + 1] = req
    ensureTickHook()
    return true, "handoff_scheduled"
end

function Controller.TriggerStandardizedGoodbye(view, closeFn, opts)
    opts = type(opts) == "table" and opts or {}
    local session = type(view) == "table" and view.session or opts.session
    if type(session) == "table" and session._farewellTriggered == true then
        if type(closeFn) == "function" then closeFn() end
        return true, "already_triggered"
    end
    if type(session) == "table" then
        session._farewellTriggered = true
        -- Cancel any pending speaker switch on close.
        if session.pendingSpeakerSwitch then
            for i = #pendingSwitches, 1, -1 do
                if pendingSwitches[i] == session.pendingSpeakerSwitch then
                    table.remove(pendingSwitches, i)
                end
            end
            session.pendingSpeakerSwitch = nil
        end
    end

    local fw = Controller.ResolveFarewell(opts.actor, opts.partner, opts.context, opts.salt)
    if type(view) == "table" then
        appendLog(view, opts.speakerLabel or "YOU", fw.playerLine, "player")
        appendLog(view, (opts.actor and opts.actor.name) or "NPC", fw.npcReply, "npc")
    end
    if type(opts.onFarewellLines) == "function" then
        pcall(opts.onFarewellLines, fw.playerLine, fw.npcReply)
    end
    if type(closeFn) == "function" then
        closeFn()
    end
    return true, fw
end

function Controller.Reset()
    pendingSwitches = {}
end

return Controller
