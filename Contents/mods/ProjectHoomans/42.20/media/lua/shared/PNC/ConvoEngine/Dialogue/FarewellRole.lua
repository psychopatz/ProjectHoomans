-- Single-source semantic relationship role resolver for farewell & social tone.
PNC = PNC or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local FarewellRole = PNC.ConvoEngine.FarewellRole or {}
PNC.ConvoEngine.FarewellRole = FarewellRole

local HOSTILE_KINDS = {
    hostile = true, enemy = true, antagonistic = true, raider_hostile = true,
}
local LOVER_KINDS = {
    lover = true, partner = true, spouse = true, romantic = true, romance = true,
}
local FAMILY_KINDS = {
    brother = true, sister = true, mother = true, father = true,
    parent = true, child = true, son = true, daughter = true,
    family = true, kin = true, sibling = true,
}
local WARY_KINDS = {
    wary = true, rival = true, suspicious = true, distrusted = true,
    unfriendly = true, guarded = true, strained = true, cold = true, disliked = true,
}
local FRIEND_KINDS = {
    friend = true, close_friend = true, best_friend = true, ally = true,
    trusted = true, warm = true, bonded = true, devoted = true, close = true,
}
local COLONIST_KINDS = {
    member = true, companion = true, colonist = true, follower = true, squad = true,
}

local function clean(value, fallback)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value ~= "" and value or fallback
end

local function norm(value)
    local s = string.lower(clean(value, ""))
    s = string.gsub(s, "([a-z])([A-Z])", "%1_%2")
    return string.gsub(s, "[%s%-]+", "_")
end

local function firstVal(entry, snapshot, record, key)
    return entry[key] or snapshot[key] or record[key]
end

local function isHostileFlags(entry, snapshot, record, context)
    local eh = type(entry.hostility) == "table" and entry.hostility or {}
    local sh = type(snapshot.hostility) == "table" and snapshot.hostility or {}
    local rh = type(record.hostility) == "table" and record.hostility or {}
    local ch = type(context.hostility) == "table" and context.hostility or {}
    return context.playerHostile == true
        or context.tacticalClass == "hostile"
        or entry.tacticalClass == "hostile"
        or snapshot.tacticalClass == "hostile"
        or record.tacticalClass == "hostile"
        or eh.attackPlayers == true
        or sh.attackPlayers == true
        or rh.attackPlayers == true
        or ch.attackPlayers == true
end

local function classify(tags, hostileFlag, npcType)
    if hostileFlag then return "hostile" end
    for i = 1, #tags do
        local v = norm(tags[i])
        if HOSTILE_KINDS[v] then return "hostile" end
    end
    for i = 1, #tags do
        local v = norm(tags[i])
        if LOVER_KINDS[v] then return "lover" end
    end
    for i = 1, #tags do
        local v = norm(tags[i])
        if FAMILY_KINDS[v] then return "family" end
    end
    for i = 1, #tags do
        local v = norm(tags[i])
        if WARY_KINDS[v] then return "wary" end
    end
    for i = 1, #tags do
        local v = norm(tags[i])
        if FRIEND_KINDS[v] then return "friend" end
    end
    for i = 1, #tags do
        local v = norm(tags[i])
        if COLONIST_KINDS[v] then return "colonist" end
    end
    local nt = norm(npcType)
    if COLONIST_KINDS[nt] then return "colonist" end
    if nt == "hostile" then return "hostile" end
    if nt == "wary" then return "wary" end
    if nt == "friend" then return "friend" end
    if nt == "lover" then return "lover" end
    if nt == "family" then return "family" end
    return "neutral"
end

function FarewellRole.ResolveFromContext(context, specNpcID)
    context = type(context) == "table" and context or {}
    local entry = type(context.entry) == "table" and context.entry or {}
    local snapshot = type(entry.snapshot) == "table" and entry.snapshot or {}
    local record = type(entry.record) == "table" and entry.record or {}
    local gen = record.generation or snapshot.generation or {}
    local netState = PNC.Network and PNC.Network.ClientState or {}
    local npcID = clean(specNpcID or context.npcID or entry.id, nil)
    local summary = npcID and netState.conversationRelationships
        and netState.conversationRelationships[npcID] or nil
    local rel = type(entry.relationship) == "table" and entry.relationship
        or (type(context.relationship) == "table" and context.relationship or {})
    local sit = type(context.dialogueSituation) == "table" and context.dialogueSituation or {}
    local social = type(sit.social) == "table" and sit.social or {}

    local hostileFlag = isHostileFlags(entry, snapshot, record, context)
    local tactical = norm(firstVal(entry, snapshot, record, "tacticalClass") or context.tacticalClass)
    if tactical == "hostile" then hostileFlag = true end

    local tags = {
        firstVal(entry, snapshot, record, "relationshipKind"),
        firstVal(entry, snapshot, record, "conversationRelationship"),
        firstVal(entry, snapshot, record, "relationshipCategory"),
        gen.relationshipKind,
        rel.category,
        rel.state,
        summary and summary.relationshipKind,
        summary and summary.category,
        summary and summary.state,
        summary and summary.status,
        context.conversationRelationshipID,
        context.relationshipState,
        context.relationshipTier,
        context.relationshipAttitude,
        social.attitude,
        context.socialRole,
        context.socialStyle == "withdrawn" and "wary" or nil,
        context.socialStyle == "hostile" and "hostile" or nil,
    }
    local compacted = {}
    for i = 1, 18 do
        if tags[i] ~= nil and tostring(tags[i]) ~= "" then
            compacted[#compacted + 1] = tags[i]
        end
    end
    return classify(compacted, hostileFlag, context.npcType)
end

function FarewellRole.ResolveFromSpec(spec)
    local context = type(spec) == "table" and spec.context or {}
    local npcID = type(spec) == "table" and spec.npcID or nil
    return FarewellRole.ResolveFromContext(context, npcID)
end

return FarewellRole
