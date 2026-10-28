local T = require "tests/support/test"
T.addPackagePaths()
PNC = {}
local Providers = require "PNC/Semantics/PNC_SemanticInteractionProviders"
T.truthy(Providers.RegisterEvidenceAdapter({ id = "aaa.mutating_filter", sourceTier = "SESSION",
    Query = function(_, query) query.actorID = "intruder"; return {} end }))
local terms = {}
for index = 1, 100 do terms[index] = "term:" .. tostring(index) .. string.rep("x", 180) end
local accepted = 0
for adapterIndex = 1, 32 do
    local id = "fixture.bounds." .. tostring(adapterIndex)
    local ok, reason = Providers.RegisterEvidenceAdapter({ id = id, sourceTier = "SESSION",
        Query = function(_, query)
            T.equal(query.actorID, "a", "one callback cannot mutate another callback's filter")
            local rows = {}
            for index = 1, 40 do rows[index] = { sourceRef = id .. ":" .. tostring(index),
                actorID = "a", targetID = "b", eventType = string.rep("e", 200),
                relations = { opens = terms }, classes = terms, tags = terms,
                retentionSalience = 999, confidence = math.huge, effectiveStrength = -1,
                ageHours = -5, arbitrary = { "not copied" }, rawText = "not copied" } end
            return rows
        end })
    if ok then accepted = accepted + 1 else T.equal(reason, "evidence_adapter_limit", "adapter limit is explicit") end
end
T.truthy(accepted > 0 and accepted < 16, "first-party and addon providers share one hard bound")
local result = Providers.QueryEvidence({}, { actorID = "a", targetID = "b" })
T.equal(#result.rows, 16, "result rows are bounded regardless of callback output")
T.equal(#result.providers, 16, "provider diagnostics are bounded")
for _, row in ipairs(result.rows) do
    T.equal(#row.eventType, 128, "identifiers bounded")
    T.equal(#row.relations.opens, 8, "relation terms bounded")
    T.equal(#row.classes, 8, "classes bounded")
    T.equal(#row.tags, 8, "tags bounded")
    T.equal(row.retentionSalience, 255, "salience clamps independently")
    T.falsy(row.confidence, "non-finite confidence excluded")
    T.equal(row.effectiveStrength, 0, "strength clamps independently")
    T.equal(row.ageHours, 0, "recency clamps independently")
    T.falsy(row.arbitrary, "arbitrary payload excluded")
    T.falsy(row.rawText, "transcript text excluded")
end
T.finish("pnc_semantic_evidence_bounds_smoke")
