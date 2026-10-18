-- Candidate assembly for the read-only P0B import planner.

local Utils = require
    "PNC/Core/Persistence/PNC_Persistence/PNC_Persistence_ImportPlan_Utils"
local Fields = require
    "PNC/Core/Persistence/PNC_Persistence/PNC_Persistence_ImportPlan_Fields"

local Source = {}

local function add(decisions, ...)
    return Utils.AddDecision(decisions, ...)
end

local function actorID(source, raw, options)
    local identity = source and source.identity or {}
    local id = identity.actorId or source and source.id or raw and raw.id
    local mapped = options and options.actorId
    if type(mapped) == "string" and mapped ~= "" then return mapped end
    if type(id) ~= "string" or id == "" then return nil end
    return "pnc:" .. id
end

function Source.Build(raw, source, options, decisions)
    local identity = Fields.Identity(source, raw, decisions)
    local policy = Fields.Appearance(source, decisions)
    local inventory = Fields.Inventory(source, decisions)
    local relationships = Fields.Relationships(raw, source, decisions)
    local location = Fields.Location(raw, source, decisions)
    local id = actorID(source, raw, options or {})
    if not id then
        add(decisions, "actorId", "quarantined", "id", "actor_id_missing")
    else
        add(decisions, "actorId", "copied", "id", nil)
    end
    if not identity or not policy or not inventory
        or not relationships or not location
    then
        return nil
    end
    local survivor = Utils.Copy(identity.survivor)
    survivor.voice = {
        legacy = identity.survivor.voice,
        prefix = identity.survivor.voicePrefix,
        type = identity.survivor.voiceType,
        pitch = identity.survivor.voicePitch,
        complete = true,
    }
    return {
        schema = "PsychopatzCore.NPC",
        schemaVersion = 1,
        actorId = id,
        source = {
            provider = "ProjectHoomans",
            persistenceVersion = tonumber(raw.schemaVersion),
            sourceRecordHash = options.sourceRecordHash,
            sourceSnapshotHash = options.sourceSnapshotHash,
            decisionSet = options.decisionSet,
        },
        identity = {
            schemaVersion = 1,
            seed = identity.seed,
            archetypeID = identity.archetypeID,
            displayName = identity.displayName,
            isFemale = identity.raw.isFemale,
            survivor = survivor,
        },
        appearance = {
            policySchemaVersion = 2,
            policy = policy,
        },
        inventory = inventory,
        relationships = { sourceSchema = 3, entries = relationships },
        location = location,
    }
end

return Source
