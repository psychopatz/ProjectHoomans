-- Generator provenance classification for the read-only P0B import planner.

local Utils = require
    "PNC/Core/Persistence/PNC_Persistence/PNC_Persistence_ImportPlan_Utils"

local Generator = {}
local Const = PNC.Const or {}

local function add(decisions, ...)
    return Utils.AddDecision(decisions, ...)
end

local function sameValue(left, right)
    if left == nil or right == nil then return left == right end
    if type(left) == "number" or type(right) == "number" then
        return tonumber(left) == tonumber(right)
    end
    return tostring(left) == tostring(right)
end

local function countItems(items)
    local count = 0
    local key
    if type(items) ~= "table" then return count end
    for key in pairs(items) do count = count + 1 end
    return count
end

function Generator.Check(source, identity, decisions, options)
    local inventory = source and source.inventory
    local template = inventory and inventory.template
    local provenanceOptions = options and options.generatorProvenance or {}
    local expectedGenerator = tonumber(options and options.generatorVersion)
        or tonumber(Const.GENERATOR_VERSION) or 1
    local expectedPool = source and source.runtime
        and source.runtime.spawnEquipmentPool
        or source and source.equipmentPoolID
    local expectedDefinition = provenanceOptions.definitionRevision
        or source and source.uniqueDefinitionVersion
    local expectedTemplateRef = source and source.inventoryTemplateRef
    local expectedPolicyHash = provenanceOptions.policyHash
    local checks = {}
    local mismatch = false
    local incomplete = false
    local mode
    local itemCount
    local policyHash
    local i
    if type(inventory) ~= "table" or type(template) ~= "table" then
        add(decisions, "appearance.generator", "quarantined",
            "inventory.template", "generator_provenance_incomplete")
        return nil
    end
    checks[1] = {
        "generatorVersion", tonumber(template.generatorVersion),
        expectedGenerator,
    }
    checks[2] = {
        "archetypeID", template.archetypeID,
        identity and identity.archetypeID,
    }
    checks[3] = {
        "seed", tonumber(template.seed), identity and identity.seed,
    }
    checks[4] = {
        "equipmentPoolID", template.equipmentPoolID, expectedPool,
    }
    checks[5] = {
        "templateRef", template.templateRef, expectedTemplateRef,
        expectedTemplateRef ~= nil,
    }
    if expectedDefinition ~= nil then
        checks[#checks + 1] = {
            "definitionRevision", template.definitionRevision,
            expectedDefinition,
        }
    end
    mode = tostring(inventory.persistenceMode or "")
    itemCount = countItems(inventory.items)
    policyHash = source and source.appearance
        and Utils.Hash(source.appearance, PNC.Identity) or nil
    if expectedPolicyHash ~= nil then
        checks[#checks + 1] = {
            "policyHash", policyHash, expectedPolicyHash,
        }
    elseif mode == "SEED_ONLY" and itemCount == 0 then
        incomplete = true
    end
    for i = 1, #checks do
        if checks[i][2] == nil and checks[i][4] ~= false then
            incomplete = true
        elseif checks[i][3] ~= nil and not sameValue(
            checks[i][2], checks[i][3]
        ) then
            mismatch = true
        end
    end
    local result = {
        currentGeneratorVersion = expectedGenerator,
        sourceGeneratorVersion = tonumber(template.generatorVersion),
        archetypeID = template.archetypeID,
        seed = tonumber(template.seed),
        equipmentPoolID = template.equipmentPoolID,
        templateRef = template.templateRef,
        definitionRevision = template.definitionRevision,
        policyHash = policyHash,
        expectedPolicyHash = expectedPolicyHash,
    }
    if mismatch or incomplete then
        if mode == "SEED_ONLY" and itemCount == 0 then
            add(decisions, "appearance.generator", "quarantined",
                "inventory.template", mismatch
                    and "generator_provenance_mismatch"
                    or "generator_provenance_incomplete")
            return nil
        end
        result.restoration = "SOURCE_AUTHORITATIVE"
        add(decisions, "appearance.generator", "projected",
            "inventory.template",
            mismatch and "generator_provenance_mismatch_source_authoritative"
                or "generator_provenance_incomplete_source_authoritative")
        return result
    end
    result.restoration = "SEED_COMPATIBLE"
    add(decisions, "appearance.generator", "verified",
        "inventory.template", nil)
    return result
end

return Generator
