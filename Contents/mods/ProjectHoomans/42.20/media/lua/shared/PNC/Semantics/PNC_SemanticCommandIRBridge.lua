-- Singular Command-to-IR & Dialogue Bridge.
-- Normalizes UI buttons (Colonist Activities, Task tab, Access Inventory),
-- right-click context menu orders, and player emotes into canonical Semantic IR
-- and emits context-aware ConvoDSL acknowledgments through SpeechTransport.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local GrammarJoin = PNC.Semantics.GrammarJoin
    or require "PNC/Semantics/PNC_SemanticGrammarJoin"

local Bridge = PNC.Semantics.CommandIRBridge or {}
PNC.Semantics.CommandIRBridge = Bridge

Bridge.VERSION = 1
Bridge.Commands = Bridge.Commands or {}
Bridge.Emotes = Bridge.Emotes or {}

local COMMAND_COOLDOWN_MS = 2500
local MAX_GROUP_RESPONDERS = 2
local MAX_COOLDOWN_KEYS = 64
local recentEmitAt, recentOrder = {}, {}

local function nowMs(at)
    if at ~= nil then return tonumber(at) or 0 end
    return PNC.Core and type(PNC.Core.Now) == "function" and tonumber(PNC.Core.Now()) or 0
end

local function lruPut(key, val)
    if recentEmitAt[key] == nil then
        while #recentOrder >= MAX_COOLDOWN_KEYS do
            local oldest = table.remove(recentOrder, 1)
            recentEmitAt[oldest] = nil
        end
        recentOrder[#recentOrder + 1] = key
    end
    recentEmitAt[key] = val
end

local function playerDisplayName(player)
    if not player then return "boss" end
    local desc = player.getDescriptor and player:getDescriptor() or nil
    local fore = desc and desc.getForename and tostring(desc:getForename() or "") or ""
    if fore ~= "" then return fore end
    local disp = player.getDisplayName and tostring(player:getDisplayName() or "") or ""
    if disp ~= "" then return disp end
    local uname = player.getUsername and tostring(player:getUsername() or "") or ""
    if uname ~= "" then return uname end
    return "boss"
end

function Bridge.RegisterCommand(commandID, spec)
    local key = string.lower(tostring(commandID or ""))
    if key == "" or type(spec) ~= "table" then return false end
    Bridge.Commands[key] = {
        action = tostring(spec.action or string.upper(key)),
        intent = tostring(spec.intent or "REQUEST"),
        speechAct = tostring(spec.speechAct or "REQUEST"),
        role = tostring(spec.role or ("ack_" .. key)),
        rejectRole = tostring(spec.rejectRole or "reject_generic"),
        topic = tostring(spec.topic or "command_ack"),
        priority = tonumber(spec.priority) or 56,
    }
    return true
end

function Bridge.RegisterEmote(emoteID, spec)
    local key = string.lower(tostring(emoteID or ""))
    if key == "" or type(spec) ~= "table" then return false end
    Bridge.Emotes[key] = {
        action = tostring(spec.action or string.upper(key)),
        intent = tostring(spec.intent or "SOCIAL"),
        speechAct = tostring(spec.speechAct or "REACT"),
        role = tostring(spec.role or ("emote_" .. key)),
        topic = tostring(spec.topic or "emote_reaction"),
        priority = tonumber(spec.priority) or 52,
    }
    return true
end

-- Register all Colonist Activities, Task commands, and Right-Click orders.
local DEFAULT_COMMANDS = {
    follow               = { action = "FOLLOW",          role = "ack_follow" },
    manual_follow        = { action = "FOLLOW",          role = "ack_follow" },
    stay                 = { action = "STAY",            role = "ack_stay" },
    wait                 = { action = "STAY",            role = "ack_stay" },
    hold                 = { action = "STAY",            role = "ack_stay" },
    stop                 = { action = "STAY",            role = "ack_stay" },
    wait_at              = { action = "WAIT_AT",         role = "ack_wait_at" },
    guard                = { action = "GUARD",           role = "ack_guard" },
    patrol               = { action = "PATROL",          role = "ack_patrol" },
    camp                 = { action = "CAMP",            role = "ack_camp" },
    return_home          = { action = "CAMP",            role = "ack_camp" },
    go_home              = { action = "CAMP",            role = "ack_camp" },
    eat                  = { action = "EAT",             role = "ack_eat" },
    manual_eat           = { action = "EAT",             role = "ack_eat" },
    drink                = { action = "DRINK",           role = "ack_drink" },
    manual_drink         = { action = "DRINK",           role = "ack_drink" },
    refill_water         = { action = "REFILL_WATER",    role = "ack_refill_water" },
    manual_refill_water  = { action = "REFILL_WATER",    role = "ack_refill_water" },
    sleep                = { action = "SLEEP",           role = "ack_sleep" },
    manual_sleep         = { action = "SLEEP",           role = "ack_sleep" },
    sleep_on             = { action = "SLEEP",           role = "ack_sleep" },
    sleep_off            = { action = "WAKE",            role = "ack_wake" },
    wake                 = { action = "WAKE",            role = "ack_wake" },
    grab_provision       = { action = "FETCH_PROVISION", role = "ack_provision" },
    manual_grab_provision= { action = "FETCH_PROVISION", role = "ack_provision" },
    corpse_haul          = { action = "HAUL_CORPSES",    role = "ack_corpse_haul" },
    grab_corpses         = { action = "HAUL_CORPSES",    role = "ack_corpse_haul" },
    manual_corpse_haul   = { action = "HAUL_CORPSES",    role = "ack_corpse_haul" },
    access_inventory     = { action = "OPEN_INVENTORY",  role = "ack_inventory" },
    scavenge             = { action = "SCAVENGE",        role = "ack_scavenge" },
    scavenge_nearby      = { action = "SCAVENGE",        role = "ack_scavenge" },
    loot                 = { action = "SCAVENGE",        role = "ack_scavenge" },
    lumber               = { action = "LUMBER",          role = "ack_lumber" },
    fishing              = { action = "FISH",            role = "ack_fish" },
    heal                 = { action = "HEAL",            role = "ack_heal" },
    bandage              = { action = "HEAL",            role = "ack_heal" },
    assign_task          = { action = "ASSIGN_TASK",     role = "ack_task" },
}
for k, v in pairs(DEFAULT_COMMANDS) do Bridge.RegisterCommand(k, v) end

-- Register vanilla player emotes onto the same IR pipeline.
local DEFAULT_EMOTES = {
    wavehi     = { action = "GREET",    intent = "GREET",   speechAct = "GREET",    role = "emote_wavehi" },
    wavebye    = { action = "FAREWELL", intent = "FAREWELL",speechAct = "FAREWELL", role = "emote_wavebye" },
    followme   = { action = "FOLLOW",   intent = "REQUEST", speechAct = "REQUEST",  role = "ack_follow" },
    comehere   = { action = "FOLLOW",   intent = "REQUEST", speechAct = "REQUEST",  role = "ack_follow" },
    stop       = { action = "STAY",     intent = "REQUEST", speechAct = "REQUEST",  role = "ack_stay" },
    freeze     = { action = "STAY",     intent = "REQUEST", speechAct = "REQUEST",  role = "ack_stay" },
    shhh       = { action = "QUIET",    intent = "REQUEST", speechAct = "REQUEST",  role = "emote_shhh" },
    thankyou   = { action = "THANK",    intent = "THANK",   speechAct = "THANK",    role = "emote_thankyou" },
    thumbsup   = { action = "PRAISE",   intent = "PRAISE",  speechAct = "PRAISE",   role = "emote_thumbsup" },
    thumbsdown = { action = "DISAGREE", intent = "DISAGREE",speechAct = "DISAGREE", role = "emote_thumbsdown" },
    salute     = { action = "SALUTE",   intent = "GREET",   speechAct = "GREET",    role = "emote_salute" },
    clap       = { action = "PRAISE",   intent = "PRAISE",  speechAct = "PRAISE",   role = "emote_thumbsup" },
    insult     = { action = "INSULT",   intent = "INSULT",  speechAct = "INSULT",   role = "emote_insult" },
}
for k, v in pairs(DEFAULT_EMOTES) do Bridge.RegisterEmote(k, v) end

function Bridge.BuildIRFromCommand(commandID, opts)
    opts = type(opts) == "table" and opts or {}
    local key = string.lower(tostring(commandID or ""))
    local spec = Bridge.Commands[key] or {
        action = string.upper(key ~= "" and key or "COMMAND"),
        intent = "REQUEST",
        speechAct = "REQUEST",
        role = "ack_generic",
        rejectRole = "reject_generic",
        topic = "command_ack",
        priority = 55,
    }
    local target = opts.target and GrammarJoin.FormatTargetWithArticle(opts.target) or nil
    return {
        intent = spec.intent,
        speechAct = spec.speechAct,
        action = spec.action,
        target = target,
        confidence = 1.0,
        provenance = {
            provider = "command_bridge",
            source = tostring(opts.source or "ui_command"),
            commandID = key,
        },
        extensions = {
            audienceScope = opts.audienceScope or { scope = opts.isGroup and "GROUP" or "INDIVIDUAL" },
            commandRole = spec.role,
            rejectRole = spec.rejectRole,
            topic = spec.topic,
            priority = spec.priority,
        },
    }
end

function Bridge.BuildIRFromEmote(emoteID, opts)
    opts = type(opts) == "table" and opts or {}
    local key = string.lower(tostring(emoteID or ""))
    local spec = Bridge.Emotes[key]
    if not spec then return nil end
    return {
        intent = spec.intent,
        speechAct = spec.speechAct,
        action = spec.action,
        confidence = 1.0,
        provenance = {
            provider = "emote_bridge",
            source = tostring(opts.source or "player_emote"),
            emoteID = key,
        },
        extensions = {
            audienceScope = opts.audienceScope or { scope = opts.isGroup and "GROUP" or "INDIVIDUAL" },
            commandRole = spec.role,
            rejectRole = "reject_generic",
            topic = spec.topic,
            priority = spec.priority,
        },
    }
end

local function resolveRecord(target)
    if type(target) == "table" and target.id ~= nil then return target end
    local reg = PNC.Registry
    if reg and type(reg.Get) == "function" and target ~= nil then
        return reg.Get(target)
    end
    return nil
end

function Bridge.EmitIRFeedback(player, ir, targets, outcome, opts)
    if type(ir) ~= "table" then return 0 end
    opts = type(opts) == "table" and opts or {}
    local Transport = PNC.Semantics and PNC.Semantics.SpeechTransport or nil
    if not Transport or type(Transport.ResolveLine) ~= "function" or type(Transport.Deliver) ~= "function" then
        return 0
    end
    local now = nowMs(opts.now)
    local ext = type(ir.extensions) == "table" and ir.extensions or {}
    local isRejected = (outcome == "rejected" or outcome == false)
    local role = isRejected and tostring(ext.rejectRole or "reject_generic")
        or tostring(ext.commandRole or "ack_generic")
    local topic = tostring(ext.topic or "command_ack")
    local addrName = playerDisplayName(player)
    local list = {}
    if type(targets) == "table" and targets.id ~= nil then
        list[1] = targets
    elseif type(targets) == "table" then
        for i = 1, #targets do list[#list + 1] = targets[i] end
    elseif targets ~= nil then
        list[1] = targets
    end

    local delivered = 0
    local maxResp = tonumber(opts.maxResponders) or MAX_GROUP_RESPONDERS
    for i = 1, #list do
        if delivered >= maxResp then break end
        local rec = resolveRecord(list[i])
        if rec and rec.alive ~= false and rec.id ~= nil then
            local cdKey = tostring(rec.id) .. ":" .. tostring(ir.action or "") .. ":" .. tostring(role)
            if now >= (tonumber(recentEmitAt[cdKey]) or 0) then
                local tokens = {
                    ["addressee.name"] = addrName,
                    ["slot.target"] = tostring(ir.target or "there"),
                    ["slot.task"] = tostring(opts.taskLabel or ir.action or "task"),
                }
                local ctx = {
                    beatRole = role,
                    commandRole = role,
                    action = ir.action,
                    topic = topic,
                    inCombat = false,
                }
                local ref = "cmdack:" .. tostring(rec.id) .. ":" .. tostring(math.floor(now)) .. ":" .. tostring(role)
                local text, res = Transport.ResolveLine(rec, {
                    eventType = "command_ack",
                    eventID = ref,
                    act = isRejected and "REFUSE" or "ACK",
                    topic = topic,
                    poolID = "semantic.command.ack",
                    role = role,
                    tokens = tokens,
                    context = ctx,
                    inCombat = false,
                })
                if text then
                    text = GrammarJoin.CleanSurface(text)
                    local sent = Transport.Deliver(rec, now + (delivered * 900), {
                        eventType = "command_ack",
                        speechEventID = res and res.realizationID or ("semantic.command.ack." .. role),
                        act = isRejected and "REFUSE" or "ACK",
                        domain = "social",
                        topic = topic,
                        channel = "social",
                        family = "command_ack_" .. string.lower(tostring(ir.action or "cmd")),
                        priority = tonumber(ext.priority) or 56,
                        priorityHoldMs = 1000,
                        cooldownMs = 1500,
                        familyCooldownMs = 1500,
                        ttlMs = 7000,
                        clientCooldowns = { familyMs = 1200, speakerMs = 1500, ambientMs = 300, mergeWindowMs = 0 },
                        responsePlanID = res and res.responsePlanID or nil,
                        realizationID = res and res.realizationID or nil,
                        poolID = res and res.poolID or "semantic.command.ack",
                        lightweightBark = true,
                        observerOnly = true,
                        eventRef = ref,
                        threadID = ref,
                        streamKey = "cmdack:" .. tostring(rec.id),
                        text = text,
                        presentationClass = res and res.presentationClass or "BARK",
                        context = ctx,
                    })
                    if (tonumber(sent) or 0) > 0 then
                        lruPut(cdKey, now + COMMAND_COOLDOWN_MS)
                        delivered = delivered + 1
                    end
                end
            end
        end
    end
    return delivered
end

function Bridge.EmitCommandFeedback(player, commandID, targets, outcome, opts)
    local ir = Bridge.BuildIRFromCommand(commandID, opts)
    return Bridge.EmitIRFeedback(player, ir, targets, outcome, opts)
end

function Bridge.EmitEmoteFeedback(player, emoteID, targets, opts)
    local ir = Bridge.BuildIRFromEmote(emoteID, opts)
    if not ir then return 0 end
    return Bridge.EmitIRFeedback(player, ir, targets, "accepted", opts)
end

function Bridge.ResetRuntime()
    recentEmitAt, recentOrder = {}, {}
end

return Bridge
