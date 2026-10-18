local T = require "tests/support/test"

-- The baseline loads the real Hoomans identity, appearance, inventory,
-- relationship, and persistence modules, including the read-only P0B planner.
T.load("tests/pnc_npc_foundation_parity_baseline_smoke.lua")

local ImportPlan = PNC.Persistence.ImportPlan
T.truthy(ImportPlan, "P0B import planner was not loaded")

local function newRecord(id)
    return PNC.Types.NewRecord({
        id = id,
        displayName = "Parity Merchant",
        identitySeed = 731,
        archetypeID = "parity_merchant",
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

local function equalValue(left, right, seen)
    if type(left) ~= type(right) then return false end
    if type(left) ~= "table" then return left == right end
    if left == right then return true end
    seen = seen or {}
    seen[left] = seen[left] or {}
    if seen[left][right] then return true end
    seen[left][right] = true
    for key, value in pairs(left) do
        if not equalValue(value, right[key], seen) then return false end
    end
    for key in pairs(right) do
        if left[key] == nil then return false end
    end
    return true
end

local function hasDecision(plan, field, action, reason)
    local i
    for i = 1, #(plan.decisions or {}) do
        local decision = plan.decisions[i]
        if decision.field == field and decision.action == action
            and (reason == nil or decision.reason == reason)
        then
            return true
        end
    end
    return false
end

local function prepareSourceRecord(id, emptyInventory)
    local record = newRecord(id)
    record.appearance = PNC.Identity.Appearance.Normalize({
        schemaVersion = 2,
        outfit = { mode = "none" },
        slots = {
            Torso_Upper = {
                mode = "item",
                type = "Base.Jacket",
                wornSlot = "Torso_Upper",
                itemState = { modData = { source = "p0b-plan" } },
            },
        },
    })
    if emptyInventory then
        record.inventory = PNC.Inventory.Internal.createBaseInventory(record)
    else
        T.truthy(PNC.Inventory.CreateFromTemplate(record),
            "source inventory template creation")
    end
    return record
end

-- Build a current persisted payload from a real record, then provide the
-- untouched source snapshot observed before the current serializer drops the
-- authored policy and complete voice fields.
local sourceRecord = prepareSourceRecord("npc:p0b:plan", true)
T.truthy(PNC.Inventory.ApplyDelta(sourceRecord, {
    {
        op = "add",
        item = {
            id = "loot:p0b:plan",
            type = "Base.CustomLoot",
            stack = 1,
            container = "root",
            itemState = { modData = { source = "plan" } },
        },
    },
}, "p0b_import_plan_ready"), "ready source item mutation")
local rawPayload = PNC.Persistence.SerializeRecord(sourceRecord)
T.truthy(rawPayload, "current source payload")
local sourceSnapshot = ImportPlan.Copy(sourceRecord)
sourceSnapshot.schemaVersion = rawPayload.schemaVersion
local rawBefore = ImportPlan.Copy(rawPayload)
local sourceBefore = ImportPlan.Copy(sourceSnapshot)
local planOptions = {
    sourceSnapshot = sourceSnapshot,
    decisionSet = "p0b-import-plan-smoke",
}
local optionsBefore = ImportPlan.Copy(planOptions)

local ready = ImportPlan.Build(rawPayload, planOptions)
T.truthy(ImportPlan.IsReady(ready), "complete source snapshot was rejected")
T.equal(ready.candidate.schema, "PsychopatzCore.NPC",
    "canonical candidate schema")
T.equal(ready.candidate.schemaVersion, 1, "canonical candidate version")
T.equal(ready.candidate.actorId, "pnc:" .. sourceRecord.id,
    "stable actor mapping")
T.equal(ready.candidate.identity.survivor.voice.legacy,
    sourceRecord.identity.survivor.voice, "legacy voice copied")
T.equal(ready.candidate.identity.survivor.voice.prefix,
    sourceRecord.identity.survivor.voicePrefix, "voice prefix copied")
T.equal(ready.candidate.identity.survivor.voice.type,
    sourceRecord.identity.survivor.voiceType, "voice type copied")
T.equal(ready.candidate.identity.survivor.voice.pitch,
    sourceRecord.identity.survivor.voicePitch, "voice pitch copied")
T.truthy(equalValue(
    ready.candidate.appearance.policy,
    sourceSnapshot.appearance
), "authored appearance policy changed")
T.truthy(equalValue(
    ready.candidate.inventory.items,
    sourceSnapshot.inventory.items
), "personal inventory changed")
T.truthy(hasDecision(ready, "appearance.policy", "copied"),
    "appearance copy decision missing")
T.truthy(hasDecision(ready, "identity.voice", "copied"),
    "voice copy decision missing")
T.truthy(hasDecision(ready, "inventory.items", "copied"),
    "inventory copy decision missing")
T.truthy(equalValue(rawPayload, rawBefore),
    "planner mutated the raw payload")
T.truthy(equalValue(sourceSnapshot, sourceBefore),
    "planner mutated the source snapshot")
T.truthy(equalValue(planOptions, optionsBefore),
    "planner mutated its options")

-- A normal persisted payload alone is not sufficient for no-loss migration:
-- its current serializer lacks the authored policy and full voice profile.
local persistedOnly = ImportPlan.Build(rawPayload)
T.equal(persistedOnly.status, "quarantined",
    "incomplete persisted payload was accepted")
T.truthy(hasDecision(
    persistedOnly, "appearance.policy", "quarantined",
    "authored_appearance_policy_missing"
), "missing appearance was not quarantined")
T.truthy(hasDecision(
    persistedOnly, "identity.voice", "quarantined",
    "voice_profile_incomplete"
), "incomplete voice was not quarantined")
T.truthy(equalValue(persistedOnly.rawPayload, rawPayload),
    "persisted quarantine changed the source copy")

-- A source item carrying the known legacy-template metadata loss is never
-- eligible for seed/delta-only import, even when the surrounding record is
-- otherwise complete.
local legacyRecord = prepareSourceRecord("npc:p0b:legacy", true)
T.truthy(PNC.Inventory.ApplyDelta(legacyRecord, {
    {
        op = "add",
        item = {
            id = "loot:p0b:legacy",
            type = "Base.CustomLoot",
            stack = 1,
            container = "root",
            legacyTemplateKey = "legacy:p0b:item",
            itemState = { modData = { source = "legacy" } },
        },
    },
}, "p0b_import_plan_legacy"), "legacy source item mutation")
local legacyPayload = PNC.Persistence.SerializeRecord(legacyRecord)
local legacySnapshot = ImportPlan.Copy(legacyRecord)
legacySnapshot.schemaVersion = legacyPayload.schemaVersion
local legacyPlan = ImportPlan.Build(legacyPayload, {
    sourceSnapshot = legacySnapshot,
})
T.equal(legacyPlan.status, "quarantined",
    "unrepresentable legacy item was accepted")
T.equal(legacyPlan.reason, "portable_metadata_unrepresentable",
    "legacy item quarantine reason")
T.truthy(hasDecision(
    legacyPlan, "inventory.legacyTemplateKey", "quarantined",
    "portable_metadata_unrepresentable"
), "legacy template decision missing")
T.truthy(equalValue(legacyPlan.rawPayload, legacyPayload),
    "legacy quarantine changed the source copy")

-- Unsupported schemas fail closed before any candidate is built.
local unsupported = ImportPlan.Copy(rawPayload)
unsupported.schemaVersion = tonumber(rawPayload.schemaVersion) - 1
local unsupportedBefore = ImportPlan.Copy(unsupported)
local unsupportedPlan = ImportPlan.Build(unsupported)
T.equal(unsupportedPlan.status, "quarantined",
    "unsupported schema was accepted")
T.equal(unsupportedPlan.reason, "unsupported_schema",
    "unsupported schema reason")
T.falsy(unsupportedPlan.candidate, "unsupported schema produced a candidate")
T.truthy(equalValue(unsupported, unsupportedBefore),
    "unsupported source was mutated")

T.finish("pnc_npc_foundation_import_plan_smoke")
