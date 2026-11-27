-- Single source of truth for knowledge-gated actor names and gender-aware
-- pronouns across Behaviors, DialogueBeats, AudienceContext, and ConvoEngine.
--
-- Prevents epistemic name bleed: an observer (NPC or Player) may only refer
-- to a target by proper name when they share a group/faction/kinship, have an
-- established relationship/familiarity, or have learned the target's identity
-- through PNC.NPCKnowledgeService. Otherwise returns a grounded fallback
-- address/reference ("stranger", "friend", etc.) while still providing accurate
-- visual gender pronouns.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.Semantics.ActorReference = PNC.Semantics.ActorReference or {}
PNC.ActorReference = PNC.Semantics.ActorReference

local Ref = PNC.Semantics.ActorReference

local FAMILIARITY_NAME_THRESHOLD = 5

local PLACEHOLDER_NAMES = {
    ["STRANGER"] = true,
    ["UNKNOWN"] = true,
    ["UNKNOWN SURVIVOR"] = true,
    ["UNKNOWN NPC"] = true,
    ["SURVIVOR"] = true,
}

local function safeCall(obj, methodName, ...)
    local fn = obj and obj[methodName]
    if type(fn) ~= "function" then return nil end
    local ok, val = pcall(fn, obj, ...)
    if ok then return val end
    return nil
end

local function firstTokenName(raw)
    if raw == nil then return nil end
    local s = tostring(raw)
    s = string.gsub(s, "^%s+", "")
    s = string.gsub(s, "%s+$", "")
    if s == "" then return nil end
    if PLACEHOLDER_NAMES[string.upper(s)] then return nil end
    local tf = PNC.ConvoEngine and PNC.ConvoEngine.TokenFormatter or nil
    if tf and type(tf.FirstTokenName) == "function" then
        local cleaned = tf.FirstTokenName(s)
        if cleaned and cleaned ~= "" and not PLACEHOLDER_NAMES[string.upper(cleaned)] then
            return cleaned
        end
    end
    local first = string.match(s, "^([^%s]+)")
    if not first or first == "" or PLACEHOLDER_NAMES[string.upper(first)] then
        return nil
    end
    return first
end

local function liveBodyFor(actor)
    if type(actor) ~= "table" then return actor end
    if actor.zombie ~= nil then return actor.zombie end
    if actor.body ~= nil then return actor.body end
    if actor.player ~= nil then return actor.player end
    local reg = PNC.Registry
    if reg and type(reg.GetLiveZombie) == "function" and actor.id ~= nil then
        return reg.GetLiveZombie(actor.id)
    end
    return nil
end

function Ref.IsFemale(actor, liveBody)
    if type(actor) == "table" then
        if actor.isFemale == true or actor.female == true then return true end
        if actor.isFemale == false or actor.female == false then return false end
        local g = string.lower(tostring(actor.gender or ""))
        if g == "female" or g == "woman" or g == "f" then return true end
        if g == "male" or g == "man" or g == "m" then return false end
    end
    local body = liveBody or liveBodyFor(actor)
    if body then
        local f = safeCall(body, "isFemale")
        if type(f) == "boolean" then return f end
        local desc = safeCall(body, "getDescriptor")
        local df = desc and safeCall(desc, "isFemale")
        if type(df) == "boolean" then return df end
    end
    return false
end

function Ref.Pronouns(actor, liveBody)
    local female = Ref.IsFemale(actor, liveBody)
    return {
        isFemale = female,
        gender = female and "female" or "male",
        subj = female and "she" or "he",
        Subj = female and "She" or "He",
        obj = female and "her" or "him",
        poss = female and "her" or "his",
        Poss = female and "Her" or "His",
        refl = female and "herself" or "himself",
        personNoun = female and "woman" or "man",
    }
end

local function isPlayerTarget(actor)
    if type(actor) ~= "table" then
        return safeCall(actor, "getUsername") ~= nil or safeCall(actor, "isLocalPlayer") ~= nil
    end
    return actor.isPlayer == true or actor.kind == "player" or actor.player ~= nil
end

local function actorEntityKey(actor)
    if not actor then return nil end
    if isPlayerTarget(actor) then
        local p = type(actor) == "table" and actor.player or actor
        if PNC.PlayerCharacters and type(PNC.PlayerCharacters.GetEntityKey) == "function" and p then
            local k = PNC.PlayerCharacters.GetEntityKey(p)
            if k and tostring(k) ~= "" then return tostring(k) end
        end
        if type(actor) == "table" and actor.key and tostring(actor.key) ~= "" then
            return tostring(actor.key)
        end
        local uname = p and safeCall(p, "getUsername")
        if uname and tostring(uname) ~= "" then return "player:" .. tostring(uname) end
        return "player:local"
    end
    if type(actor) == "table" and actor.id ~= nil then
        return "npc:" .. tostring(actor.id)
    end
    return nil
end

local function playerUUIDOf(actor)
    local p = type(actor) == "table" and actor.player or actor
    if not p then return nil end
    if PNC.PlayerCharacters and type(PNC.PlayerCharacters.GetCharacterUUID) == "function" then
        local ok, uuid = pcall(PNC.PlayerCharacters.GetCharacterUUID, p)
        if ok and uuid and tostring(uuid) ~= "" then return tostring(uuid) end
    end
    if type(actor) == "table" and actor.characterUUID and tostring(actor.characterUUID) ~= "" then
        return tostring(actor.characterUUID)
    end
    return nil
end

local function sharesGroupOrFaction(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    if a.groupId ~= nil and b.groupId ~= nil and tostring(a.groupId) ~= "" and a.groupId == b.groupId then
        return true
    end
    local fa = (a.affiliation and a.affiliation.factionID) or a.factionID
    local fb = (b.affiliation and b.affiliation.factionID) or b.factionID
    if fa ~= nil and fb ~= nil and tostring(fa) ~= "" and fa == fb then
        return true
    end
    if a.colonyOwned == true and b.colonyOwned == true then
        return true
    end
    if a.recruited == true and b.recruited == true then
        local oa = a.ownerUsername or a.ownerOnlineID
        local ob = b.ownerUsername or b.ownerOnlineID
        if oa == nil or ob == nil or oa == ob then
            return true
        end
    end
    if a.familyId ~= nil and b.familyId ~= nil and a.familyId == b.familyId then
        return true
    end
    return false
end

local function hasRelationshipAcquaintance(observer, target)
    local relSvc = PNC.Relationships or PNC.RelationshipService
    if not relSvc then return false end
    local obsId = (type(observer) == "table" and observer.id ~= nil) and tostring(observer.id) or nil
    local keyA = actorEntityKey(observer)
    local keyB = actorEntityKey(target)
    if not keyB then return false end

    -- Canonical PNC.RelationshipService signature: (observerNPCID, targetKey)
    if obsId and type(relSvc.GetFamiliarity) == "function" then
        local ok, fam = pcall(relSvc.GetFamiliarity, obsId, keyB)
        if ok and (tonumber(fam) or 0) >= FAMILIARITY_NAME_THRESHOLD then
            return true
        end
    end

    local rel = nil
    if obsId and type(relSvc.Get) == "function" then
        local ok, res = pcall(relSvc.Get, obsId, keyB)
        if ok and type(res) == "table" then rel = res end
    end
    if not rel and keyA and type(relSvc.GetPair) == "function" then
        local ok, res = pcall(relSvc.GetPair, keyA, keyB)
        if ok and type(res) == "table" then rel = res end
    elseif not rel and keyA and type(relSvc.Get) == "function" then
        local ok, res = pcall(relSvc.Get, keyA, keyB)
        if ok and type(res) == "table" then rel = res end
    end
    if not rel then return false end
    if rel.knownName == true or rel.met == true or rel.acquainted == true then
        return true
    end
    local fam = tonumber(rel.familiarity or rel.familiarityValue) or 0
    return fam >= FAMILIARITY_NAME_THRESHOLD
end

local function hasPlayerKnowledgeName(playerActor, npcRecord)
    if type(npcRecord) ~= "table" or npcRecord.id == nil then return false end
    if npcRecord.recruited == true or npcRecord.colonyOwned == true then
        return true
    end
    local kSvc = PNC.NPCKnowledgeService
    local uuid = playerUUIDOf(playerActor)
    if kSvc and uuid and type(kSvc.GetDescriptor) == "function" then
        for _, descId in ipairs({ "identity.name", "identity.first_name", "identity.nickname" }) do
            local ok, desc = pcall(kSvc.GetDescriptor, uuid, npcRecord.id, descId)
            if ok and type(desc) == "table" and (desc.known == true or desc.status == "known" or desc.value ~= nil) then
                return true
            end
        end
    end
    -- Client-side fallback when called in client presentation contexts
    local idPres = PNC.NPCIdentityPresentation
    if idPres and type(idPres.IsNameKnown) == "function" then
        local ok, known = pcall(idPres.IsNameKnown, npcRecord)
        if ok and known == true then return true end
    end
    return false
end

-- Returns true iff `observer` epistemically knows `target`'s proper name.
function Ref.KnowsName(observer, target)
    if not target then return false end
    if not observer then return false end
    if observer == target then return true end

    local obsIsPlayer = isPlayerTarget(observer)
    local tgtIsPlayer = isPlayerTarget(target)

    if not obsIsPlayer and not tgtIsPlayer then
        if type(observer) == "table" and type(target) == "table"
            and observer.id ~= nil and tostring(observer.id) == tostring(target.id)
        then
            return true
        end
        if sharesGroupOrFaction(observer, target) then return true end
        if hasRelationshipAcquaintance(observer, target) then return true end
        return false
    end

    if not obsIsPlayer and tgtIsPlayer then
        if type(observer) == "table" and (observer.recruited == true or observer.colonyOwned == true) then
            return true
        end
        if hasRelationshipAcquaintance(observer, target) then return true end
        if hasPlayerKnowledgeName(target, observer) then return true end
        return false
    end

    if obsIsPlayer and not tgtIsPlayer then
        if hasPlayerKnowledgeName(observer, target) then return true end
        if hasRelationshipAcquaintance(observer, target) then return true end
        return false
    end

    return true
end

local function extractRawName(target)
    if type(target) == "table" then
        if target.player then
            local desc = safeCall(target.player, "getDescriptor")
            local fore = desc and safeCall(desc, "getForename")
            if fore and tostring(fore) ~= "" then return fore end
            local disp = safeCall(target.player, "getDisplayName")
            if disp and tostring(disp) ~= "" then return disp end
        end
        return target.name or target.fullName or target.displayName
    end
    local desc = safeCall(target, "getDescriptor")
    local fore = desc and safeCall(desc, "getForename")
    if fore and tostring(fore) ~= "" then return fore end
    return safeCall(target, "getDisplayName") or safeCall(target, "getUsername")
end

-- Resolves the name `observer` should use for `target`, gated by KnowsName.
-- `opts.role`: "vocative" (direct address) | "reference" (3rd-person mention).
function Ref.NameFor(observer, target, opts)
    opts = type(opts) == "table" and opts or {}
    if Ref.KnowsName(observer, target) then
        local clean = firstTokenName(extractRawName(target))
        if clean then return clean, true end
    end
    if opts.role == "reference" then
        return tostring(opts.unknownReference or "stranger"), false
    end
    return tostring(opts.unknownAddress or "stranger"), false
end

-- Builds a complete token set under `prefix` (e.g. "victim" or "addressee")
-- from `observer`'s epistemic perspective of `target`.
function Ref.BuildTokens(observer, target, prefix, opts)
    opts = type(opts) == "table" and opts or {}
    prefix = tostring(prefix or "target")
    local name, known = Ref.NameFor(observer, target, opts)
    local p = Ref.Pronouns(target, opts.liveBody)
    return {
        [prefix .. ".name"] = name,
        [prefix .. ".known"] = known and "true" or "false",
        [prefix .. ".subj"] = p.subj,
        [prefix .. ".Subj"] = p.Subj,
        [prefix .. ".obj"] = p.obj,
        [prefix .. ".poss"] = p.poss,
        [prefix .. ".Poss"] = p.Poss,
        [prefix .. ".refl"] = p.refl,
        [prefix .. ".gender"] = p.gender,
    }, known
end

return Ref
