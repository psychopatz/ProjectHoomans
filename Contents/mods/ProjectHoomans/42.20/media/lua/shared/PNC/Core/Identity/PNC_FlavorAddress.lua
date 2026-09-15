-- Safe, deterministic player addressing for NPC flavor text.
--
-- This module deliberately separates authoritative identity from its
-- presentation.  Callers may read the real player identity, but this module
-- will only expose it when the caller has an explicit name-knowledge fact.
-- The canonical gender flag is the existing boolean `isFemale`.

PNC = PNC or {}
PNC.FlavorAddress = PNC.FlavorAddress or {}

if not PNC.Identity or not PNC.Identity.NormalizeSeed then
    require "PNC/Core/Identity/PNC_Identity"
end

local Address = PNC.FlavorAddress
local Identity = PNC.Identity
local Nicknames = require "PNC/Core/Identity/PNC_FlavorAddress_Nicknames"
local Names = require "PNC/Core/Identity/PNC_FlavorAddress_Names"
local translatedNicknames = {}

Address.VERSION = Address.VERSION or 1

local function translate(key, fallback)
    if translatedNicknames[key] then return translatedNicknames[key] end
    local value = PNC.Translation.GetKey(key)
    value = Names.Clean(value, nil)
    value = value and value ~= key and value or fallback
    translatedNicknames[key] = value
    return value
end

local function knownFromMap(map, npcID, playerUUID)
    if type(map) ~= "table" then return nil end
    npcID = Names.Clean(npcID, nil)
    playerUUID = Names.Clean(playerUUID, nil)
    if not npcID then return nil end

    local direct = map[npcID]
    if type(direct) == "boolean" then return direct end
    if type(direct) == "table" and playerUUID
        and type(direct[playerUUID]) == "boolean"
    then
        return direct[playerUUID]
    end
    if playerUUID and type(map[playerUUID]) == "table"
        and type(map[playerUUID][npcID]) == "boolean"
    then
        return map[playerUUID][npcID]
    end
    return nil
end

function Address.ResolvePlayerIsFemale(player, explicit)
    if type(explicit) == "boolean" then return explicit end
    local value = player and Names.Call(player, "isFemale") or nil
    if type(value) == "boolean" then return value end
    local descriptor = player and Names.Call(player, "getDescriptor") or nil
    value = descriptor and Names.Call(descriptor, "isFemale") or nil
    if type(value) == "boolean" then return value end
    return false
end

function Address.ResolveNPCSeed(source, fallback)
    source = type(source) == "table" and source or {}
    local candidates = {
        source,
        type(source.snapshot) == "table" and source.snapshot or nil,
        type(source.record) == "table" and source.record or nil,
    }
    for index = 1, #candidates do
        local value = candidates[index]
        local identity = value and value.identity or nil
        local seed = value and (
            value.identitySeed or value.npcIdentitySeed
        ) or nil
        seed = seed or identity and (
            identity.identitySeed or identity.seed
        ) or nil
        if seed ~= nil then
            return Identity.NormalizeSeed(seed, fallback or "npc")
        end
    end
    return Identity.NormalizeSeed(nil, fallback or "npc")
end

function Address.IsPlayerNameKnown(npcID, playerUUID, state)
    state = type(state) == "table" and state
        or PNC.Network and PNC.Network.ClientState or {}
    local maps = {
        state.playerNameKnowledge,
        state.npcPlayerKnowledge,
        state.playerIdentityKnowledge,
    }
    for index = 1, #maps do
        local value = knownFromMap(maps[index], npcID, playerUUID)
        if value ~= nil then return value end
    end
    return false
end

function Address.ResolvePlayer(options)
    options = type(options) == "table" and options or {}
    local playerUUID = Names.Clean(options.playerUUID, nil)
    local npcID = Names.Clean(options.npcID, "unknown-npc")
    local isFemale = Address.ResolvePlayerIsFemale(
        options.player, options.isFemale
    )
    local seed = Identity.NormalizeSeed(
        options.npcIdentitySeed,
        npcID
    )
    local nicknameSeed = playerUUID
        and Identity.HashText(playerUUID, seed) or seed
    local pool = isFemale and Nicknames.female or Nicknames.default
    local nickname = pool[Identity.Index(
        nicknameSeed,
        "flavor-address:v" .. tostring(Address.VERSION),
        #pool
    )] or pool[1]
    local nicknameText = nickname
        and translate(nickname.key, nickname.fallback) or "Stranger"
    local known = options.playerNameKnown == true
    local fullName, firstName, lastName
    if known then
        fullName, firstName, lastName = Names.Read(options)
        known = fullName ~= nil or firstName ~= nil
    end
    if not known then
        return {
            known = false,
            isFemale = isFemale,
            addressName = nicknameText,
            firstName = nicknameText,
            fullName = nicknameText,
            surname = "",
            lastName = "",
            nicknameID = nickname and nickname.id or "stranger",
        }
    end
    return {
        known = true,
        isFemale = isFemale,
        addressName = firstName or fullName or nicknameText,
        firstName = firstName or fullName or nicknameText,
        fullName = fullName or firstName or nicknameText,
        surname = lastName or "",
        lastName = lastName or "",
        nicknameID = nil,
    }
end

function Address.ResolveForNPC(options)
    options = type(options) == "table" and options or {}
    local known = options.playerNameKnown
    if type(known) ~= "boolean" then
        known = Address.IsPlayerNameKnown(
            options.npcID,
            options.playerUUID,
            options.state
        )
    end
    local resolved = {}
    for key, value in pairs(options) do resolved[key] = value end
    resolved.playerNameKnown = known
    return Address.ResolvePlayer(resolved)
end

function Address.ApplyPlayer(context, options)
    context = type(context) == "table" and context or {}
    local address = Address.ResolveForNPC(options)
    context.player = address.addressName
    context.playerName = address.addressName
    context.playerAddressName = address.addressName
    context.playerFullName = address.fullName
    context.playerFirstName = address.firstName
    context.playerSurname = address.surname
    context.playerLastName = address.lastName
    context.playerNameKnown = address.known
    context.playerIsFemale = address.isFemale
    context.playerNicknameID = address.nicknameID
    return context, address
end

return Address
