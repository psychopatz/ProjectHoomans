-- Dynamic semantic concept & pattern conflict detector.
-- Loads every semantic catalog and pack together, detects equal-priority alias
-- collisions across distinct concepts, and verifies every single-concept pattern
-- resolves cleanly instead of silently collapsing to 0 candidates.

local repoRoot = "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
local coreRoot = "/home/psychopatz/Zomboid/Workshop/psychopatzCore"
local dtRoot = "/home/psychopatz/Zomboid/Workshop/DynamicTrading"

package.path = table.concat({
    repoRoot .. "/Contents/mods/ProjectHoomans/42.20/media/lua/shared/?.lua",
    repoRoot .. "/Contents/mods/ProjectHoomans/common/media/lua/shared/?.lua",
    coreRoot .. "/Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua",
    dtRoot .. "/Contents/mods/DTCommon/42.20/media/lua/shared/?.lua",
    package.path,
}, ";")

local Sem = require "PsychopatzCore/Semantics/PsychopatzSemantic"
require "PNC/Semantics/PNC_SemanticCatalog"
pcall(require, "PNC/Semantics/PNC_SemanticConsumptionCatalog")
require "PNC/Semantics/PNC_CoreSemanticPack"
pcall(require, "DTCommon/DTCommon_SemanticPack")

local Registry = Sem.Registry
local Parser = Sem.Parser

-- 1. Detect equal-priority alias collisions across distinct concepts.
local aliasOwners = {}
local conceptIDs = Registry.ListConcepts()
for _, cid in ipairs(conceptIDs) do
    local concept = Registry.GetConcept(cid)
    if type(concept) == "table" and type(concept.aliases) == "table" then
        local pri = tonumber(concept.priority) or 1
        for _, rawAlias in ipairs(concept.aliases) do
            local alias = string.lower(tostring(rawAlias or ""))
            if alias ~= "" then
                aliasOwners[alias] = aliasOwners[alias] or {}
                aliasOwners[alias][#aliasOwners[alias] + 1] = {
                    id = tostring(cid),
                    priority = pri,
                }
            end
        end
    end
end

local collisions = {}
for alias, owners in pairs(aliasOwners) do
    if #owners > 1 then
        table.sort(owners, function(a, b)
            if a.priority ~= b.priority then return a.priority > b.priority end
            return a.id < b.id
        end)
        -- Equal top priority between two distinct concepts creates an ambiguous symbol.
        if owners[1].priority == owners[2].priority then
            local names = {}
            for _, o in ipairs(owners) do
                if o.priority == owners[1].priority then
                    names[#names + 1] = o.id .. "(pri=" .. tostring(o.priority) .. ")"
                end
            end
            collisions[#collisions + 1] = string.format(
                'alias="%s" -> %s', alias, table.concat(names, " vs ")
            )
        end
    end
end
table.sort(collisions)

-- 2. Verify every single-concept pattern resolves at least its first alias to >= 1 candidate.
local brokenPatterns = {}
local patterns = Registry.GetPatterns() or {}
for _, pat in ipairs(patterns) do
    local seq = pat and (pat.sequence or pat.match or pat.tokens) or nil
    if type(seq) == "table" and #seq == 1 then
        local step = seq[1]
        local cid = nil
        if type(step) == "string" and string.sub(step, 1, 1) == "@" then
            cid = string.sub(step, 2)
        elseif type(step) == "table" and (step.kind == "concept" or step.concept) then
            cid = step.id or step.concept
        end
        if cid then
            local concept = Registry.GetConcept(cid)
            local aliases = concept and concept.aliases or {}
            if #aliases > 0 then
                local sample = tostring(aliases[1])
                local caps = {}
                for _, c in ipairs(pat.capabilitiesRequired or {}) do caps[c] = true end
                local bundle = Parser.ParseCandidates(sample, {
                    capabilities = (#(pat.capabilitiesRequired or {}) > 0) and caps or nil,
                })
                local count = bundle and type(bundle.candidates) == "table" and #bundle.candidates or 0
                if count == 0 then
                    brokenPatterns[#brokenPatterns + 1] = string.format(
                        'pattern="%s" concept="%s" sample="%s" -> 0 candidates',
                        tostring(pat.id), tostring(cid), sample
                    )
                end
            end
        end
    end
end
table.sort(brokenPatterns)

if #collisions > 0 or #brokenPatterns > 0 then
    if #collisions > 0 then
        print("CONCEPT_COLLISIONS (" .. tostring(#collisions) .. "):")
        for _, line in ipairs(collisions) do print("  " .. line) end
    end
    if #brokenPatterns > 0 then
        print("BROKEN_SINGLE_CONCEPT_PATTERNS (" .. tostring(#brokenPatterns) .. "):")
        for _, line in ipairs(brokenPatterns) do print("  " .. line) end
    end
    error("Semantic concept conflict check failed: "
        .. tostring(#collisions) .. " collision(s), "
        .. tostring(#brokenPatterns) .. " broken pattern(s)")
end

print("PASS pnc_semantic_concept_conflict_smoke concepts=" .. tostring(#conceptIDs)
    .. " patterns=" .. tostring(#patterns))
