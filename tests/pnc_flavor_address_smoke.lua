local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
})

PNC = {}
getText = function(key) return key end

T.load("ProjectHoomans", "shared",
    "PNC/Core/Identity/PNC_FlavorAddress.lua")

local Address = PNC.FlavorAddress
local femalePlayer = {
    isFemale = function() return true end,
    getDisplayName = function() return "Alexandra Mercer" end,
    getDescriptor = function()
        return {
            isFemale = function() return true end,
            getForename = function() return "Alexandra" end,
            getSurname = function() return "Mercer" end,
        }
    end,
}

local first = Address.ResolvePlayer({
    npcID = "npc-one",
    npcIdentitySeed = 101,
    player = femalePlayer,
    playerUUID = "character-one",
})
local repeated = Address.ResolvePlayer({
    npcID = "npc-one",
    npcIdentitySeed = 101,
    player = femalePlayer,
    playerUUID = "character-one",
})
T.equal(first.isFemale, true, "resolver preserves canonical isFemale flag")
T.equal(first.genderKey, nil, "resolver does not introduce a genderKey alias")
T.equal(first.known, false, "unknown player name defaults to masked")
T.equal(first.addressName, repeated.addressName,
    "same NPC seed and player identity keep the same nickname")
T.equal(first.firstName, first.addressName,
    "unknown first name uses the safe address")
T.equal(first.fullName, first.addressName,
    "unknown full name uses the safe address")
T.equal(first.surname, "", "unknown surname is empty")
T.falsy(string.find(first.addressName, "Alexandra", 1, true),
    "unknown address does not contain the real first name")
T.falsy(string.find(first.addressName, "Mercer", 1, true),
    "unknown address does not contain the real surname")

local known = Address.ResolvePlayer({
    npcID = "npc-one",
    npcIdentitySeed = 101,
    player = femalePlayer,
    playerUUID = "character-one",
    playerNameKnown = true,
})
T.equal(known.known, true, "explicit name knowledge exposes identity")
T.equal(known.firstName, "Alexandra", "known first name is authoritative")
T.equal(known.fullName, "Alexandra Mercer",
    "known full name is authoritative")
T.equal(known.surname, "Mercer", "known surname is authoritative")

local mapped = Address.ResolveForNPC({
    npcID = "npc-one",
    npcIdentitySeed = 101,
    player = femalePlayer,
    playerUUID = "character-one",
    state = {
        playerNameKnowledge = {
            ["npc-one"] = { ["character-one"] = true },
        },
    },
})
T.equal(mapped.known, true,
    "directional player-name knowledge map is respected")

local male = Address.ResolvePlayer({
    npcID = "npc-one",
    npcIdentitySeed = 101,
    playerUUID = "character-one",
    isFemale = false,
})
T.equal(male.isFemale, false, "default pool uses isFemale false")
T.truthy(male.nicknameID ~= nil, "default nickname pool returns an entry")

local differentNPC = Address.ResolvePlayer({
    npcID = "npc-two",
    npcIdentitySeed = 202,
    playerUUID = "character-one",
    isFemale = false,
})
T.truthy(differentNPC.nicknameID ~= nil,
    "different NPC identity seed resolves independently")
T.truthy(differentNPC.addressName ~= male.addressName,
    "different NPC identity seeds select different addresses")

local applied = {}
local _, appliedAddress = Address.ApplyPlayer(applied, {
    npcID = "npc-one",
    npcIdentitySeed = 101,
    player = femalePlayer,
    playerUUID = "character-one",
})
T.equal(applied.player, applied.playerAddressName,
    "context uses the canonical safe address field")
T.equal(applied.playerNameKnown, false,
    "applied context carries the knowledge state")
T.equal(appliedAddress.known, false,
    "ApplyPlayer returns the resolved address")

T.finish("pnc_flavor_address_smoke")
