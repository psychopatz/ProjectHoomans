-- Dual-actor partner state and O(1) relationship providers for BeatContext.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local BC = PNC.Semantics.BeatContext or {}
PNC.Semantics.BeatContext = BC

local function safeCall(obj, method, ...)
    if not obj or type(obj[method]) ~= "function" then return nil end
    local ok, val = pcall(obj[method], obj, ...)
    return ok and val or nil
end

local function isPlayerObject(actor, opts)
    if opts and opts.addresseeIsPlayer == true then return true end
    if actor == nil then return false end
    if type(instanceof) == "function" and instanceof(actor, "IsoPlayer") == true then
        return true
    end
    if type(actor) == "table" then
        if actor.isPlayer == true then return true end
        if actor.id == nil and (type(actor.getUsername) == "function" or type(actor.getDescriptor) == "function") then
            return true
        end
    end
    return false
end

local function extractPlayerName(player)
    if type(player) == "table" and type(player.name) == "string" and player.name ~= "" then
        return player.name
    end
    local desc = safeCall(player, "getDescriptor")
    local forename = desc and safeCall(desc, "getForename") or nil
    if type(forename) == "string" and forename ~= "" then return forename end
    local display = safeCall(player, "getDisplayName")
    if type(display) == "string" and display ~= "" then return display end
    local user = safeCall(player, "getUsername")
    if type(user) == "string" and user ~= "" then return user end
    return nil
end

local function buildPlayerPartnerStats(player)
    local stats = safeCall(player, "getStats")
    local body = safeCall(player, "getBodyDamage")
    local fatigue = tonumber(stats and safeCall(stats, "getFatigue")) or 0
    local panic = tonumber(stats and safeCall(stats, "getPanic")) or 0
    local stress = tonumber(stats and safeCall(stats, "getStress")) or 0
    local pain = tonumber(stats and safeCall(stats, "getPain")) or 0
    local health = tonumber(body and safeCall(body, "getOverallBodyHealth"))
    local hpRatio = health and math.max(0, math.min(1, health / 100)) or 1
    local bleed = tonumber(body and safeCall(body, "getNumPartsBleeding")) or 0
    local bleeding = bleed > 0
    local isInjured = bleeding or hpRatio < 0.75 or pain >= 40
    local isExhausted = fatigue >= 0.75 or isInjured
    return {
        isPlayer = true,
        name = extractPlayerName(player),
        style = isExhausted and "exhausted" or "neutral",
        styleProfile = "default",
        bravery = 0.5,
        aggression = 0.5,
        compassion = 0.5,
        panic = panic,
        stress = stress,
        fatigue = fatigue,
        pain = pain,
        bleeding = bleeding,
        hpRatio = hpRatio,
        isInjured = isInjured,
        isExhausted = isExhausted,
    }
end

local function isCompanionRecord(rec)
    if type(rec) ~= "table" then return false end
    if rec.isCompanion == true or rec.isPlayerCompanion == true or rec.colonist == true then
        return true
    end
    local owner = rec.ownerKey or rec.owner or rec.playerOwner
    if owner ~= nil and tostring(owner) ~= "" then return true end
    local fac = PNC.Factions
    if fac and type(fac.IsPlayerFaction) == "function" and rec.factionID ~= nil then
        local ok, res = pcall(fac.IsPlayerFaction, rec.factionID)
        if ok and res == true then return true end
    end
    return false
end

local function resolvePartnerKey(addressee, opts)
    if type(opts) == "table" and opts.partnerKey ~= nil and tostring(opts.partnerKey) ~= "" then
        return tostring(opts.partnerKey)
    end
    if isPlayerObject(addressee, opts) then
        local hooks = PNC.SocialEventHooks
        if hooks and type(hooks.ResolvePlayerKey) == "function" then
            local ok, key = pcall(hooks.ResolvePlayerKey, addressee)
            if ok and key and tostring(key) ~= "" then return tostring(key) end
        end
        local er = PNC.EntityRef
        if er and type(er.ForPlayer) == "function" then
            local ok, key = pcall(er.ForPlayer, addressee)
            if ok and key and tostring(key) ~= "" then return tostring(key) end
        end
        local uid = safeCall(addressee, "getUsername") or safeCall(addressee, "getOnlineID")
        return uid ~= nil and ("player:" .. tostring(uid)) or nil
    end
    if type(addressee) == "table" and addressee.id ~= nil then
        local er = PNC.EntityRef
        if er and type(er.ForNPC) == "function" then
            return tostring(er.ForNPC(addressee.id))
        end
        return "npc:" .. tostring(addressee.id)
    end
    return nil
end

local function classifyTier(rel, sameFaction, isHostile)
    if isHostile then return "hostile" end
    if type(rel) ~= "table" then
        return sameFaction and "ally" or "stranger"
    end
    local state = string.lower(tostring(rel.state or ""))
    if state == "hostile" or state == "enemy" or state == "rival" then return "hostile" end
    if state == "ally" or state == "close_friend" or state == "lover" or state == "partner" then
        return "ally"
    end
    local trust = tonumber(rel.trust) or 0
    local approval = tonumber(rel.approval) or tonumber(rel.affinity) or 0
    local familiarity = tonumber(rel.familiarity) or 0
    if approval <= -25 or trust <= -25 then return "hostile" end
    if approval <= -8 or trust <= -8 then return "wary" end
    if sameFaction or approval >= 45 or trust >= 45 then return "ally" end
    if approval >= 25 or trust >= 25 then return "trusted" end
    if approval >= 10 or trust >= 10 then return "friendly" end
    if familiarity >= 5 or state == "acquaintance" then return "acquaintance" end
    return "stranger"
end

BC.RegisterProvider("partner_stats", function(ctx, _, addressee, opts)
    if addressee == nil then return end
    if isPlayerObject(addressee, opts) then
        ctx.partner = buildPlayerPartnerStats(addressee)
    elseif type(addressee) == "table" and addressee.id ~= nil then
        ctx.partner = BC.ResolveActorStats(addressee, {
            role = opts and opts.partnerRole or "partner",
            inCombat = opts and opts.inCombat == true,
        }, ctx.now)
        ctx.partner.isPlayer = false
        ctx.partner.isCompanion = isCompanionRecord(addressee)
    end
end)

BC.RegisterProvider("pair_relationship", function(ctx, speaker, addressee, opts)
    if type(speaker) ~= "table" or speaker.id == nil or addressee == nil then return end
    local partnerIsPlayer = isPlayerObject(addressee, opts)
    local partnerKey = resolvePartnerKey(addressee, opts)
    local rel = nil
    local relSvc = PNC.Relationships
    if partnerKey and relSvc and type(relSvc.Get) == "function" then
        local ok, found = pcall(relSvc.Get, speaker.id, partnerKey)
        if ok and type(found) == "table" then rel = found end
    end

    local spCompanion = isCompanionRecord(speaker)
    local ptCompanion = (not partnerIsPlayer) and isCompanionRecord(addressee) or false
    local sameFaction = false
    if partnerIsPlayer then
        sameFaction = spCompanion
    elseif type(addressee) == "table" then
        sameFaction = (speaker.factionID ~= nil and speaker.factionID == addressee.factionID)
            or (spCompanion and ptCompanion)
    end

    local isHostile = speaker.isHostile == true
        or tostring(speaker.activeBehavior or speaker.behavior or "") == "hostile"
    local tier = classifyTier(rel, sameFaction, isHostile)
    local idTrust = rel and tostring(rel.identityTrust or "") or ""
    if idTrust == "" then idTrust = "unknown" end
    local knowsName = sameFaction or idTrust == "trusted"
        or (rel and (rel.identityKnown == true or rel.nameKnown == true)) == true

    ctx.relationship = {
        found = rel ~= nil,
        partnerKey = partnerKey,
        partnerIsPlayer = partnerIsPlayer,
        tier = tier,
        state = rel and rel.state or tier,
        affinity = tonumber(rel and (rel.approval or rel.affinity)) or 0,
        trust = tonumber(rel and rel.trust) or 0,
        respect = tonumber(rel and rel.respect) or 0,
        familiarity = tonumber(rel and rel.familiarity) or 0,
        identityTrust = idTrust,
        knowsName = knowsName,
        sameFaction = sameFaction,
        speakerIsCompanion = spCompanion,
        partnerIsCompanion = ptCompanion,
        isCompanion = spCompanion or ptCompanion,
        isCrossGroup = (spCompanion ~= ptCompanion) and (not partnerIsPlayer),
        earnedDelta = tonumber(opts and opts.earnedDelta) or 0,
    }
end)

function BC.FlattenForSpeech(ctx)
    ctx = type(ctx) == "table" and ctx or {}
    local a = type(ctx.actor) == "table" and ctx.actor or {}
    local p = type(ctx.partner) == "table" and ctx.partner or {}
    local r = type(ctx.relationship) == "table" and ctx.relationship or {}
    local e = type(ctx.env) == "table" and ctx.env or {}
    local tod = tostring(e.timeOfDay or "day")
    return {
        speakerStyle = a.style or "neutral",
        speakerStyleProfile = a.styleProfile or "default",
        partnerStyle = p.style or "neutral",
        partnerIsPlayer = p.isPlayer == true or r.partnerIsPlayer == true,
        relationshipTier = r.tier or "stranger",
        identityTrust = r.identityTrust or "unknown",
        knowsName = r.knowsName == true,
        playerNameKnown = (r.partnerIsPlayer == true) and (r.knowsName == true) or nil,
        sameFaction = r.sameFaction == true,
        isCompanion = r.isCompanion == true,
        isCrossGroup = r.isCrossGroup == true,
        timeOfDay = tod,
        sceneClock = tod,
        isNightOrDusk = tod == "night" or tod == "dusk",
        weather = e.weather or "clear",
        isRaining = e.isRaining == true,
        isIndoors = e.isIndoors == true,
        speakerInjured = a.isInjured == true,
        speakerExhausted = a.isExhausted == true,
        partnerInjured = p.isInjured == true,
        partnerExhausted = p.isExhausted == true,
        anyInjured = a.isInjured == true or p.isInjured == true,
        anyExhausted = a.isExhausted == true or p.isExhausted == true,
        earnedRelationship = (tonumber(r.earnedDelta) or 0) > 0,
    }
end

return BC
