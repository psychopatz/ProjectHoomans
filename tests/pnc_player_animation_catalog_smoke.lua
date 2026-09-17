local T = require "tests/support/test"

local CATALOG_FILE =
    T.path("ProjectHoomans", "client", "PNC/Debug/")
        .. "PNC_PlayerAnimationDebugCatalog.lua"

PNC = {}
T.load(CATALOG_FILE)

local catalog = PNC.PlayerAnimationDebugCatalog
T.truthy(catalog.generatedCount == #catalog.entries,
    "player catalog count mismatch")
T.truthy(catalog.generatedCount > 0,
    "player catalog is empty")

local lootHigh
local bandageUpper
local clap
for _, entry in ipairs(catalog.entries) do
    if entry.file == "LootHigh.xml" then lootHigh = entry end
    if entry.file == "BandageUpperBody.xml" then bandageUpper = entry end
    if entry.file == "clap.xml" then clap = entry end
end

T.truthy(lootHigh, "LootHigh player action is missing")
T.equal(lootHigh.action, "Loot", "LootHigh action context mismatch")
T.equal(lootHigh.anim, "Bob_IdleLooting_High", "LootHigh clip mismatch")
T.equal(lootHigh.variables[1].name, "LootPosition",
    "LootHigh selector name mismatch")
T.equal(lootHigh.variables[1].value, "High",
    "LootHigh selector value mismatch")
T.truthy(bandageUpper, "BandageUpperBody player action is missing")
T.equal(bandageUpper.action, "Bandage",
    "BandageUpperBody action context mismatch")
T.equal(bandageUpper.variables[1].name, "BandageType",
    "BandageUpperBody selector name mismatch")
T.equal(bandageUpper.variables[1].value, "UpperBody",
    "BandageUpperBody selector value mismatch")
T.truthy(clap, "clap player emote is missing")
T.equal(clap.mode, "emote", "clap emote mode mismatch")
T.equal(clap.emote, "clap", "clap emote key mismatch")
T.equal(clap.anim, "Bob_EmoteClap", "clap emote clip mismatch")
T.truthy(clap.looped, "clap inherited engine loop default mismatch")

T.finish("pnc_player_animation_catalog_smoke")
