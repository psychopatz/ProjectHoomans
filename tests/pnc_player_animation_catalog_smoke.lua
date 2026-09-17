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
T.equal(catalog.sourceCounts.player_native, 443,
    "native player catalog count changed unexpectedly")
T.equal(catalog.sourceCounts.player_mod, 3,
    "mod player catalog count mismatch")
T.equal(catalog.sourceCounts.zombie, 466,
    "zombie catalog count mismatch")
T.truthy(catalog.bridgeCount > 0, "player bridge catalog is empty")

local lootHigh
local bandageUpper
local clap
local zombieChop
local zombieAttack
local zombiePathfind
local zombieUnsupported
local zombieSleepBed
local zombieSit
local zombieAwakeBed
local nativeSatChair
local nativeSatChairIn
for _, entry in ipairs(catalog.entries) do
    if entry.file == "LootHigh.xml" then lootHigh = entry end
    if entry.file == "BandageUpperBody.xml" then bandageUpper = entry end
    if entry.file == "clap.xml" then clap = entry end
    if entry.source == "zombie" and entry.node == "PNC_Anim_ChopTree"
    then
        zombieChop = entry
    end
    if entry.source == "zombie" and entry.node == "PNC_Anim_Attack2H4"
    then
        zombieAttack = entry
    end
    if entry.source == "zombie" and entry.sourceState == "zombie/pathfind"
        and entry.node == "PNC_Anim_Walk2handed"
    then
        zombiePathfind = entry
    end
    if entry.source == "zombie" and entry.playable ~= true
    then
        zombieUnsupported = entry
    end
    if entry.source == "zombie" and entry.node == "PNC_Anim_SleepBed"
    then
        zombieSleepBed = entry
    end
    if entry.source == "zombie" and entry.node == "PNC_Anim_Sit"
    then
        zombieSit = entry
    end
    if entry.source == "zombie" and entry.node == "PNC_Anim_AwakeBed"
    then
        zombieAwakeBed = entry
    end
    if entry.source == "player_native" and entry.file == "SatChair.xml"
    then
        nativeSatChair = entry
    end
    if entry.source == "player_native" and entry.file == "SatChairIn.xml"
    then
        nativeSatChairIn = entry
    end
end

T.truthy(lootHigh, "LootHigh player action is missing")
T.equal(lootHigh.action, "Loot", "LootHigh action context mismatch")
T.equal(lootHigh.sourceState, "player/actions",
    "native action source state mismatch")
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

T.falsy(zombieChop,
    "zombie chop-tree duplicate was redundantly re-added to player catalog")

T.truthy(zombieAttack, "zombie attack animation is missing")
T.equal(zombieAttack.route, "player_bridge",
    "zombie attack did not receive player bridge route")
T.truthy(zombieAttack.playable,
    "zombie attack bridge is not playable")

T.truthy(zombiePathfind, "zombie pathfind animation is missing")
T.equal(zombiePathfind.route, "player_bridge",
    "zombie pathfind did not receive player bridge route")
T.truthy(zombiePathfind.playable,
    "zombie pathfind bridge is not playable")

T.truthy(zombieUnsupported,
    "catalog has no explicit no-clip zombie audit row")
T.equal(catalog.dedupe.zombieRowsRemoved, 73,
    "resolved player/zombie duplicate row count changed unexpectedly")
T.equal(catalog.dedupe.zombieClipsRemoved, 60,
    "resolved player/zombie duplicate clip count changed unexpectedly")
T.equal(catalog.bridgeCount, 462,
    "non-duplicate resolved player/zombie clips should have bridges")
T.equal(catalog.fullBodyBridgeCount, 25,
    "full-body zombie bridge count changed unexpectedly")

T.truthy(nativeSatChair, "native chair-sit animation is missing")
T.equal(nativeSatChair.mode, "emote",
    "chair-sit preview did not use the full-body emote bridge")
T.equal(nativeSatChair.route, "player_emote_bridge",
    "chair-sit preview did not use the full-body bridge route")
T.truthy(nativeSatChair.fullBody,
    "chair-sit preview was not marked full-body")
T.falsy(nativeSatChair.action,
    "chair-sit preview incorrectly used the action selector")
T.contains(nativeSatChair.bridgePath, "player/emote/",
    "chair-sit bridge was not emitted into the player emote graph")

T.truthy(nativeSatChairIn, "native chair-sit-in animation is missing")
T.equal(nativeSatChairIn.mode, "emote",
    "chair-sit-in preview did not use the full-body emote bridge")
T.falsy(nativeSatChairIn.looped,
    "chair-sit-in source unexpectedly became looped")

T.truthy(zombieSleepBed, "zombie sleep-bed animation is missing")
T.equal(zombieSleepBed.mode, "emote",
    "sleep-bed preview did not use the player emote state")
T.equal(zombieSleepBed.route, "player_emote_bridge",
    "sleep-bed preview did not use the full-body bridge route")
T.truthy(zombieSleepBed.fullBody,
    "sleep-bed preview was not marked full-body")
T.falsy(zombieSleepBed.action,
    "sleep-bed preview incorrectly used an action selector")
T.contains(zombieSleepBed.bridgePath, "player/emote/",
    "sleep-bed bridge was not emitted into the player emote graph")

T.truthy(zombieSit, "zombie ground-sit animation is missing")
T.equal(zombieSit.mode, "emote",
    "ground-sit preview did not use the player emote state")
T.truthy(zombieSit.fullBody,
    "ground-sit preview was not marked full-body")

T.truthy(zombieAwakeBed, "zombie awake-bed animation is missing")
T.falsy(zombieAwakeBed.looped,
    "awake-bed source unexpectedly became looped")

local bridgeSource = T.read("ProjectHoomans", "common",
    "AnimSets/player/actions/" .. zombieAttack.bridgeFile)
T.contains(bridgeSource, "<m_Name>" .. zombieAttack.action .. "</m_Name>",
    "bridge node name mismatch")
T.contains(bridgeSource, "<m_AnimName>" .. zombieAttack.anim .. "</m_AnimName>",
    "bridge clip mismatch")
T.contains(bridgeSource, "<m_Name>PerformingAction</m_Name>",
    "bridge does not use the player action selector")
T.contains(bridgeSource, "<m_Value>" .. zombieAttack.action .. "</m_Value>",
    "bridge action selector value mismatch")
T.contains(zombieAttack.action, "PNC_PH_",
    "bridge action does not use the compact PNC namespace")
T.falsy(string.find(bridgeSource, "BumpType", 1, true),
    "bridge leaked the zombie BumpType condition")
T.falsy(string.find(bridgeSource, "PNCActor", 1, true),
    "bridge leaked the zombie actor condition")
T.falsy(string.find(bridgeSource, "BumpAnimFinished", 1, true),
    "bridge leaked the zombie completion event")

local fullBodyBridgeSource = T.read("ProjectHoomans", "common",
    "AnimSets/player/emote/" .. zombieSleepBed.bridgeFile)
T.contains(fullBodyBridgeSource,
    "<m_Name>" .. zombieSleepBed.emote .. "</m_Name>",
    "full-body bridge node name mismatch")
T.contains(fullBodyBridgeSource, "<m_Name>emote</m_Name>",
    "full-body bridge does not use the player emote selector")
T.contains(fullBodyBridgeSource, "<boneName>Bip01</boneName>",
    "full-body bridge does not mask from the skeleton root")
T.contains(fullBodyBridgeSource, "<includeDescendants>true</includeDescendants>",
    "full-body bridge does not include skeleton descendants")
T.falsy(string.find(fullBodyBridgeSource, "PerformingAction", 1, true),
    "full-body bridge fell back to the action selector")

local oneShotBridgeSource = T.read("ProjectHoomans", "common",
    "AnimSets/player/emote/" .. zombieAwakeBed.bridgeFile)
T.contains(oneShotBridgeSource, "<m_EventName>EmoteFinishing</m_EventName>",
    "one-shot full-body bridge cannot leave PlayerEmoteState")

local chairBridgeSource = T.read("ProjectHoomans", "common",
    "AnimSets/player/emote/" .. nativeSatChair.bridgeFile)
T.contains(chairBridgeSource, "<m_Name>emote</m_Name>",
    "chair-sit bridge does not use the player emote selector")
T.contains(chairBridgeSource, "<m_AnimName>Bob_SatChair</m_AnimName>",
    "chair-sit bridge clip mismatch")
T.falsy(string.find(chairBridgeSource, "SatChairStarted", 1, true),
    "chair-sit bridge leaked the furniture-state condition")

T.finish("pnc_player_animation_catalog_smoke")
