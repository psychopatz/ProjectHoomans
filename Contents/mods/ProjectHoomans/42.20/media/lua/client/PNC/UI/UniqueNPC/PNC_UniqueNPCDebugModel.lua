-- Presentation-neutral model for the authority-owned unique NPC registry.

PNC = PNC or {}
PNC.UniqueNPCDebugModel = PNC.UniqueNPCDebugModel or {}

local Model = PNC.UniqueNPCDebugModel

local function scalar(value)
    if value == nil then return "none" end
    if type(value) == "boolean" then return value and "yes" or "no" end
    if type(value) == "number" then
        if value % 1 == 0 then return tostring(value) end
        return string.format("%.3f", value)
    end
    return tostring(value)
end

local function sortedKeys(values)
    local keys = {}
    if type(values) ~= "table" then return keys end
    for key in pairs(values) do keys[#keys + 1] = key end
    table.sort(keys, function(left, right)
        return tostring(left) < tostring(right)
    end)
    return keys
end

local function valueText(value, depth)
    local parts
    local keys
    local key
    local child
    depth = tonumber(depth) or 0
    if type(value) ~= "table" then return scalar(value) end
    if depth >= 2 then return "{...}" end
    keys = sortedKeys(value)
    if #keys == 0 then return "{}" end
    parts = {}
    for _, keyValue in ipairs(keys) do
        key = tostring(keyValue)
        child = value[keyValue]
        parts[#parts + 1] = key .. "=" .. valueText(child, depth + 1)
    end
    return "{" .. table.concat(parts, ", ") .. "}"
end

local function contains(value, query)
    if not query or query == "" then return true end
    return string.find(
        string.lower(tostring(value or "")),
        string.lower(query),
        1,
        true
    ) ~= nil
end

local function matchesFilter(entry, filter)
    filter = filter or "All"
    if filter == "All" then return true end
    if filter == "Unspawned" then return entry.status == "unseen" end
    if filter == "Reserved" then return entry.status == "reserved" end
    if filter == "Alive" then return entry.status == "alive" end
    if filter == "Dead" then return entry.status == "dead" end
    if filter == "Problems" then
        return entry.integrity ~= nil
            or entry.registrationError ~= nil
            or entry.registered ~= true
    end
    return true
end

local function runtime(entry)
    return entry and entry.runtime or nil
end

local function positionText(runtimeData)
    if not runtimeData then return "none" end
    if runtimeData.x == nil or runtimeData.y == nil then return "unknown" end
    return string.format("%.1f, %.1f, %.0f",
        tonumber(runtimeData.x) or 0,
        tonumber(runtimeData.y) or 0,
        tonumber(runtimeData.z) or 0)
end

local function affiliationText(affiliation)
    if type(affiliation) ~= "table" then return "none" end
    return string.format("%s | role %s | rank %s | %s",
        tostring(affiliation.name or affiliation.id or "unknown"),
        tostring(affiliation.role or "none"),
        tostring(affiliation.rank or "none"),
        tostring(affiliation.membershipStatus or "unknown"))
end

local function communityText(community)
    if type(community) ~= "table" then return "none" end
    return string.format("%s | role %s | %s",
        tostring(community.name or community.id or "unknown"),
        tostring(community.role or "none"),
        tostring(community.status or "unknown"))
end

local function statusText(entry)
    local status = tostring(entry and entry.status or "unknown")
    if entry and (entry.integrity or entry.registrationError) then
        status = status .. " / PROBLEM"
    end
    return string.upper(status)
end

function Model.StatusText(entry)
    return statusText(entry or {})
end

function Model.IsLocatable(entry)
    local live = runtime(entry)
    return entry and entry.status == "alive"
        and live and tostring(live.runtimeNpcId or "") ~= ""
        and live.x ~= nil and live.y ~= nil
end

function Model.IsTestSpawnable(entry)
    return type(entry) == "table"
        and entry.registered == true
        and tostring(entry.definitionId or "") ~= ""
        and entry.registrationError == nil
end

function Model.BuildItems(snapshot, filter, query)
    local items = {}
    local seen = {}
    if type(snapshot) ~= "table" then return items end
    for _, entry in ipairs(snapshot.entries or {}) do
        local id = tostring(entry.definitionId or "")
        seen[id] = true
        local live = runtime(entry)
        local detail = string.format("%s | %s",
            statusText(entry),
            live and tostring(live.presenceState or "spawned") or "not spawned")
        if matchesFilter(entry, filter) and contains(
            tostring(entry.displayName or entry.definitionId), query)
        then
            items[#items + 1] = {
                id = id,
                label = tostring(entry.displayName or entry.definitionId),
                detail = detail,
                status = entry.status,
                locatable = Model.IsLocatable(entry),
                entry = entry,
            }
        end
    end
    for _, errorEntry in ipairs(snapshot.registrationErrors or {}) do
        local id = tostring(errorEntry.id or "invalid:" .. tostring(
            errorEntry.reason or "definition"))
        if not seen[id] then
            local entry = {
                definitionId = id,
                displayName = errorEntry.displayName or id,
                registered = false,
                status = "invalid",
                registrationError = errorEntry,
            }
            if matchesFilter(entry, filter) and contains(
                entry.displayName, query)
            then
                items[#items + 1] = {
                    id = id,
                    label = tostring(entry.displayName),
                    detail = statusText(entry),
                    status = entry.status,
                    locatable = false,
                    entry = entry,
                }
            end
        end
    end
    return items
end

local function add(rows, key, labelKey, fallback, value, colorName)
    rows[#rows + 1] = {
        key = key,
        labelKey = labelKey,
        fallback = fallback,
        value = scalar(value),
        colorName = colorName,
    }
end

function Model.BuildDetailRows(entry)
    local rows = {}
    local live = runtime(entry)
    local authored = entry and entry.authored or nil
    local integrity = entry and entry.integrity or nil
    if type(entry) ~= "table" then return rows end

    add(rows, "definition", "UI_PNC_UniqueNPCDebug_Definition",
        "Definition", entry.definitionId)
    add(rows, "registration", "UI_PNC_UniqueNPCDebug_Registration",
        "Registration", entry.registered and "registered" or "missing",
        entry.registered and "success" or "danger")
    if entry.registrationError then
        add(rows, "registration_error",
            "UI_PNC_UniqueNPCDebug_RegistrationError", "Registration error",
            valueText(entry.registrationError), "danger")
    end
    add(rows, "status", "UI_PNC_UniqueNPCDebug_Status", "Status",
        statusText(entry), entry.status == "dead" and "danger" or "text")
    add(rows, "spawned", "UI_PNC_UniqueNPCDebug_Spawned", "Spawned",
        entry.spawned)
    add(rows, "gender", "UI_PNC_UniqueNPCDebug_Gender", "Gender",
        entry.isFemale == nil and "unknown"
            or entry.isFemale and "female" or "male")
    add(rows, "archetype", "UI_PNC_UniqueNPCDebug_Archetype", "Archetype",
        entry.archetypeID)
    add(rows, "version", "UI_PNC_UniqueNPCDebug_Version", "Definition version",
        entry.version)
    add(rows, "seed", "UI_PNC_UniqueNPCDebug_IdentitySeed", "Identity seed",
        entry.identitySeed)
    add(rows, "reserved", "UI_PNC_UniqueNPCDebug_ReservedAt", "Reserved at",
        entry.reservedAt)
    add(rows, "spawned_at", "UI_PNC_UniqueNPCDebug_SpawnedAt", "Spawned at",
        entry.spawnedAt)
    add(rows, "died_at", "UI_PNC_UniqueNPCDebug_DiedAt", "Died at",
        entry.diedAt)
    add(rows, "death_reason", "UI_PNC_UniqueNPCDebug_DeathReason",
        "Death reason", entry.deathReason)
    if integrity then
        add(rows, "integrity", "UI_PNC_UniqueNPCDebug_Integrity", "Integrity",
            integrity, "danger")
    end

    if live then
        add(rows, "runtime_id", "UI_PNC_UniqueNPCDebug_RuntimeID", "Runtime NPC ID",
            live.runtimeNpcId)
        add(rows, "runtime_name", "UI_PNC_UniqueNPCDebug_RuntimeName", "Runtime name",
            live.name)
        add(rows, "presence", "UI_PNC_UniqueNPCDebug_Presence", "Presence",
            live.presenceState)
        add(rows, "tactical", "UI_PNC_UniqueNPCDebug_Tactical", "Tactical class",
            live.tacticalClass)
        add(rows, "body_lease", "UI_PNC_UniqueNPCDebug_BodyLease", "Body lease",
            live.bodyLease)
        add(rows, "position", "UI_PNC_UniqueNPCDebug_Position", "Position",
            positionText(live))
        add(rows, "health", "UI_PNC_UniqueNPCDebug_Health", "Health",
            string.format("%s / %s | %s",
                scalar(live.hpCurrent), scalar(live.hpMax),
                scalar(live.healthState)))
        add(rows, "faction", "UI_PNC_UniqueNPCDebug_Faction", "Faction",
            affiliationText(live.affiliation))
        add(rows, "community", "UI_PNC_UniqueNPCDebug_Community", "Community",
            communityText(live.community))
        add(rows, "skills", "UI_PNC_UniqueNPCDebug_Skills", "Skills",
            valueText(live.skillLevels))
        add(rows, "base_skills", "UI_PNC_UniqueNPCDebug_BaseSkills",
            "Base skills", valueText(live.skillBaseLevels))
        add(rows, "traits", "UI_PNC_UniqueNPCDebug_Traits", "Vanilla traits",
            valueText(live.vanillaTraits))
        add(rows, "dynamic_traits", "UI_PNC_UniqueNPCDebug_DynamicTraits",
            "Dynamic traits", valueText(live.dynamicTraits))
        add(rows, "npc_traits", "UI_PNC_UniqueNPCDebug_NPCTraits",
            "NPC traits", valueText(live.npcTraits))
        add(rows, "equipment", "UI_PNC_UniqueNPCDebug_Equipment", "Equipment",
            valueText(live.equipment))
        add(rows, "inventory", "UI_PNC_UniqueNPCDebug_Inventory",
            "Inventory template", live.inventoryTemplateRef)
    end

    if authored then
        add(rows, "authored_identity", "UI_PNC_UniqueNPCDebug_AuthoredIdentity",
            "Authored identity", valueText(authored.identity))
        add(rows, "authored_tactical",
            "UI_PNC_UniqueNPCDebug_AuthoredTactical", "Authored tactical class",
            authored.tacticalClass)
        add(rows, "authored_visual",
            "UI_PNC_UniqueNPCDebug_AuthoredVisual", "Authored visual profile",
            authored.visualProfile)
        add(rows, "authored_outfit", "UI_PNC_UniqueNPCDebug_AuthoredOutfit",
            "Authored outfit", authored.outfit)
        add(rows, "authored_hp", "UI_PNC_UniqueNPCDebug_AuthoredHP",
            "Authored maximum health", authored.hpMax)
        add(rows, "authored_combat",
            "UI_PNC_UniqueNPCDebug_AuthoredCombat", "Authored combat profile",
            valueText(authored.combatProfile))
        add(rows, "authored_equipment",
            "UI_PNC_UniqueNPCDebug_AuthoredEquipment", "Authored equipment",
            valueText(authored.equipment))
        add(rows, "authored_faction",
            "UI_PNC_UniqueNPCDebug_AuthoredFaction", "Authored faction",
            string.format("%s | %s | role %s | rank %s",
                scalar(authored.factionID), scalar(authored.membershipStatus),
                scalar(authored.factionRole), scalar(authored.factionRank)))
        add(rows, "authored_skills", "UI_PNC_UniqueNPCDebug_AuthoredSkills",
            "Authored skill levels", valueText(authored.skillLevels))
        add(rows, "authored_traits", "UI_PNC_UniqueNPCDebug_AuthoredTraits",
            "Authored vanilla traits", valueText(authored.vanillaTraits))
        add(rows, "authored_dynamic_traits",
            "UI_PNC_UniqueNPCDebug_AuthoredDynamicTraits",
            "Authored dynamic traits", valueText(authored.dynamicTraits))
        add(rows, "authored_npc_traits",
            "UI_PNC_UniqueNPCDebug_AuthoredNPCTraits", "Authored NPC traits",
            valueText(authored.npcTraits))
        add(rows, "authored_inventory",
            "UI_PNC_UniqueNPCDebug_AuthoredInventory", "Authored inventory",
            authored.inventoryTemplateRef)
        add(rows, "starting_items",
            "UI_PNC_UniqueNPCDebug_StartingItems", "Starting item entries",
            authored.startingItemCount)
        add(rows, "starting_item_values",
            "UI_PNC_UniqueNPCDebug_StartingItemValues", "Starting items",
            valueText(authored.startingItems))
    end
    return rows
end

return Model
