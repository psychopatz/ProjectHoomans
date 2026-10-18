-- Source-field validation for the read-only P0B import planner.

local Utils = require
    "PNC/Core/Persistence/PNC_Persistence/PNC_Persistence_ImportPlan_Utils"

local Fields = {}
local APPEARANCE_SCHEMA = 2
local INVENTORY_SCHEMA = 2

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
        elseif item.legacyTemplateKey ~= nil then
            blocked = true
            add(decisions, "inventory.legacyTemplateKey", "quarantined",
                "inventory.items." .. tostring(item.id)
                    .. ".legacyTemplateKey",
                "portable_metadata_unrepresentable")
        end
        output.items[itemID] = Utils.Copy(item)
    end
    if itemCount == 0 or not blocked then
        add(decisions, "inventory.items", "copied", "inventory.items", nil)
    end
    return output
end

function Fields.Relationships(raw, source, decisions)
    local value = source and source.social or raw and raw.social
    if type(value) ~= "table" then
        add(decisions, "relationships", "quarantined", "social",
            "relationship_state_missing")
        return nil
    end
    add(decisions, "relationships", "copied", "social", nil)
    return Utils.Copy(value)
end

local function locationValue(raw, source, key, xKey)
    if raw and type(raw[key]) == "table" then return Utils.Copy(raw[key]) end
    if source and source[xKey] ~= nil then
        local yKey
        local zKey
        if key == "position" then
            yKey, zKey = "y", "z"
        elseif key == "spawn" then
            yKey, zKey = "spawnY", "spawnZ"
        else
            yKey, zKey = "anchorY", "anchorZ"
        end
        if source[yKey] == nil or source[zKey] == nil then return nil end
        return { x = source[xKey], y = source[yKey], z = source[zKey] }
    end
    return nil
end

function Fields.Location(raw, source, decisions)
    local position = locationValue(raw, source, "position", "x")
    local spawn = locationValue(raw, source, "spawn", "spawnX")
    local anchor = locationValue(raw, source, "anchor", "anchorX")
    local values = {
        { "location.position", position, "position" },
        { "location.spawn", spawn, "spawn" },
        { "location.anchor", anchor, "anchor" },
    }
    local output = {
        position = position,
        spawn = spawn,
        anchor = anchor,
        journey = Utils.Copy(raw and raw.travel or source and source.travel),
    }
    local i
    for i = 1, #values do
        if type(values[i][2]) ~= "table" then
            add(decisions, values[i][1], "quarantined", values[i][3],
                "location_value_missing")
        end
    end
    add(decisions, "location.journey", "projected", "travel",
        "journey_projection_remains_source_authoritative")
    return output
end

return Fields
