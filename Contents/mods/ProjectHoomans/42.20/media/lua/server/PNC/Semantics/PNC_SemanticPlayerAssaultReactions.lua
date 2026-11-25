-- Semantic reactions for player pushes/strikes on friendlies, provoked neutrals, and looters.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Mod = PNC.Semantics.PlayerAssaultReactions or {}
PNC.Semantics.PlayerAssaultReactions = Mod

Mod.VERSION = 1
Mod.PUSH_DEBOUNCE_MS = 650
Mod.DAILY_PENALTY_THRESHOLD = 3
Mod.DAILY_PENALTY_MAX = 4
Mod.LOOTER_TAUNT_COOLDOWN_MS = 18000
Mod.HOSTILE_HIT_COOLDOWN_MS = 6500

local MAX_COOLDOWN_KEYS = 128

local LOOTER_KEYWORDS = {
    "looter",
    "raider",
    "bandit",
    "scav",
    "marauder",
    "robber",
    "mugger",
    "thug",
}

local pushDebounceAt = {}
local pushDebounceCount = 0
local hostileHitAt = {}
local hostileHitCount = 0
local looterTauntAt = {}
local looterTauntCount = 0

local function safeCall(obj, method, ...)
    if not obj or type(obj[method]) ~= "function" then
        return nil
    end
    local ok, value = pcall(obj[method], obj, ...)
    if ok then
        return value
    end
    return nil
end

local function nowMs(spec)
    if type(spec) == "table" and spec.now ~= nil then
        return tonumber(spec.now) or 0
    end
    if PNC.Core and type(PNC.Core.Now) == "function" then
        return tonumber(PNC.Core.Now()) or 0
    end
    if type(getTimestampMs) == "function" then
        return tonumber(getTimestampMs()) or 0
    end
    return 0
end

local function worldAgeHours()
    local gt = type(getGameTime) == "function" and getGameTime() or nil
    local hours = gt and safeCall(gt, "getWorldAgeHours")
    return tonumber(hours) or 0
end

local function resolvePlayerKey(player)
    local hooks = PNC.SocialEventHooks
    if hooks and type(hooks.ResolvePlayerKey) == "function" then
        local key = hooks.ResolvePlayerKey(player)
        if key ~= nil and tostring(key) ~= "" then
            return tostring(key)
        end
    end
    if PNC.EntityRef and type(PNC.EntityRef.ForPlayer) == "function" then
        local ok, ref = pcall(PNC.EntityRef.ForPlayer, player)
        if ok and ref ~= nil and tostring(ref) ~= "" then
            return tostring(ref)
        end
    end
    local onlineID = safeCall(player, "getOnlineID")
    local username = safeCall(player, "getUsername")
    if username and tostring(username) ~= "" and PNC.EntityRef
        and type(PNC.EntityRef.ForPlayerIdentity) == "function"
    then
        local ok, ref = pcall(PNC.EntityRef.ForPlayerIdentity, username, safeCall(player, "getDescriptorID") or onlineID or "local")
        if ok and ref ~= nil and tostring(ref) ~= "" then
            return tostring(ref)
        end
    end
    return "player:" .. tostring(onlineID or username or "unknown")
end

local function resolveTargetKey(record)
    if PNC.EntityRef and type(PNC.EntityRef.ForNPC) == "function" then
        local ok, ref = pcall(PNC.EntityRef.ForNPC, record.id)
        if ok and ref ~= nil and tostring(ref) ~= "" then
            return tostring(ref)
        end
    end
    return "npc:" .. tostring(record.id)
end

local function checkCooldown(map, count, key, now, cooldownMs)
    local last = map[key]
    if last ~= nil and now >= last and (now - last) < cooldownMs then
        return false, map, count
    end
    if last == nil then
        count = count + 1
        if count > MAX_COOLDOWN_KEYS then
            map = {}
            count = 1
        end
    end
    map[key] = now
    return true, map, count
end

local function hasLooterKeyword(value)
    if type(value) ~= "string" or value == "" then
        return false
    end
    local lower = string.lower(value)
    for i = 1, #LOOTER_KEYWORDS do
        if string.find(lower, LOOTER_KEYWORDS[i], 1, true) then
            return true
        end
    end
    return false
end

local function itemLabel(item, fallback)
    if not item then
        return fallback
    end
    local label = safeCall(item, "getDisplayName") or safeCall(item, "getName")
    if type(label) == "string" and label ~= "" then
        return label
    end
    return fallback
end

local function hashString(text)
    local total = 0
    local str = tostring(text or "")
    for i = 1, #str do
        total = total + string.byte(str, i) * i
    end
    return total
end

function Mod.ResolveDayIndex(spec)
    if type(spec) == "table" and spec.dayIndex ~= nil then
        return math.floor(tonumber(spec.dayIndex) or 0)
    end
    local gt = type(getGameTime) == "function" and getGameTime() or nil
    if gt then
        local days = safeCall(gt, "getWorldAgeDaysSinceBegin")
        if days ~= nil then
            return math.floor(tonumber(days) or 0)
        end
        local hours = safeCall(gt, "getWorldAgeHours")
        if hours ~= nil then
            return math.floor((tonumber(hours) or 0) / 24)
        end
    end
    return 0
end

function Mod.ResolveHostileArchetype(record)
    if type(record) ~= "table" then
        return "hostile"
    end
    local hostility = type(record.hostility) == "table" and record.hostility or nil
    local rt = type(record.runtime) == "table" and record.runtime or nil
    if hostility then
        local origin = tostring(hostility.originTacticalClass or "")
        if hostility.provokedByPlayer == true
            or origin == "neutral"
            or origin == "friendly"
        then
            return "neutral_turned_hostile"
        end
    end
    if rt and tostring(rt.tacticalClassChangedReason or "") == "attacked_by_player" then
        return "neutral_turned_hostile"
    end
    if record.isLooter == true then
        return "looter"
    end
    local fields = {
        record.archetype,
        record.role,
        record.personalityRole,
        record.factionRole,
        record.factionArchetype,
        record.groupArchetype,
        record.hostileArchetype,
        record.factionID,
        record.name,
    }
    for i = 1, #fields do
        if hasLooterKeyword(fields[i]) then
            return "looter"
        end
    end
    if record.factionID and PNC.Factions and type(PNC.Factions.Peek) == "function" then
        local ok, faction = pcall(PNC.Factions.Peek, record.factionID)
        if ok and type(faction) == "table" then
            if hasLooterKeyword(faction.archetype)
                or hasLooterKeyword(faction.role)
                or hasLooterKeyword(faction.groupArchetype)
                or hasLooterKeyword(faction.kind)
                or hasLooterKeyword(faction.name)
            then
                return "looter"
            end
        end
    end
    return "hostile"
end

function Mod.InspectTargetLootHighlight(player, salt)
    if not player then
        return { category = "general", label = "gear" }
    end
    local candidates = {}

    local backSlot = (ItemBodyLocation and ItemBodyLocation.BACK)
        or (not ItemBodyLocation and "Back")
        or nil
    local backpack = safeCall(player, "getClothingItem_Back")
        or (backSlot and safeCall(player, "getWornItem", backSlot))
    if backpack then
        candidates[#candidates + 1] = {
            category = "backpack",
            label = itemLabel(backpack, "backpack"),
        }
    end

    local weapon = safeCall(player, "getPrimaryHandItem")
    if weapon then
        local fullType = tostring(safeCall(weapon, "getFullType") or "")
        if fullType ~= "Base.BareHands" then
            candidates[#candidates + 1] = {
                category = "weapon",
                label = itemLabel(weapon, "weapon"),
            }
        end
    end

    local inv = safeCall(player, "getInventory")
    if inv then
        local hasMoney = safeCall(inv, "containsTypeRecurse", "Base.Money") == true
            or safeCall(inv, "getFirstType", "Base.Money") ~= nil
            or (tonumber(safeCall(inv, "getItemCount", "Base.Money")) or 0) > 0
        if hasMoney then
            candidates[#candidates + 1] = {
                category = "money",
                label = "cash",
            }
        end
    end

    if #candidates == 0 then
        return { category = "general", label = "gear" }
    end
    local idx = (hashString(salt) % #candidates) + 1
    return candidates[idx]
end

local function emitAssaultLine(record, player, spec)
    local reactionService = PNC.SemanticCombatReactionService
        or (PNC.Semantics and PNC.Semantics.CombatReactionService)
        or nil
    if not reactionService or type(reactionService.OnPlayerAssaultedNPC) ~= "function" then
        return 0, "reaction_service_unavailable"
    end
    return reactionService.OnPlayerAssaultedNPC(record, player, spec)
end

function Mod.OnFriendlyPushOrStrike(record, player, spec)
    spec = type(spec) == "table" and spec or {}
    if type(record) ~= "table" or record.alive == false or record.id == nil or not player then
        return false, "invalid_friendly_push_context"
    end
    local now = nowMs(spec)
    local pKey = resolvePlayerKey(player)
    local dKey = tostring(record.id) .. "|" .. tostring(pKey)
    local allowed
    allowed, pushDebounceAt, pushDebounceCount = checkCooldown(
        pushDebounceAt,
        pushDebounceCount,
        dKey,
        now,
        Mod.PUSH_DEBOUNCE_MS
    )
    if not allowed then
        return false, "push_debounced"
    end

    local day = Mod.ResolveDayIndex(spec)
    record.runtime = type(record.runtime) == "table" and record.runtime or {}
    local pushMap = record.runtime.friendlyPushByPlayer
    if type(pushMap) ~= "table" then
        pushMap = {}
        record.runtime.friendlyPushByPlayer = pushMap
    end
    local entry = pushMap[pKey]
    if type(entry) ~= "table" or entry.day ~= day then
        entry = {
            day = day,
            count = 0,
            penaltiesApplied = 0,
            lastAt = now,
        }
        pushMap[pKey] = entry
    end
    entry.count = (tonumber(entry.count) or 0) + 1
    entry.lastAt = now

    local tier = "first"
    if entry.count >= Mod.DAILY_PENALTY_THRESHOLD then
        tier = "penalty"
    elseif entry.count == 2 then
        tier = "warn"
    end

    local penaltyApplied = false
    if entry.count >= Mod.DAILY_PENALTY_THRESHOLD
        and (tonumber(entry.penaltiesApplied) or 0) < Mod.DAILY_PENALTY_MAX
        and PNC.SocialEvents
        and type(PNC.SocialEvents.Emit) == "function"
    then
        entry.penaltiesApplied = (tonumber(entry.penaltiesApplied) or 0) + 1
        local eventSpec = {
            id = "friendly_harass:" .. tostring(record.id)
                .. ":" .. tostring(day) .. ":" .. tostring(entry.count),
            type = "player_harassed_friendly_npc",
            actorKey = pKey,
            targetKey = resolveTargetKey(record),
            occurredAt = tonumber(spec.occurredAt) or worldAgeHours(),
            sourceSystem = "combat",
            x = record.x,
            y = record.y,
            z = record.z,
            context = {
                dayIndex = day,
                pushCount = entry.count,
                isShove = spec.isShove == true,
            },
        }
        local ok, res = pcall(PNC.SocialEvents.Emit, eventSpec)
        if ok and (res == true or (type(res) == "table" and res.accepted ~= false and res.ok ~= false)) then
            penaltyApplied = true
        end
    end

    emitAssaultLine(record, player, {
        assaultKind = "friendly_push",
        friendlyPushTier = tier,
        friendlyPushCount = entry.count,
        isShove = spec.isShove == true,
        weaponFullType = spec.weaponFullType,
        attackType = spec.isShove == true and "shove" or "melee",
        hostilityReason = "friendly_push",
        cooldownMs = tonumber(spec.cooldownMs) or 1500,
        now = now,
        x = record.x,
        y = record.y,
        z = record.z,
    })

    return true, {
        tier = tier,
        count = entry.count,
        day = day,
        penaltyApplied = penaltyApplied,
    }
end

local function emitHostileDialogue(record, player, spec, cooldownType)
    spec = type(spec) == "table" and spec or {}
    if type(record) ~= "table" or record.alive == false or record.id == nil or not player then
        return false, "invalid_hostile_reaction_context"
    end
    local now = nowMs(spec)
    local pKey = resolvePlayerKey(player)
    local cKey = tostring(record.id) .. "|" .. tostring(pKey)
    local allowed
    if cooldownType == "hit" then
        allowed, hostileHitAt, hostileHitCount = checkCooldown(
            hostileHitAt,
            hostileHitCount,
            cKey,
            now,
            tonumber(spec.cooldownMs) or Mod.HOSTILE_HIT_COOLDOWN_MS
        )
    else
        allowed, looterTauntAt, looterTauntCount = checkCooldown(
            looterTauntAt,
            looterTauntCount,
            cKey,
            now,
            tonumber(spec.cooldownMs) or Mod.LOOTER_TAUNT_COOLDOWN_MS
        )
    end
    if not allowed then
        return false, "hostile_reaction_cooldown"
    end

    local archetype = Mod.ResolveHostileArchetype(record)
    if archetype == "neutral_turned_hostile" then
        local sent, reason = emitAssaultLine(record, player, {
            assaultKind = "neutral_turned_hostile",
            attackType = spec.attackType,
            attackKind = spec.attackKind,
            woundType = spec.woundType,
            hostilityReason = "attacked_by_player",
            cooldownMs = tonumber(spec.cooldownMs) or 4500,
            priority = 64,
            now = now,
            x = tonumber(spec.x or record.x),
            y = tonumber(spec.y or record.y),
            z = tonumber(spec.z or record.z),
        })
        return (tonumber(sent) or 0) > 0, reason
    end

    local loot = Mod.InspectTargetLootHighlight(
        player,
        tostring(record.id) .. ":" .. tostring(math.floor(now / 1000))
    )
    local sent, reason = emitAssaultLine(record, player, {
        assaultKind = "looter_taunt",
        lootCategory = loot.category,
        lootItemName = loot.label,
        attackType = spec.attackType,
        attackKind = spec.attackKind,
        woundType = spec.woundType,
        hostilityReason = "looter_ambush",
        cooldownMs = tonumber(spec.cooldownMs) or 4500,
        priority = 64,
        now = now,
        x = tonumber(spec.x or record.x),
        y = tonumber(spec.y or record.y),
        z = tonumber(spec.z or record.z),
    })
    return (tonumber(sent) or 0) > 0, reason
end

function Mod.OnHostileAttackedByPlayer(record, player, spec)
    return emitHostileDialogue(record, player, spec, "hit")
end

function Mod.OnHostileAcquiredPlayer(record, player, spec)
    return emitHostileDialogue(record, player, spec, "acquire")
end

function Mod.ResetRuntime()
    pushDebounceAt = {}
    pushDebounceCount = 0
    hostileHitAt = {}
    hostileHitCount = 0
    looterTauntAt = {}
    looterTauntCount = 0
end

return Mod
