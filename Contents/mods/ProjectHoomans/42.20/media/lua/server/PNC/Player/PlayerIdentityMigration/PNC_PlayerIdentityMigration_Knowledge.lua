-- NPC knowledge merge for player identity migration.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PlayerIdentityMigration = PNC.PlayerIdentityMigration or {}
local Internal = PNC.PlayerIdentityMigration.Internal
local copy = Internal.Copy
local mergeListByID = Internal.MergeListByID

local function mergeKnowledge(canonical, candidates)
    local service = PNC.NPCKnowledge
    if not service then return end
    service.EnsureLoaded()
    local registry = service.Registry
    local destination = registry.byCharacter[canonical.uuid] or { byNPC = {} }
    registry.byCharacter[canonical.uuid] = destination
    for _, sourceRecord in ipairs(candidates) do
        local source = registry.byCharacter[sourceRecord.uuid]
        for npcID, note in pairs(source and source.byNPC or {}) do
            local target = destination.byNPC[npcID]
            if not target then
                destination.byNPC[npcID] = copy(note)
            else
                local firstA, firstB = tonumber(target.firstMetAt) or 0,
                    tonumber(note.firstMetAt) or 0
                if firstA == 0 or (firstB > 0 and firstB < firstA) then
                    target.firstMetAt = firstB
                end
                target.lastInteractionAt = math.max(
                    tonumber(target.lastInteractionAt) or 0,
                    tonumber(note.lastInteractionAt) or 0
                )
                for descriptorID, fact in pairs(note.discovered or {}) do
                    local current = target.discovered[descriptorID]
                    if not current or (tonumber(fact.lastUpdatedAt) or 0)
                        > (tonumber(current.lastUpdatedAt) or 0)
                    then target.discovered[descriptorID] = copy(fact) end
                end
                target.evidence = mergeListByID(target.evidence, note.evidence)
                target.journalEntries = mergeListByID(
                    target.journalEntries, note.journalEntries
                )
                target.manualNotes = mergeListByID(
                    target.manualNotes, note.manualNotes
                )
                target.revision = math.max(
                    tonumber(target.revision) or 0,
                    tonumber(note.revision) or 0
                ) + 1
            end
        end
    end
    service.Registry = service.NormalizeRegistry(registry)
    service.Registry.revision = (tonumber(service.Registry.revision) or 0) + 1
    service.Dirty = true
end

Internal.MergeKnowledge = mergeKnowledge

return Internal
