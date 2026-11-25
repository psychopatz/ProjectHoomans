-- Domain-neutral semantic speech realization and token formatting helpers.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Transport = PNC.Semantics.SpeechTransport or {}
PNC.Semantics.SpeechTransport = Transport

local TokenFormatter = PNC.ConvoEngine.TokenFormatter
    or require "PNC/ConvoEngine/TokenFormatter"
local Lexicon = PNC.ConvoEngine.Lexicon
    or require "PNC/ConvoEngine/Lexicon"
local GrammarJoin = PNC.ConvoEngine.GrammarJoin
    or require "PNC/ConvoEngine/GrammarJoin"

local MAX_COOLDOWN_KEYS = 256
local sr = nil
local streamCooldowns, streamOrder = {}, {}
local familyCooldowns, familyOrder = {}, {}

local function finite(v)
    v = tonumber(v)
    if v == nil or v ~= v or v == math.huge or v == -math.huge then return nil end
    return v
end
Transport.Finite = finite

local function cleanText(v)
    if v == nil then return nil end
    if GrammarJoin and type(GrammarJoin.CleanSurface) == "function" then
        return GrammarJoin.CleanSurface(v)
    end
    local s = tostring(v)
    s = string.gsub(s, "^%s+", "")
    s = string.gsub(s, "%s+$", "")
    return s ~= "" and s or nil
end
Transport.CleanText = cleanText

local function copyShallow(source)
    local out = {}
    if type(source) ~= "table" then return out end
    for k, v in pairs(source) do out[k] = v end
    return out
end
Transport.CopyShallow = copyShallow

function Transport.FirstTokenName(raw)
    return TokenFormatter.FirstTokenName(raw)
end

function Transport.FormatTokens(text, tokens)
    return TokenFormatter.Format(text, tokens)
end

function Transport.DefaultCooldowns(familyMs, speakerMs, ambientMs)
    return { familyMs = familyMs, speakerMs = speakerMs, ambientMs = ambientMs, mergeWindowMs = 0 }
end

function Transport.PlayerKey(p)
    if not p then return nil end
    if type(p.getOnlineID) == "function" then
        local v = p:getOnlineID()
        if v ~= nil then return tostring(v) end
    end
    if type(p.getUsername) == "function" then
        local v = p:getUsername()
        if v and v ~= "" then return tostring(v) end
    end
    return nil
end

local function coord(o, m)
    return (o and type(o[m]) == "function") and finite(o[m](o)) or nil
end

function Transport.CanHear(p, rec, radius)
    local px, py, pz = coord(p, "getX"), coord(p, "getY"), coord(p, "getZ")
    local nx, ny, nz = finite(rec and rec.x), finite(rec and rec.y), finite(rec and rec.z)
    if not px or not py or not pz or not nx or not ny or not nz or math.abs(pz - nz) >= 1 then
        return false
    end
    local rad, dx, dy = tonumber(radius) or 12, px - nx, py - ny
    if (dx * dx + dy * dy) > rad * rad then return false end
    local perc = PNC.Perception
    return perc and type(perc.CanSeeWorldObject) == "function"
        and perc.CanSeeWorldObject(rec, p) == true or false
end

local function setBoundedCooldown(map, order, key, untilAt)
    if map[key] == nil then
        while #order >= MAX_COOLDOWN_KEYS do
            local oldest = table.remove(order, 1)
            map[oldest] = nil
        end
        order[#order + 1] = key
    end
    map[key] = untilAt
end

function Transport.ReserveNeutralCooldown(streamKey, family, npcId, aud, now, cd, famCd)
    local sKey = aud .. "|" .. streamKey
    local fKey = aud .. "|" .. tostring(family) .. "|" .. npcId
    if cd > 0 and now < (tonumber(streamCooldowns[sKey]) or -math.huge) then return false end
    if famCd > 0 and now < (tonumber(familyCooldowns[fKey]) or -math.huge) then return false end
    if cd > 0 then setBoundedCooldown(streamCooldowns, streamOrder, sKey, now + cd) end
    if famCd > 0 then setBoundedCooldown(familyCooldowns, familyOrder, fKey, now + famCd) end
    return true
end

function Transport.ResetRuntime()
    streamCooldowns, streamOrder = {}, {}
    familyCooldowns, familyOrder = {}, {}
end

function Transport.ResolveLine(rec, opts)
    if type(rec) ~= "table" or rec.id == nil then return nil, nil end
    opts = type(opts) == "table" and opts or {}
    local react = PNC.ConvoEngine and PNC.ConvoEngine.SocialReactions
    if type(react) ~= "table" or type(react.Resolve) ~= "function" then return nil, nil end

    local evType = tostring(opts.eventType or "social_beat")
    local ref = opts.eventID or opts.eventRef or evType
    local act = tostring(opts.act or "REACT")
    local topic = cleanText(opts.topic or opts.domain) or evType
    local context = copyShallow(opts.context)
    if context.topic == nil then context.topic = topic end
    local role = opts.role or opts.replyRole
    if role ~= nil then
        if context.beatRole == nil then context.beatRole = role end
        if context.combatReactionRole == nil then context.combatReactionRole = role end
    end
    if opts.inCombat ~= nil then context.inCombat = opts.inCombat == true end

    local res
    if opts.templateID ~= nil or opts.fallback ~= nil then
        res = {
            realizationID = opts.realizationID or opts.templateID or ("semantic.beat." .. tostring(role or evType)),
            templateID = opts.templateID,
            fallback = opts.fallback,
            presentationClass = opts.presentationClass or "BARK",
        }
    else
        res = react.Resolve({
            eventType = evType, eventID = ref, npcID = tostring(rec.id),
            act = act, topic = topic, poolID = opts.poolID, context = context,
        })
    end
    if type(res) ~= "table" then return nil, nil end

    local raw = res.fallback or res.text
    sr = sr or (PNC.ConvoEngine and PNC.ConvoEngine.SpeechRealization)
    if sr and type(sr.Apply) == "function" then
        local ap = sr.Apply(
            { selectionID = res.realizationID, templateID = res.templateID, fallback = raw },
            { npcID = tostring(rec.id), phraseSalt = tostring(ref or "") .. ":" .. tostring(rec.id) }
        )
        if type(ap) == "table" and type(ap.fallback) == "string" and ap.fallback ~= "" then
            raw = ap.fallback
        end
    end
    if type(raw) ~= "string" or raw == "" then return nil, nil end
    local mergedTokens = copyShallow(opts.tokens)
    if mergedTokens["speaker.name"] == nil or cleanText(mergedTokens["speaker.name"]) == nil then
        mergedTokens["speaker.name"] = TokenFormatter.FirstTokenName(
            rec.name or rec.fullName or rec.displayName
        )
    end
    if mergedTokens["addressee.name"] == nil or cleanText(mergedTokens["addressee.name"]) == nil then
        local addr = type(opts.addressee) == "table" and opts.addressee or nil
        local addrAllowed = addr == nil or (addr.identityKnown ~= false and addr.isUnknown ~= true)
        local rawAddressee = addrAllowed and addr
            and (addr.name or addr.fullName or addr.displayName) or nil
        if rawAddressee == nil then
            if context.playerNameKnown == true then
                rawAddressee = opts.addresseeName or context.addresseeName
                    or context.playerAddressName or context.playerName
            elseif context.playerNameKnown == false then
                rawAddressee = context.playerAddressName or context.player
            else
                rawAddressee = opts.addresseeName or context.targetName
            end
        end
        if rawAddressee == nil and context.npcIdentityKnown == true then
            rawAddressee = context.npcName
        end
        mergedTokens["addressee.name"] = TokenFormatter.FirstTokenName(rawAddressee)
    else
        mergedTokens["addressee.name"] = TokenFormatter.CleanName(mergedTokens["addressee.name"])
    end
    if mergedTokens["scene.location"] == nil then
        mergedTokens["scene.location"] = TokenFormatter.CleanLocation(
            opts.sceneLocation or opts.locationLabel or context.sceneLocation
            or context.locationLabel or context.locationName or context.zoneName
            or context.settlementName or context.roomName or rec.zoneName
            or rec.locationName or rec.settlementName or rec.roomName
        )
    elseif cleanText(mergedTokens["scene.location"]) == nil then
        mergedTokens["scene.location"] = nil
    end
    if mergedTokens["scene.clock"] == nil or cleanText(mergedTokens["scene.clock"]) == nil then
        mergedTokens["scene.clock"] = TokenFormatter.CleanName(
            opts.sceneClock or context.sceneClock or context.timeOfDay
        )
    end
    if type(TokenFormatter.AttachPronouns) == "function" then
        TokenFormatter.AttachPronouns(mergedTokens, "speaker", rec)
        if type(opts.addressee) == "table" or opts.addressee ~= nil then
            TokenFormatter.AttachPronouns(mergedTokens, "addressee", opts.addressee)
        end
    end
    if Lexicon and type(Lexicon.Expand) == "function" then
        context.npcID = context.npcID or tostring(rec.id)
        return Lexicon.Expand(raw, context, mergedTokens, {
            salt = tostring(ref or "") .. ":" .. tostring(rec.id),
        }), res
    end
    return Transport.FormatTokens(raw, mergedTokens), res
end

return Transport
