local T = require "tests/support/test"

T.addPackagePaths()

local Catalog = require "PNC/ConvoEngine/Dialogue/ResponseCatalog"
local Core = require "PNC/ConvoEngine/Dialogue/ResponseCatalog_Core"
require "PNC/ConvoEngine/ResponseCatalog/Generated/Init"

local allowedFields = {}
for _, field in ipairs(Core.CONDITION_FIELDS or {}) do
    allowedFields[tostring(field)] = true
end

local unknownKeys = {}
local duplicateVariantIDs = {}
local missingIndexPools = {}
local actualPoolCount = 0

for poolID, pool in pairs(Catalog.POOLS or {}) do
    actualPoolCount = actualPoolCount + 1
    if type(pool.byID) ~= "table" or type(pool._evalOrder) ~= "table" then
        missingIndexPools[#missingIndexPools + 1] = tostring(poolID)
    end
    local seenIDs = {}
    for _, variant in ipairs(pool.variants or {}) do
        local vid = tostring(variant.id or "")
        if vid ~= "" then
            if seenIDs[vid] then
                duplicateVariantIDs[#duplicateVariantIDs + 1] = tostring(poolID) .. ":" .. vid
            end
            seenIDs[vid] = true
        end
        if type(variant.when) == "table" then
            for key in pairs(variant.when) do
                if not allowedFields[tostring(key)] then
                    unknownKeys[#unknownKeys + 1] = tostring(poolID) .. ":" .. vid .. "." .. tostring(key)
                end
            end
        end
    end
end

table.sort(unknownKeys)
table.sort(duplicateVariantIDs)
table.sort(missingIndexPools)

T.equal(Catalog.MAX_POOLS, nil, "ResponseCatalog has no hard pool cap")
T.equal(Catalog.POOL_COUNT, actualPoolCount, "Catalog.POOL_COUNT matches actual pool count")
T.equal(#missingIndexPools, 0, "all pools have precomputed byID/_evalOrder indices: " .. table.concat(missingIndexPools, ", "))
T.equal(#duplicateVariantIDs, 0, "no duplicate variant IDs: " .. table.concat(duplicateVariantIDs, ", "))
T.equal(#unknownKeys, 0, "all when-condition keys are registered in CONDITION_FIELDS: " .. table.concat(unknownKeys, ", "))

print("pnc_response_catalog_integrity_smoke: ok (pools=" .. tostring(actualPoolCount) .. ")")
