local T = require "tests/support/test"

T.load("tests/pnc_npc_foundation_parity_baseline_smoke.lua")

local function copy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local output = {}
    seen[value] = output
    for key, item in pairs(value) do
        output[copy(key, seen)] = copy(item, seen)
    end
    return output
end

local function equalValue(left, right, seen)
    if type(left) ~= type(right) then return false end
    if type(left) ~= "table" then return left == right end
    seen = seen or {}
    seen[left] = seen[left] or {}
    if seen[left][right] then return true end
    seen[left][right] = true
    for key, item in pairs(left) do
        if not equalValue(item, right[key], seen) then return false end
    end
    for key in pairs(right) do
        if left[key] == nil then return false end
    end
    return true
end

local function newRecord(id)
    return PNC.Types.NewRecord({
        id = id,
        displayName = "Normal Persistence NPC",
        identitySeed = 731,
        archetypeID = "parity_merchant",
        uniqueDefinitionId = "p0b-normal",
        uniqueDefinitionVersion = 1,
        tacticalClass = "neutral",
        x = 104.5,
        y = 208.25,
        z = 0,
        anchorX = 100,
        anchorY = 200,
        anchorZ = 0,
        equipment = { worn = {}, attached = {} },
    })
end

local authoredPolicy = PNC.Identity.Appearance.Normalize({
    schemaVersion = 2,
    outfit = { mode = "none" },
    slots = {
        Torso_Upper = {
            mode = "item",
            type = "Base.Jacket",
            wornSlot = "Torso_Upper",
            itemState = { modData = { source = "normal-persistence" } },
        },
    },
})
local authored = newRecord("npc:p0b:normal:authored")
authored.appearance = copy(authoredPolicy)
authored.appearanceAuthored = true
local authoredPayload = PNC.Persistence.SerializeRecord(authored)
T.truthy(authoredPayload, "authored normal payload")
T.truthy(authoredPayload.appearance, "authored policy missing")
T.equal(authoredPayload.appearance.schemaVersion, 2,
    "authored policy schema changed")
T.equal(authoredPayload.appearanceContract.schemaVersion, 1,
    "appearance contract schema")
T.equal(authoredPayload.appearanceContract.mode, "AUTHORED_POLICY",
    "authored appearance mode")
T.truthy(equalValue(authoredPayload.appearance, authoredPolicy),
    "authored policy changed during serialization")

local restoredAuthored = PNC.Persistence.DeserializeRecord(
    authoredPayload, authored.id)
T.truthy(restoredAuthored, "authored normal payload rejected")
T.truthy(restoredAuthored.appearanceAuthored,
    "authored state was not restored")
T.truthy(equalValue(restoredAuthored.appearance, authoredPolicy),
    "authored policy changed during normal round-trip")
T.equal(restoredAuthored.identity.survivor.voice,
    authored.identity.survivor.voice, "legacy voice changed")
T.equal(restoredAuthored.identity.survivor.voiceProfile.voice,
    authored.identity.survivor.voice, "voice profile voice changed")
T.equal(restoredAuthored.identity.survivor.voiceProfile.voicePrefix,
    authored.identity.survivor.voicePrefix, "voice prefix changed")
T.equal(restoredAuthored.identity.survivor.voiceProfile.voiceType,
    authored.identity.survivor.voiceType, "voice type changed")
T.near(restoredAuthored.identity.survivor.voiceProfile.voicePitch,
    authored.identity.survivor.voicePitch, 0.000001, "voice pitch changed")
T.equal(restoredAuthored.identity.survivor.voicePrefix,
    authored.identity.survivor.voicePrefix, "record voice prefix changed")
T.equal(restoredAuthored.identity.survivor.voiceType,
    authored.identity.survivor.voiceType, "record voice type changed")
T.near(restoredAuthored.identity.survivor.voicePitch,
    authored.identity.survivor.voicePitch, 0.000001,
    "record voice pitch changed")
T.truthy(restoredAuthored.identity.survivor.voiceProfile.complete,
    "complete voice marker changed")

local generated = newRecord("npc:p0b:normal:generated")
local generatedPayload = PNC.Persistence.SerializeRecord(generated)
T.truthy(generatedPayload, "generated normal payload")
T.equal(generatedPayload.appearance, nil,
    "generated NPC unexpectedly gained authored policy")
T.equal(generatedPayload.appearanceContract.mode, "GENERATED_DEFAULT",
    "generated appearance mode")
T.equal(generatedPayload.appearanceContract.authored, false,
    "generated appearance authored marker")
local restoredGenerated = PNC.Persistence.DeserializeRecord(
    generatedPayload, generated.id)
T.truthy(restoredGenerated, "generated normal payload rejected")
T.falsy(restoredGenerated.appearance,
    "generated NPC acquired authored policy")
T.falsy(restoredGenerated.appearanceAuthored,
    "generated NPC was treated as authored")
T.equal(restoredGenerated.identity.survivor.voiceProfile.voicePrefix,
    generated.identity.survivor.voicePrefix, "generated voice prefix changed")

-- An older payload with only the legacy voice field remains incomplete.  The
-- loader must preserve what exists and must not invoke SurvivorFactory to
-- invent the missing profile values.
local incomplete = copy(authoredPayload)
incomplete.identity.survivor.voiceProfile = nil
incomplete.appearanceContract = nil
local restoredIncomplete = PNC.Persistence.DeserializeRecord(
    incomplete, authored.id)
T.truthy(restoredIncomplete, "legacy incomplete payload was rejected")
T.equal(restoredIncomplete.identity.survivor.voice,
    authored.identity.survivor.voice, "legacy voice changed")
T.equal(restoredIncomplete.identity.survivor.voicePrefix, nil,
    "missing voice prefix was invented")
T.equal(restoredIncomplete.identity.survivor.voiceType, nil,
    "missing voice type was invented")
T.equal(restoredIncomplete.identity.survivor.voicePitch, nil,
    "missing voice pitch was invented")

local unsupported = copy(authoredPayload)
unsupported.appearance.schemaVersion = 1
T.equal(PNC.Persistence.DeserializeRecord(unsupported, authored.id), nil,
    "unsupported appearance policy was accepted")

T.finish("pnc_npc_foundation_normal_persistence_smoke")
