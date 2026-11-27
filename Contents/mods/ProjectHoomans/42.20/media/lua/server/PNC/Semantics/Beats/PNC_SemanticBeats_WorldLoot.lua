-- Semantic DialogueBeats integration for unified opportunistic looting:
--   * MarketSense-aware "just found" discovery lines (price/value, quality/condition,
--     treat/comfort food, item category, and container/location source).
--   * Stealth stealing lines (unseen looter inside a protected safe zone).
--   * Witnessed safe-zone theft confrontations using PNC.ActorReference pronouns & name gating.
--   * Pack-full callouts and looted sustenance consumption.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.Semantics.DialogueBeats = PNC.Semantics.DialogueBeats or {}

local Beats = PNC.Semantics.DialogueBeats
local LOOT_POOL = "semantic.social.world_loot"

local PICKUP_COOLDOWN_MS = 35000
local STEAL_SOLO_COOLDOWN_MS = 25000
local PACK_FULL_COOLDOWN_MS = 60000
local THEFT_COOLDOWN_MS = 12000
local SUSTENANCE_COOLDOWN_MS = 45000

local HIGH_VALUE_PRICE = 120
local PRISTINE_CONDITION = 0.85
local WORN_CONDITION = 0.35

local TREAT_KEYWORDS = {
    "icecream", "chocolate", "candy", "lollipop", "cake",
    "donut", "cookie", "cupcake", "brownie", "gummy", "mintcandy",
}

local SOURCE_PHRASES = {
    shelves = "on the shelf",
    shelf = "on the shelf",
    fridge = "in the fridge",
    freezer = "in the freezer",
    crate = "in the crate",
    counter = "in the counter",
    cabinet = "in the cabinet",
    wardrobe = "in the wardrobe",
    locker = "in the locker",
    desk = "in the desk",
    bin = "in the bin",
    bag = "in a bag",
    floor = "on the floor",
    corpse = "on a body",
}

local function actorRef()
    return PNC.ActorReference or (PNC.Semantics and PNC.Semantics.ActorReference)
end

local function readMethod(obj, method)
    if type(obj) ~= "table" and type(obj) ~= "userdata" then return nil end
    local fn = obj[method]
    if type(fn) ~= "function" then return nil end
    local ok, val = pcall(fn, obj)
    return ok and val or nil
end

local function humanizeItemName(fullType, item)
    local disp = readMethod(item, "getDisplayName") or (type(item) == "table" and item.displayName)
    if disp and tostring(disp) ~= "" then
        return string.lower(tostring(disp))
    end
    local s = tostring(fullType or "supplies")
    local short = string.match(s, "[^%.]+$") or s
    short = string.gsub(short, "(%l)(%u)", "%1 %2")
    short = string.gsub(short, "_", " ")
    return string.lower(short)
end

local function resolveSourcePhrase(target)
    if type(target) ~= "table" then return "nearby" end
    if target.kind == "floor" then return SOURCE_PHRASES.floor end
    if target.kind == "corpse" then return SOURCE_PHRASES.corpse end
    local cType = readMethod(target.container, "getType")
        or (type(target.container) == "table" and target.container.type)
        or target.containerType
    if cType and tostring(cType) ~= "" then
        local key = string.lower(tostring(cType))
        if SOURCE_PHRASES[key] then return SOURCE_PHRASES[key] end
        return "in the " .. string.gsub(key, "_", " ")
    end
    return "in a container"
end

local function isTreatItem(fullType, facts)
    if type(facts) == "table" then
        if facts.marketRole == "candy" or facts.subcategoryKey == "candy"
            or facts.subcategoryKey == "dessert" or facts.subcategoryKey == "sweets"
        then
            return true
        end
        local ts = type(facts.tagSet) == "table" and facts.tagSet or nil
        if ts and (ts.candy or ts.dessert or ts.icecream or ts.chocolate or ts.sweet or ts.treat) then
            return true
        end
    end
    local low = string.lower(tostring(fullType or ""))
    for i = 1, #TREAT_KEYWORDS do
        if string.find(low, TREAT_KEYWORDS[i], 1, true) then
            return true
        end
    end
    return false
end

local function resolveMarketSenseFacts(fullType, item)
    local adapter = PNC.Gifts and PNC.Gifts.Foundation and PNC.Gifts.Foundation.MarketSenseAdapter or nil
    if adapter and type(adapter.BuildFacts) == "function" then
        local ok, facts = pcall(adapter.BuildFacts, fullType, item)
        if ok and type(facts) == "table" then
            return facts
        end
    end
    -- Direct MarketSense or lightweight item fallback
    local price = 0
    if MarketSense and type(MarketSense.GetPrice) == "function" then
        local okP, p = pcall(MarketSense.GetPrice, fullType, item)
        if okP and tonumber(p) then price = tonumber(p) end
    elseif type(item) == "table" and tonumber(item.price) then
        price = tonumber(item.price)
    end
    local cond = nil
    local cCur = readMethod(item, "getCondition")
    local cMax = readMethod(item, "getConditionMax")
    if tonumber(cCur) and tonumber(cMax) and tonumber(cMax) > 0 then
        cond = tonumber(cCur) / tonumber(cMax)
    elseif type(item) == "table" and tonumber(item.condition) then
        cond = tonumber(item.condition)
    end
    return {
        price = price,
        condition = cond,
        marketRole = type(item) == "table" and item.marketRole or nil,
        tagSet = type(item) == "table" and type(item.tagSet) == "table" and item.tagSet or {},
    }
end

-- Resolves the best ConvoDSL role & rich tokens from MarketSense price, quality,
-- treat/comfort status, category, and container source.
function Beats.DescribeLootContext(item, desc, target)
    local fullType = (desc and desc.fullType) or (target and target.fullType)
        or readMethod(item, "getFullType") or (type(item) == "table" and item.fullType) or ""
    local category = string.lower(tostring((desc and desc.category) or (target and target.category) or ""))
    local facts = resolveMarketSenseFacts(fullType, item)
    local price = tonumber(facts and facts.price) or 0
    local cond = facts and tonumber(facts.condition) or nil
    local treat = isTreatItem(fullType, facts)

    local role = "loot_found_general"
    if treat then
        role = "loot_found_treat"
    elseif price >= HIGH_VALUE_PRICE then
        role = "loot_found_jackpot"
    elseif cond ~= nil and (category == "weapons" or category == "tools" or category == "clothing") then
        if cond >= PRISTINE_CONDITION then
            role = "loot_found_pristine"
        elseif cond <= WORN_CONDITION then
            role = "loot_found_worn"
        end
    elseif category == "food" then
        role = "loot_found_food"
    elseif category == "water" then
        role = "loot_found_water"
    elseif category == "medical" then
        role = "loot_found_medical"
    elseif category == "ammo" then
        role = "loot_found_ammo"
    end

    return {
        role = role,
        price = price,
        condition = cond,
        isTreat = treat,
        isHighValue = price >= HIGH_VALUE_PRICE,
        tokens = {
            ["slot.item"] = humanizeItemName(fullType, item),
            ["slot.source"] = resolveSourcePhrase(target),
        },
    }
end

local hooksRegistered = false

local function ensureHooksRegistered()
    if hooksRegistered then return true end
    local b = PNC.Semantics and PNC.Semantics.DialogueBeats or Beats
    if type(b) ~= "table" or type(b.RegisterHook) ~= "function" then
        return false
    end
    hooksRegistered = true
    b.RegisterHook("ambient.world_loot_pickup", {
        eventTypes = { "ambient.world_loot_pickup" },
        priority = 26,
        cooldownMs = PICKUP_COOLDOWN_MS,
        evaluate = function(_, payload)
            if type(b.BuildWorldThread) ~= "function" then return nil end
            local a = payload and payload.anchor
            if type(a) ~= "table" then return nil end
            return b.BuildWorldThread(a, nil, {
                refPrefix = "loot_found:" .. tostring(a.id or "npc"),
                family = "npc_world_loot_found",
                poolID = LOOT_POOL,
                eventType = "ambient_world_loot_pickup",
                domain = "social",
                channel = "social",
                topic = "world_loot_pickup",
                openAct = "INFORM",
                openRole = tostring(payload.openRole or "loot_found_general"),
                priority = 26,
                tokens = payload.tokens,
                context = { topic = "world_loot_pickup" },
            })
        end,
    })

    b.RegisterHook("ambient.world_loot_steal_solo", {
        eventTypes = { "ambient.world_loot_steal_solo" },
        priority = 32,
        cooldownMs = STEAL_SOLO_COOLDOWN_MS,
        evaluate = function(_, payload)
            if type(b.BuildWorldThread) ~= "function" then return nil end
            local a = payload and payload.anchor
            if type(a) ~= "table" then return nil end
            return b.BuildWorldThread(a, nil, {
                refPrefix = "loot_steal:" .. tostring(a.id or "npc"),
                family = "npc_world_loot_steal",
                poolID = LOOT_POOL,
                eventType = "ambient_world_loot_steal_solo",
                domain = "social",
                channel = "social",
                topic = "world_loot_steal",
                openAct = "INFORM",
                openRole = tostring(payload.openRole or "loot_steal_sneaky"),
                priority = 32,
                tokens = payload.tokens,
                context = { topic = "world_loot_steal" },
            })
        end,
    })

    b.RegisterHook("ambient.world_loot_pack_full", {
        eventTypes = { "ambient.world_loot_pack_full" },
        priority = 30,
        cooldownMs = PACK_FULL_COOLDOWN_MS,
        evaluate = function(_, payload)
            if type(b.BuildWorldThread) ~= "function" then return nil end
            local a = payload and payload.anchor
            if type(a) ~= "table" then return nil end
            return b.BuildWorldThread(a, nil, {
                refPrefix = "loot_full:" .. tostring(a.id or "npc"),
                family = "npc_world_loot_pack_full",
                poolID = LOOT_POOL,
                eventType = "ambient_world_loot_pack_full",
                domain = "social",
                channel = "social",
                topic = "world_loot_pack_full",
                openAct = "INFORM",
                openRole = "loot_pack_full",
                priority = 30,
                tokens = payload.tokens,
                context = { topic = "world_loot_pack_full" },
            })
        end,
    })

    b.RegisterHook("ambient.world_loot_sustenance", {
        eventTypes = { "ambient.world_loot_sustenance" },
        priority = 22,
        cooldownMs = SUSTENANCE_COOLDOWN_MS,
        evaluate = function(_, payload)
            if type(b.BuildWorldThread) ~= "function" then return nil end
            local a = payload and payload.anchor
            if type(a) ~= "table" then return nil end
            return b.BuildWorldThread(a, nil, {
                refPrefix = "loot_eat:" .. tostring(a.id or "npc"),
                family = "npc_world_loot_sustenance",
                poolID = LOOT_POOL,
                eventType = "ambient_world_loot_sustenance",
                domain = "social",
                channel = "social",
                topic = "world_loot_sustenance",
                openAct = "INFORM",
                openRole = tostring(payload.openRole or "sustenance_eat"),
                priority = 22,
                tokens = payload.tokens,
                context = { topic = "world_loot_sustenance" },
            })
        end,
    })

    b.RegisterHook("ambient.world_loot_theft", {
        eventTypes = { "ambient.world_loot_theft" },
        priority = 70,
        cooldownMs = THEFT_COOLDOWN_MS,
        evaluate = function(_, payload)
            if type(b.BuildWorldThread) ~= "function" then return nil end
            local witness = payload and payload.anchor
            local thief = payload and payload.partner
            if type(witness) ~= "table" then return nil end
            return b.BuildWorldThread(witness, type(thief) == "table" and thief or nil, {
                refPrefix = "loot_theft:" .. tostring(witness.id or "w") .. ":" .. tostring(thief and thief.id or "t"),
                family = "npc_world_loot_theft",
                poolID = LOOT_POOL,
                eventType = "ambient_world_loot_theft",
                domain = "social",
                channel = "social",
                topic = "world_loot_theft",
                openAct = "STOP",
                openRole = "theft_witness_challenge",
                replyAct = type(thief) == "table" and "REFUSE" or nil,
                replyRole = type(thief) == "table" and "theft_looter_reply" or nil,
                delayMs = 1500,
                priority = 70,
                tokens = payload.tokens,
                context = { topic = "world_loot_theft" },
            })
        end,
    })
    return true
end

ensureHooksRegistered()

function Beats.EmitWorldLootPickup(record, desc, nowMs, target)
    ensureHooksRegistered()
    local b = PNC.Semantics and PNC.Semantics.DialogueBeats or Beats
    if type(record) ~= "table" or type(b.Emit) ~= "function" then return false end
    local ctx = Beats.DescribeLootContext(target and target.item or nil, desc, target)
    return b.Emit("ambient.world_loot_pickup", {
        anchor = record,
        openRole = ctx.role,
        tokens = ctx.tokens,
        price = ctx.price,
        isTreat = ctx.isTreat,
    }, nowMs)
end

function Beats.EmitWorldLootStealSolo(record, desc, nowMs, target)
    ensureHooksRegistered()
    local b = PNC.Semantics and PNC.Semantics.DialogueBeats or Beats
    if type(record) ~= "table" or type(b.Emit) ~= "function" then return false end
    local ctx = Beats.DescribeLootContext(target and target.item or nil, desc, target)
    local role = ctx.isHighValue and "loot_steal_high_value" or "loot_steal_sneaky"
    return b.Emit("ambient.world_loot_steal_solo", {
        anchor = record,
        openRole = role,
        tokens = ctx.tokens,
        price = ctx.price,
    }, nowMs)
end

function Beats.EmitWorldLootPackFull(record, leaderActor, nowMs)
    ensureHooksRegistered()
    local b = PNC.Semantics and PNC.Semantics.DialogueBeats or Beats
    if type(record) ~= "table" or type(b.Emit) ~= "function" then return false end
    local ref = actorRef()
    local addr = "boss"
    if ref and type(ref.NameFor) == "function" and leaderActor then
        addr = ref.NameFor(record, leaderActor, { role = "vocative", unknownAddress = "friend" })
    end
    return b.Emit("ambient.world_loot_pack_full", {
        anchor = record,
        tokens = {
            ["addressee.name"] = addr,
        },
    }, nowMs)
end

function Beats.EmitWorldLootSustenance(record, needType, itemFullType, nowMs)
    ensureHooksRegistered()
    local b = PNC.Semantics and PNC.Semantics.DialogueBeats or Beats
    if type(record) ~= "table" or type(b.Emit) ~= "function" then return false end
    local role = (needType == "thirst" or needType == "water") and "sustenance_drink" or "sustenance_eat"
    return b.Emit("ambient.world_loot_sustenance", {
        anchor = record,
        openRole = role,
        tokens = {
            ["slot.item"] = humanizeItemName(itemFullType, nil),
        },
    }, nowMs)
end

function Beats.EmitWorldLootTheft(witness, thief, itemFullType, nowMs, target)
    ensureHooksRegistered()
    local b = PNC.Semantics and PNC.Semantics.DialogueBeats or Beats
    if type(witness) ~= "table" or type(thief) ~= "table" or type(b.Emit) ~= "function" then
        return false
    end
    local ref = actorRef()
    local tokens = {
        ["slot.item"] = humanizeItemName(itemFullType, target and target.item or nil),
        ["slot.source"] = resolveSourcePhrase(target),
        ["addressee.name"] = "thief",
        ["thief.name"] = "that thief",
        ["thief.subj"] = "they",
        ["thief.Subj"] = "They",
        ["thief.obj"] = "them",
        ["thief.poss"] = "their",
        ["thief.Poss"] = "Their",
    }
    if ref and type(ref.BuildTokens) == "function" then
        local built = ref.BuildTokens(witness, thief, "thief", {
            role = "reference",
            unknownReference = "that thief",
        })
        for k, v in pairs(built) do tokens[k] = v end
    end
    if ref and type(ref.NameFor) == "function" then
        tokens["addressee.name"] = ref.NameFor(witness, thief, {
            role = "vocative",
            unknownAddress = "thief",
        })
    end
    return b.Emit("ambient.world_loot_theft", {
        anchor = witness,
        partner = thief,
        tokens = tokens,
    }, nowMs)
end

return Beats
