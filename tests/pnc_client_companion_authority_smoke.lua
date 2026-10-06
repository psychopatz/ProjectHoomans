--[[
    Client companion authority.

    `PNC.CompanionCommands.IsOwnedByPlayer` needs the faction registry and the
    player-character identity service. Both live under `server/` and return
    early through the RuntimeRole guard, so on a multiplayer client ownership
    always resolves to `factions_unavailable`. Every client-side gate that asked
    "is this NPC mine?" therefore answered no, which is why the companion
    command and inventory context options appeared in single player and vanished
    in multiplayer.

    These assertions pin the replacement: the authoritative check is always
    preferred where it can work, and the replicated faction projection answers
    the same question on a pure client, failing closed when the client has not
    synced a faction yet.
]]

local T = require "tests/support/test"

T.addPackagePaths()

local SHARED = T.path("ProjectHoomans", "shared", "")
local CLIENT = T.path("ProjectHoomans", "client", "")

local PRESENCE_LIVE = "live"
local FACTION = "faction_mp"

PNC = {
    Const = {
        PRESENCE_LIVE = PRESENCE_LIVE,
        COMPANION_COMMAND_RADIUS = 20,
    },
    Core = {
        DistanceSq = function(x1, y1, x2, y2)
            local dx = (tonumber(x1) or 0) - (tonumber(x2) or 0)
            local dy = (tonumber(y1) or 0) - (tonumber(y2) or 0)
            return (dx * dx) + (dy * dy)
        end,
    },
    Network = { ClientState = {} },
    -- No PNC.Factions and no PNC.PlayerCharacters: this is a pure multiplayer
    -- client, where both services are server-only.
}

local function playerAt(x, y, z)
    return {
        getX = function() return x end,
        getY = function() return y end,
        getZ = function() return z end,
        isDead = function() return false end,
        getUsername = function() return "mp-user" end,
        getOnlineID = function() return 17 end,
    }
end

local function companion(overrides)
    local record = {
        id = "npc_one",
        alive = true,
        recruited = true,
        factionID = FACTION,
        presenceState = PRESENCE_LIVE,
        x = 10,
        y = 10,
        z = 0,
    }
    for key, value in pairs(overrides or {}) do record[key] = value end
    return record
end

T.load(SHARED .. "PNC/Core/Identity/PNC_Identity_Verifier.lua")
T.load(SHARED .. "PNC/Core/Commands/PNC_CompanionCommandRegistry.lua")
local Authority = T.load("ProjectHoomans", "client",
    "PNC/Commands/PNC_ClientCompanionAuthority.lua")

T.truthy(Authority, "client authority module loaded")
PNC.CompanionCommands.Register({
    id = "follow",
    radioRelay = true,
    buildOrder = function() return { kind = "follow" } end,
})

-- ---------------------------------------------------------------------------
-- The authoritative gate is genuinely unavailable on this client.
-- ---------------------------------------------------------------------------
local nearPlayer = playerAt(10.5, 10.5, 0)
T.equal(PNC.CompanionCommands.IsOwnedByPlayer(companion(), nearPlayer), false,
    "authoritative ownership cannot resolve without the server services")
T.equal(PNC.CompanionCommands.CanPlayerCommand(companion(), nearPlayer, 20),
    false, "authoritative commandability is unavailable on a pure client")

-- ---------------------------------------------------------------------------
-- The replicated faction projection answers it instead.
-- ---------------------------------------------------------------------------
PNC.Network.ClientState.colonyManagement = { faction = { id = FACTION } }

T.equal(Authority.LocalFactionID(), FACTION, "local faction comes from the sync")
T.equal(Authority.IsOwnedByPlayer(companion(), nearPlayer), true,
    "replicated ownership authorizes a same-faction colonist")
T.equal(Authority.CanPlayerCommand(companion(), nearPlayer, 20), true,
    "nearby live colonist is commandable on a multiplayer client")

-- A different faction is never owned, even when otherwise commandable.
T.equal(Authority.IsOwnedByPlayer(companion({ factionID = "faction_other" }),
    nearPlayer), false, "a foreign faction is not owned")
T.equal(Authority.CanPlayerCommand(companion({ factionID = "faction_other" }),
    nearPlayer, 20), false, "a foreign faction is not commandable")

-- Fails closed before the client has synced any faction.
PNC.Network.ClientState.colonyManagement = nil
T.equal(Authority.LocalFactionID(), nil, "no synced faction yet")
T.equal(Authority.CanPlayerCommand(companion(), nearPlayer, 20), false,
    "un-synced client offers nothing rather than everything")
PNC.Network.ClientState.colonyManagement = { faction = { id = FACTION } }

-- The base bootstrap carries the same faction, so ownership works before the
-- colony snapshot arrives.
PNC.Network.ClientState.colonyManagement = nil
PNC.Network.ClientState.colonyBase = { faction = { id = FACTION } }
T.equal(Authority.IsOwnedByPlayer(companion(), nearPlayer), true,
    "base bootstrap faction authorizes ownership too")
PNC.Network.ClientState.colonyBase = nil
PNC.Network.ClientState.colonyManagement = { faction = { id = FACTION } }

-- ---------------------------------------------------------------------------
-- Every server rule is still reproduced, not just ownership.
-- ---------------------------------------------------------------------------
T.equal(Authority.CanPlayerCommand(companion({ recruited = false }),
    nearPlayer, 20), false, "an unrecruited NPC is not commandable")
T.equal(Authority.CanPlayerCommand(companion({ alive = false }),
    nearPlayer, 20), false, "a dead NPC is not commandable")
T.equal(Authority.CanPlayerCommand(
    companion({ presenceState = "abstract" }), nearPlayer, 20), false,
    "an abstracted NPC is not commandable")
T.equal(Authority.CanRelayCommand(
    companion({ presenceState = "abstract" }), nearPlayer, "follow"), false,
    "abstract Follow Me bypassed the unavailable relay gate")
PNC.CommandRelayGate = {
    Evaluate = function(facts)
        return facts.playerRadio == true and facts.npcRadio == true,
            facts.playerRadio == true and facts.npcRadio == true
                and "radio_relay" or "npc_radio_missing"
    end,
}
PsychopatzCore = {
    RadioDeviceState = {
        FindActivePlayerDevice = function() return {} end,
    },
}
local abstractWithRadio = companion({
    presenceState = "abstract",
    radioGear = { equipped = true },
})
T.equal(Authority.CanRelayCommand(
    abstractWithRadio, nearPlayer, "follow"), true,
    "abstract Follow Me with two radios was not relay-commandable")
PNC.CommandRelayGate = nil
PsychopatzCore = nil
T.equal(Authority.CanPlayerCommand(companion({ z = 2 }), playerAt(10.5, 10.5, 0),
    20), false, "a colonist on another floor is not commandable")
T.equal(Authority.CanPlayerCommand(companion({ x = 400, y = 400 }), nearPlayer,
    20), false, "a distant colonist is not commandable")

local reason = select(2, Authority.CanPlayerCommand(
    companion({ x = 400, y = 400 }), nearPlayer, 20))
T.equal(reason, "too_far", "distance refusal keeps the server's reason")

local notOwnerReason = select(2, Authority.CanPlayerCommand(
    companion({ factionID = "faction_other" }), nearPlayer, 20))
T.equal(notOwnerReason, "not_owner", "foreign faction refusal reason")

-- ---------------------------------------------------------------------------
-- Where the authoritative services do exist, they win.
-- ---------------------------------------------------------------------------
PNC.Factions = {
    Get = function(id)
        return {
            id = id,
            ownerPlayerKey = "player:mp",
            playerMemberKeys = { ["player:mp"] = true },
        }
    end,
}
PNC.PlayerCharacters = {
    GetCharacterUUID = function() return "uuid" end,
}
PNC.PlayerContext = {
    Peek = function() return { entityKey = "player:mp" } end,
}

T.equal(PNC.CompanionCommands.IsOwnedByPlayer(companion(), nearPlayer), true,
    "authoritative ownership resolves once the services exist")
T.equal(Authority.IsOwnedByPlayer(
    companion({ factionID = "faction_other" }), nearPlayer), true,
    "the authoritative answer is preferred over the replicated projection")

PNC.Factions = nil
PNC.PlayerCharacters = nil
PNC.PlayerContext = nil

T.equal(Authority.IsOwnedByPlayer(
    companion({ factionID = "faction_other" }), nearPlayer), false,
    "without the services the replicated projection decides again")

T.finish("pnc_client_companion_authority_smoke")
