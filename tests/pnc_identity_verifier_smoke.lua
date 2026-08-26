local T = require "tests/support/test"

local FILE = T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Identity/PNC_Identity_Verifier.lua"
)

local factions = {
    faction_alpha = {
        id = "faction_alpha",
        name = "Alpha Colony",
        archetypeID = "settler",
        ownerPlayerKey = "player:account:char_alpha",
        playerMemberKeys = {
            ["player:account:char_alpha"] = true,
            ["player:account:char_beta"] = true,
        },
    },
    faction_raiders = {
        id = "faction_raiders",
        name = "Raiders",
        archetypeID = "raider",
        playerMemberKeys = {},
    },
}

local records = {
    alpha = {
        id = "npc_alpha",
        tacticalClass = "colonist",
        recruited = true,
        affiliation = {
            factionID = "faction_alpha",
            membershipStatus = "member",
            role = "civilian",
            rank = "member",
        },
    },
    raider = {
        id = "npc_raider",
        tacticalClass = "colonist",
        recruited = false,
        affiliation = { factionID = "faction_raiders" },
    },
    factionless = {
        id = "npc_factionless",
        tacticalClass = "colonist",
        recruited = true,
        ownerUsername = "alice",
    },
    hostile = {
        id = "npc_hostile",
        tacticalClass = "colonist",
        recruited = false,
        hostility = { attackPlayers = true },
    },
}

local function player(username, uuid)
    return {
        getUsername = function() return username end,
        getOnlineID = function() return username == "alice" and 7 or 8 end,
        uuid = uuid,
    }
end

local alice = player("alice", "char_alpha")
local bob = player("bob", "char_beta")
local outsider = player("outsider", "char_outsider")

PNC = {
    FactionTypes = {
        IsValidFactionID = function(value)
            return type(value) == "string"
                and string.sub(value, 1, 8) == "faction_"
        end,
    },
    Factions = {
        Get = function(id) return factions[id] end,
        GetFactionForPlayerKey = function(key)
            if key == "player:account:char_alpha"
                or key == "player:account:char_beta"
            then
                return factions.faction_alpha
            end
            return nil
        end,
        IsMember = function(id, npcID)
            local record = records[npcID == "npc_alpha" and "alpha"
                or npcID == "npc_raider" and "raider" or "factionless"]
            return record and record.affiliation
                and record.affiliation.factionID == id or false
        end,
    },
    PlayerContext = {
        Peek = function() return nil end,
    },
    PlayerCharacters = {
        GetCharacterUUID = function(value) return value.uuid end,
        Registry = {
            byUUID = {
                char_alpha = { accountKey = "account" },
                char_beta = { accountKey = "account" },
                char_outsider = { accountKey = "other" },
            },
        },
    },
    EntityRef = {
        ForPlayerIdentity = function(account, uuid)
            return "player:" .. account .. ":" .. uuid
        end,
    },
}

local Verifier = T.load(FILE)

T.equal(Verifier.GetFactionID(records.alpha), "faction_alpha",
    "affiliation factionID should be authoritative")
T.equal(Verifier.GetFactionID({
    factionID = "faction_alpha",
}), "faction_alpha", "payload factionID should be readable")
T.equal(Verifier.GetFactionID({
    record = { id = "npc_alpha" },
    snapshot = { factionID = "faction_alpha" },
}), "faction_alpha", "snapshot fallback should be readable")

T.equal(Verifier.IsOwnedByPlayer(records.alpha, alice), true,
    "faction owner should own NPC")
T.equal(Verifier.IsOwnedByPlayer(records.alpha, bob), true,
    "second player in same faction should own NPC")
T.equal(Verifier.IsOwnedByPlayer(records.alpha, outsider), false,
    "unaffiliated player should not own NPC")
T.equal(Verifier.GetPlayerFactionID(bob), "faction_alpha",
    "player faction should resolve from character-scoped key")
T.equal(Verifier.IsColonyOwnedNPC(records.alpha), true,
    "player faction NPC should be colony-owned")
T.equal(Verifier.IsColonyOwnedNPC(records.raider), false,
    "non-player faction NPC should not be colony-owned")
T.equal(Verifier.IsColonyOwnedNPC(records.hostile), false,
    "tactical class should not make NPC colony-owned")
T.equal(Verifier.IsColonyOwnedNPC(records.factionless), false,
    "factionless recruited NPC should be readable but not owned")

local view = Verifier.BuildView(records.alpha, { player = bob })
T.equal(view.factionID, "faction_alpha", "view factionID")
T.equal(view.tacticalClass, nil, "public identity view omits tactical class")
T.equal(view.viewerOwned, true, "view resolves faction membership")
T.equal(view.identitySource, "factionID", "view identifies authority")
T.equal(view.identityVerified, true, "view verifier status")

local factionlessVerification = Verifier.Verify(records.factionless)
T.equal(factionlessVerification.ok, true, "factionless payload remains readable")
T.equal(#factionlessVerification.warnings, 0,
    "identity verification does not emit compatibility warnings")
local requiredVerification = Verifier.Verify(records.factionless, {
    requireFaction = true,
})
T.equal(requiredVerification.ok, false,
    "strict consumers should require factionID")
local invalidVerification = Verifier.Verify({
    id = "npc_invalid",
    factionID = "wrong",
})
T.equal(invalidVerification.ok, false,
    "invalid factionID should fail verification")

PNC.Registry = {
    Get = function(id) return id == "npc_alpha" and records.alpha or nil end,
}
PNC.Network = {
    ClientState = {
        snapshots = {
            npc_raider = records.raider,
        },
    },
}
local IdentityAPI = T.load(T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/API/PNC_API/Identity.lua"
))
local capabilities = IdentityAPI.GetCapabilities()
T.equal(capabilities.factionAuthority, "factionID",
    "public API should advertise factionID authority")
T.equal(capabilities.multiPlayerFaction, true,
    "public API should advertise shared player factions")
T.equal(IdentityAPI.Get("npc_alpha", { player = bob }).viewerOwned,
    true, "public API should expose verified ownership")
T.equal(IdentityAPI.Get("npc_raider").colonyOwned, false,
    "public API should not treat an NPC faction as colony-owned")
T.equal(IdentityAPI.GetPlayerFactionID(bob), "faction_alpha",
    "public API should resolve a character-scoped player faction")
T.equal(IdentityAPI.ResolveOwnership("npc_alpha", bob), true,
    "public API should resolve shared-faction ownership")
T.equal(IdentityAPI.IsOwnedByPlayer("npc_alpha", outsider), false,
    "public API should reject an outsider")
T.equal(IdentityAPI.VerifyPayload({ id = "npc_alpha",
    factionID = "faction_alpha" }).ok, true,
    "public API should verify transport payloads")

T.finish("pnc_identity_verifier_smoke")
