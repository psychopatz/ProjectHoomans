-- One-time durable-state backup for player identity migration.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PlayerIdentityMigration = PNC.PlayerIdentityMigration or {}
local Internal = PNC.PlayerIdentityMigration.Internal
local Characters = PNC.PlayerCharacters
local Constants = PNC.PlayerCharacterConstants
local copy = Internal.Copy
local keyVariants = Internal.KeyVariants

local function backupOnce(candidates)
    if not ModData or not ModData.getOrCreate then return end
    local target = ModData.getOrCreate(Constants.MIGRATION_BACKUP_MODDATA_KEY)
    if target.created ~= true then
        target.created = true
        target.sourceSchemaVersion = 3
        target.registry = copy(
            Characters.PendingLegacyBackup or Characters.Registry
        )
        target.knowledgeByCharacter = {}
        for _, record in ipairs(candidates or {}) do
            local notes = PNC.NPCKnowledge and PNC.NPCKnowledge.Registry
                and PNC.NPCKnowledge.Registry.byCharacter
                and PNC.NPCKnowledge.Registry.byCharacter[record.uuid]
            if notes then
                target.knowledgeByCharacter[record.uuid] = copy(notes)
            end
        end
        target.factionRegistry = copy(
            PNC.Factions and PNC.Factions.Registry or {}
        )
        target.affectedNPCSocial = {}
        if PNC.Registry and PNC.Registry.ForEach then
            PNC.Registry.ForEach(function(npc)
                local affected = false
                for _, record in ipairs(candidates or {}) do
                    for key in pairs(keyVariants(record)) do
                        if npc.social and npc.social.relationships
                            and npc.social.relationships[key]
                        then affected = true end
                    end
                end
                if affected then
                    target.affectedNPCSocial[tostring(npc.id)] =
                        copy(npc.social)
                end
            end)
        end
    end
end

Internal.BackupOnce = backupOnce

return Internal
