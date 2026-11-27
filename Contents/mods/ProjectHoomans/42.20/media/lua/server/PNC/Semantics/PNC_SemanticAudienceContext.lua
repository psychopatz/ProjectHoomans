-- Shared audience resolution for dialogue beats and combat callouts.
-- Includes nearby non-hostile players alongside allied NPCs and resolves
-- singular/pair/plural addressing, pronouns, and target verb agreement.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Audience = PNC.Semantics.AudienceContext or {}
PNC.Semantics.AudienceContext = Audience

local GROUP_LABELS = { "everyone", "everybody", "guys" }
local seq = 0

local function firstTokenName(raw)
    if raw == nil then return nil end
    local tf = PNC.ConvoEngine and PNC.ConvoEngine.TokenFormatter or nil
    if tf and type(tf.FirstTokenName) == "function" then
        local cleaned = tf.FirstTokenName(raw)
        if cleaned and cleaned ~= "" then return cleaned end
    end
    local s = tostring(raw)
    s = string.gsub(s, "^%s+", "")
    s = string.gsub(s, "%s+$", "")
    local first = string.match(s, "^([^%s]+)")
    return (first and first ~= "") and first or nil
end

local function playerKeyFor(p)
    if not p then return "player" end
    local uname = type(p.getUsername) == "function" and tostring(p:getUsername() or "") or ""
    if uname ~= "" then return "player:" .. uname end
    return "player"
end

local function isHostileToPlayer(speaker, player)
    if type(speaker) ~= "table" then return false end
    if speaker.isHostile == true then return true end
    local tc = tostring(speaker.tacticalClass or "")
    if tc == "hostile" then return true end
    if PNC.Types and type(PNC.Types.ResolveTacticalClass) == "function" then
        local resolved = tostring(PNC.Types.ResolveTacticalClass(speaker) or "")
        if resolved == "hostile" then return true end
    end
    local beh = tostring(speaker.activeBehavior or speaker.behavior or "")
    if beh == "hostile" then return true end
    if type(speaker.hostility) == "table" then
        if tostring(speaker.hostility.mode or "") == "hostile"
            or speaker.hostility.attackPlayers == true
        then
            return true
        end
    end
    local rt = type(speaker.runtime) == "table" and speaker.runtime or nil
    if rt then
        if rt.hostileToPlayer == true then return true end
        if type(rt.target) == "table" and tostring(rt.target.kind or "") == "player" then
            return true
        end
    end
    local pKey = playerKeyFor(player)
    local rels = PNC.Relationships
    if rels and type(rels.Get) == "function" and speaker.id ~= nil then
        local rel = rels.Get(speaker.id, pKey)
        if type(rel) == "table" then
            local st = string.lower(tostring(rel.state or ""))
            if st == "enemy" or st == "hostile" or st == "rival" then return true end
            if tonumber(rel.approval) and tonumber(rel.approval) <= -25 then return true end
        end
    end
    local isOwnedByPlayer = speaker.recruited == true
        or speaker.isCompanion == true
        or speaker.ownerUsername ~= nil
        or speaker.ownerOnlineID ~= nil
    if not isOwnedByPlayer then
        local aff = type(speaker.affiliation) == "table" and speaker.affiliation or nil
        local fid = (aff and aff.factionID) or speaker.factionID
        if fid ~= nil and PNC.FactionArchetypes
            and type(PNC.FactionArchetypes.IsHostileToOutsiders) == "function"
            and PNC.FactionArchetypes.IsHostileToOutsiders(fid) == true
        then
            return true
        end
    end
    return false
end

Audience.IsHostileToPlayer = isHostileToPlayer

function Audience.CanAddressPlayerAsAlly(speaker, player, opts)
    if type(speaker) ~= "table" then return false end
    if isHostileToPlayer(speaker, player) then return false end
    if not (type(opts) == "table" and opts.requireAlly == true) then
        return true
    end
    -- Combat/team callouts require an actual ally/teammate relationship with the player.
    if speaker.recruited == true
        or speaker.isCompanion == true
        or speaker.isColonist == true
    then
        return true
    end
    local role = string.lower(tostring(speaker.role or speaker.tacticalRole or ""))
    if role == "companion" or role == "colonist" then return true end
    local order = type(speaker.orderSpec) == "table" and speaker.orderSpec or nil
    local ownerUser = speaker.ownerUsername or (order and order.ownerUsername)
    local ownerOID = speaker.ownerOnlineID or (order and order.ownerOnlineID)
    if ownerUser ~= nil and tostring(ownerUser) ~= "" then
        if not player or type(player.getUsername) ~= "function"
            or tostring(player:getUsername() or "") == ""
            or tostring(player:getUsername()) == tostring(ownerUser)
        then
            return true
        end
    end
    if ownerOID ~= nil then
        if not player or type(player.getOnlineID) ~= "function"
            or tostring(player:getOnlineID()) == tostring(ownerOID)
        then
            return true
        end
    end
    local pKey = playerKeyFor(player)
    local rels = PNC.Relationships
    if rels and type(rels.Get) == "function" and speaker.id ~= nil then
        local rel = rels.Get(speaker.id, pKey)
        if type(rel) == "table" then
            local st = string.lower(tostring(rel.state or ""))
            if st == "friend" or st == "ally" or st == "lover"
                or st == "family" or st == "companion"
            then
                return true
            end
            if tonumber(rel.approval) and tonumber(rel.approval) >= 10 then
                return true
            end
        end
    end
    return false
end

local function resolvePlayerEntry(p, speaker, maxRadius)
    if not p then return nil end
    if type(p.isDead) == "function" and p:isDead() == true then return nil end
    local px = type(p.getX) == "function" and tonumber(p:getX()) or nil
    local py = type(p.getY) == "function" and tonumber(p:getY()) or nil
    local pz = type(p.getZ) == "function" and tonumber(p:getZ()) or 0
    if px == nil or py == nil then return nil end
    if type(speaker) == "table" and speaker.x ~= nil and speaker.y ~= nil then
        local sz = tonumber(speaker.z) or 0
        if math.abs(pz - sz) >= 1 then return nil end
        local dx, dy = px - (tonumber(speaker.x) or 0), py - (tonumber(speaker.y) or 0)
        local r = tonumber(maxRadius) or 14
        if (dx * dx + dy * dy) > (r * r) then return nil end
    end
    local desc = type(p.getDescriptor) == "function" and p:getDescriptor() or nil
    local rawName = (desc and type(desc.getForename) == "function" and desc:getForename())
        or (type(p.getDisplayName) == "function" and p:getDisplayName())
        or (type(p.getUsername) == "function" and p:getUsername())
        or nil
    local name = firstTokenName(rawName) or "friend"
    local injured = false
    if type(p.getBodyDamage) == "function" then
        local bd = p:getBodyDamage()
        local health = bd and type(bd.getOverallBodyHealth) == "function"
            and tonumber(bd:getOverallBodyHealth()) or nil
        if health and health < 80 then injured = true end
    end
    return {
        id = "player",
        name = name,
        isPlayer = true,
        injured = injured,
        player = p,
    }
end

function Audience.FindNearbyAlliedPlayer(speaker, maxRadius, opts)
    if isHostileToPlayer(speaker, nil) then return nil end
    local core = PNC.Core
    if not core or type(core.ForEachPlayer) ~= "function" then return nil end
    local best = nil
    local bestDistSq = math.huge
    local sx = tonumber(speaker and speaker.x)
    local sy = tonumber(speaker and speaker.y)
    core.ForEachPlayer(function(p)
        if not Audience.CanAddressPlayerAsAlly(speaker, p, opts) then return end
        local entry = resolvePlayerEntry(p, speaker, maxRadius or 14)
        if not entry then return end
        local dSq = 0
        if sx and sy and type(p.getX) == "function" and type(p.getY) == "function" then
            local dx = (tonumber(p:getX()) or sx) - sx
            local dy = (tonumber(p:getY()) or sy) - sy
            dSq = dx * dx + dy * dy
        end
        if dSq < bestDistSq then
            bestDistSq = dSq
            best = entry
        end
    end)
    return best
end

-- Build normalized audience addressing tokens & ConvoDSL context flags.
-- `listeners` is an optional list of NPC/player listener tables.
function Audience.Resolve(speaker, listeners, opts)
    opts = type(opts) == "table" and opts or {}
    local spId = tostring(speaker and speaker.id or "")
    local names = {}
    local seen = {}
    local includesPlayer = false
    local playerName = nil
    local playerInjured = false

    local function addListener(entry)
        if type(entry) ~= "table" then return end
        if entry.isPlayer == true and not Audience.CanAddressPlayerAsAlly(speaker, entry.player, opts) then
            return
        end
        local eid = tostring(entry.id or "")
        if eid ~= "" and eid == spId then return end
        local key = entry.isPlayer == true and "player" or (eid ~= "" and eid or tostring(entry.name or ""))
        if key == "" or seen[key] then return end
        seen[key] = true
        local ref = PNC.ActorReference or (PNC.Semantics and PNC.Semantics.ActorReference)
        local n
        if ref and type(ref.NameFor) == "function" and type(speaker) == "table" then
            n = ref.NameFor(speaker, entry, {
                role = "vocative",
                unknownAddress = entry.isPlayer == true and "friend" or "stranger",
            })
        else
            n = firstTokenName(entry.name or entry.fullName or entry.displayName)
        end
        if entry.isPlayer == true then
            includesPlayer = true
            playerName = n or "friend"
            if entry.injured == true then playerInjured = true end
        end
        names[#names + 1] = n or "friend"
    end

    if type(listeners) == "table" then
        for i = 1, #listeners do
            addListener(listeners[i])
        end
    end

    if opts.includeNearbyPlayer ~= false and not includesPlayer then
        local pEntry = Audience.FindNearbyAlliedPlayer(speaker, tonumber(opts.playerRadius) or 14, opts)
        if pEntry then addListener(pEntry) end
    end

    local count = #names
    local isPlural = count >= 2
    seq = seq + 1
    local label
    if count == 0 then
        label = opts.fallbackName or ""
    elseif count == 1 then
        label = names[1]
    elseif count == 2 then
        if opts.preferPairNames ~= false and names[1] ~= names[2] and (seq % 2 == 1) then
            label = names[1] .. " and " .. names[2]
        else
            label = "you two"
        end
    else
        label = GROUP_LABELS[((seq - 1) % #GROUP_LABELS) + 1]
    end

    local targetCount = math.max(1, math.floor(tonumber(opts.targetCount) or 1))
    local tokens = {
        ["addressee.name"] = label,
        ["audience.label"] = label,
        ["audience.count"] = tostring(count),
        ["audience.pronoun"] = isPlural and "you all" or "you",
        ["target.pronoun"] = targetCount > 1 and "them" or "it",
        ["target.verb_be"] = targetCount > 1 and "are" or "is",
    }
    if playerName then
        tokens["player.name"] = playerName
    end

    local context = {
        audienceCount = count,
        audiencePlural = isPlural,
        audienceIncludesPlayer = includesPlayer,
        playerInjured = playerInjured,
        ["audience.plural"] = isPlural,
        ["audience.includes_player"] = includesPlayer,
    }

    return {
        count = count,
        isPlural = isPlural,
        includesPlayer = includesPlayer,
        playerName = playerName,
        playerInjured = playerInjured,
        label = label,
        names = names,
        tokens = tokens,
        context = context,
    }
end

function Audience.ResetRuntime()
    seq = 0
end

return Audience
