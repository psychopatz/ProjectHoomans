PNC = PNC or {}
PNC.Persistence = PNC.Persistence or {}
PNC.Persistence.Internal = PNC.Persistence.Internal or {}

local NeedsRecordRepository = require "PNC/Core/Needs/PNC_NeedsRecordRepository"
local IdentityRestoration = require "PNC/Core/Identity/PNC_IdentityRestoration"
local HealthRepository = require "PNC/Core/Health/PNC_HealthRepository"
local RelationshipRepository = require "PNC/Core/Relationships/PNC_RelationshipRepository"
local CompanionRecordRepository = require "PNC/Core/Commands/PNC_CompanionRecordRepository"
local BodyRepository = require "PNC/Core/Presence/PNC_BodyRepository"
local TravelRepository = require "PNC/Core/Travel/PNC_TravelRepository"
local Persistence = PNC.Persistence
local Internal = Persistence.Internal
local InventoryRepository = require "PNC/Core/Inventory/PNC_InventoryRepository"
local Core = PNC.Core

local function restoreJournalAndTravel(record, raw)
    if PNC.Journals and PNC.Journals.RemoveNPC then
        PNC.Journals.RemoveNPC(record.id)
    end
    if type(raw.npcJournal) == "table"
        and PNC.Journals and PNC.Journals.ImportNPC
    then
        local imported = pcall(
            PNC.Journals.ImportNPC,
            record,
            raw.npcJournal
        )
        if not imported and Core and Core.LogWarn then
            Core.LogWarn("Rejected NPC journal id=" .. tostring(record.id))
        end
    end
    local active, journeyID = TravelRepository.RestoreRecord(
        record, raw, CompanionRecordRepository.IsFollowing(record))
    if active then CompanionRecordRepository.SetTravelOrder(record, journeyID) end
end

function Internal.FinalizeDeserializedRecord(
    record,
    raw,
    identity,
    progression
)
    IdentityRestoration.RestoreTraits(record, raw)
    NeedsRecordRepository.RestoreRecord(record, raw)
    BodyRepository.RestoreCorpse(record, raw.corpse)
    IdentityRestoration.RestoreRecord(record, raw, identity)
    RelationshipRepository.RestoreRecord(record, raw)
    HealthRepository.RestoreStamina(raw.stamina, record)
    record = InventoryRepository.RestoreRecord(record, raw.inventory)
    record = Persistence.RebuildRuntime(record)
    if Persistence.Repairs and Persistence.Repairs.Apply then
        Persistence.Repairs.Apply("npc_record", record, {
            objectId = record.id,
            sourceVersion = tonumber(raw.schemaVersion) or 0,
        })
    end
    restoreJournalAndTravel(record, raw)
    record.persistenceSourceVersion = tonumber(raw.schemaVersion) or 0
    BodyRepository.RestoreHint(record, raw)
    return record
end
