-- Source-field validation for the read-only P0B import planner.

local Utils = require
    "PNC/Core/Persistence/PNC_Persistence/PNC_Persistence_ImportPlan_Utils"

local Fields = {}
local APPEARANCE_SCHEMA = 2
local INVENTORY_SCHEMA = 2
local INVENTORY_METADATA_SCHEMA = 2

local function add(decisions, ...)
    return Utils.AddDecision(decisions, ...)
end

function Fields.Identity(source, raw, decisions)
    local identity = source and source.identity
    local survivor = identity and identity.survivor
    local seed = identity and identity.seed
        or source and source.identitySeed or raw and raw.identitySeed
    local displayName = identity and identity.displayName
        or source and (source.displayName or source.name)
        or raw and (raw.displayName or raw.name)
    local archetypeID = identity and identity.archetypeID
        or source and source.archetypeID or raw and raw.archetypeID
    local voiceFields = {
        { "voice", "identity.survivor.voice" },
        { "voicePrefix", "identity.survivor.voicePrefix" },
        { "voiceType", "identity.survivor.voiceType" },
        { "voicePitch", "identity.survivor.voicePitch" },
    }
    local missing = false
    local i
    if type(identity) ~= "table" then
        add(decisions, "identity", "quarantined", "identity",
            "identity_missing")
    end
    if type(seed) ~= "number" and type(seed) ~= "string" then
        add(decisions, "identity.seed", "quarantined", "identity.seed",
            "identity_seed_missing")
    end
    if type(displayName) ~= "string" or displayName == "" then
        add(decisions, "identity.displayName", "quarantined",
            "identity.displayName", "display_name_missing")
    end
    if type(archetypeID) ~= "string" or archetypeID == "" then
        add(decisions, "identity.archetypeID", "quarantined",
            "identity.archetypeID", "archetype_missing")
    end
    if type(survivor) ~= "table" then
        add(decisions, "identity.survivor", "quarantined",
            "identity.survivor", "survivor_profile_missing")
        return nil
    end
    for i = 1, #voiceFields do
        if survivor[voiceFields[i][1]] == nil then
            missing = true
            add(decisions, "identity.voice", "quarantined",
                voiceFields[i][2], "voice_profile_incomplete")
        end
    end
    if not missing then
        add(decisions, "identity.voice", "copied",
            "identity.survivor.voice*", nil)
    end
    if not missing and (type(seed) == "number" or type(seed) == "string")
        and type(displayName) == "string" and displayName ~= ""
        and type(archetypeID) == "string" and archetypeID ~= ""
    then
        add(decisions, "identity", "copied", "identity", nil)
    end
    return {
        raw = Utils.Copy(identity),
        seed = seed,
        displayName = displayName,
        archetypeID = archetypeID,
        survivor = survivor,
    }
end

function Fields.Appearance(source, decisions)
    local value = source and source.appearance
    if type(value) ~= "table" then
        add(decisions, "appearance.policy", "quarantined", "appearance",
            "authored_appearance_policy_missing")
        return nil
    end
    if tonumber(value.schemaVersion) ~= APPEARANCE_SCHEMA then
        add(decisions, "appearance.policy", "quarantined",
            "appearance.schemaVersion", "appearance_schema_unsupported")
        return nil
    end
    add(decisions, "appearance.policy", "copied", "appearance", nil)
    return Utils.Copy(value)
end

function Fields.Inventory(source, decisions)
    local value = source and source.inventory
    local items = value and value.items
    if type(value) ~= "table" or type(items) ~= "table" then
        add(decisions, "inventory", "quarantined", "inventory",
            "inventory_source_shape_unverified")
        return nil
    end
    local output = {
        sourceSchema = INVENTORY_SCHEMA,
        metadataSchema = INVENTORY_METADATA_SCHEMA,
        persistenceMode = value.persistenceMode,
        revision = value.revision,
        maxWeight = value.maxWeight,
        rootMaxWeight = value.rootMaxWeight,
        template = Utils.Copy(value.template),
        items = {},
        equipped = Utils.Copy(value.equipped),
        worn = Utils.Copy(value.worn),
        attached = Utils.Copy(value.attached),
    }
    local itemCount = 0
    local blocked = false
    local itemID
    local item
    for itemID, item in pairs(items) do
        itemCount = itemCount + 1
        if type(item) ~= "table" or type(item.id) ~= "string"
            or item.id == ""
        then
            blocked = true
            add(decisions, "inventory.items", "quarantined",
                "inventory.items", "item_identity_missing")
        elseif tostring(item.id) ~= tostring(itemID) then
            blocked = true
            add(decisions, "inventory.items", "quarantined",
                "inventory.items." .. tostring(itemID),
                "item_id_key_mismatch")
        elseif item.legacyTemplateKey ~= nil
            and (type(item.legacyTemplateKey) ~= "string"
                or item.legacyTemplateKey == "")
        then
            blocked = true
            add(decisions, "inventory.legacyTemplateKey", "quarantined",
                "inventory.items." .. tostring(item.id)
                    .. ".legacyTemplateKey",
                "portable_metadata_invalid")
        elseif item.legacyTemplateKey ~= nil then
            add(decisions, "inventory.legacyTemplateKey", "copied",
                "inventory.items." .. tostring(item.id)
                    .. ".legacyTemplateKey", nil)
        end
        output.items[itemID] = Utils.Copy(item)
    end
    if itemCount == 0 or not blocked then
        add(decisions, "inventory.items", "copied", "inventory.items", nil)
    end
    return output
end

return Fields
