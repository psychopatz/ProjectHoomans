-- Generates the player-animation debug catalog from Project Zomboid's
-- AnimSets/player/actions and AnimSets/player/emote XML files. Run from the
-- ProjectHoomans repository
-- root with the installed Project Zomboid root as the first argument:
--
--     lua tools/generate_pnc_player_animation_debug_catalog.lua \
--         "/path/to/ProjectZomboid/projectzomboid"
--
-- A second argument may override the generated output path.

local pzRoot = arg and arg[1] or os.getenv("PZ_ROOT")
assert(pzRoot and pzRoot ~= "", "missing Project Zomboid root argument")
pzRoot = string.gsub(pzRoot, "/+$", "")

local sourceSpecs = {
    {
        folder = "actions",
        sourceRoot = pzRoot .. "/media/AnimSets/player/actions",
        mediaRoot = "media/AnimSets/player/actions/",
    },
    {
        folder = "emote",
        sourceRoot = pzRoot .. "/media/AnimSets/player/emote",
        mediaRoot = "media/AnimSets/player/emote/",
    },
}
local outputPath = arg and arg[2]
    or "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/Debug/"
        .. "PNC_PlayerAnimationDebugCatalog.lua"

local function readFile(path)
    local file = assert(io.open(path, "rb"))
    local value = file:read("*a")
    file:close()
    return value
end

local function firstTag(xml, tag)
    return xml:match("<" .. tag .. "[^>]*>(.-)</" .. tag .. ">")
end

local function parseFields(xml)
    return {
        name = firstTag(xml, "m_Name"),
        anim = firstTag(xml, "m_AnimName"),
        looped = firstTag(xml, "m_Looped"),
        speed = firstTag(xml, "m_SpeedScale"),
    }
end

local function parseCondition(block)
    local xml = block.contents
    local kind = firstTag(xml, "m_Type") or ""
    local value = firstTag(xml, "m_Value")
        or firstTag(xml, "m_StringValue")
        or firstTag(xml, "m_BoolValue")
        or firstTag(xml, "m_FloatValue")
    return {
        id = block.id,
        name = firstTag(xml, "m_Name"),
        kind = kind ~= "" and kind or nil,
        value = value,
    }
end

local function parseArray(xml, tag, parser)
    local result = {}
    for attributes, contents in xml:gmatch(
        "<" .. tag .. "([^>]*)>(.-)</" .. tag .. ">") do
        result[#result + 1] = parser({
            id = attributes:match('x_name="([^"]+)"'),
            contents = contents,
        })
    end
    return result
end

local function cloneTable(value)
    local result = {}
    for key, child in pairs(value or {}) do
        result[key] = type(child) == "table" and cloneTable(child) or child
    end
    return result
end

local function mergeRecord(parent, child)
    local result = cloneTable(parent or {})
    for key, value in pairs(child or {}) do
        if value ~= nil then result[key] = value end
    end
    return result
end

local function mergeConditions(parent, child)
    local result = cloneTable(parent or {})
    local byId = {}
    for index, value in ipairs(result) do
        if value.id then byId[value.id] = index end
    end
    for _, value in ipairs(child or {}) do
        local index = value.id and byId[value.id] or nil
        if index then
            result[index] = mergeRecord(result[index], value)
        else
            result[#result + 1] = value
        end
    end
    return result
end

local function normalizePath(path)
    local parts = {}
    for part in path:gmatch("[^/]+") do
        if part == ".." then
            assert(#parts > 0, "invalid parent path: " .. path)
            parts[#parts] = nil
        elseif part ~= "." and part ~= "" then
            parts[#parts + 1] = part
        end
    end
    return table.concat(parts, "/")
end

local files = {}
for _, spec in ipairs(sourceSpecs) do
    local command = 'find "' .. spec.sourceRoot
        .. '" -mindepth 1 -type f -name "*.xml" | sort'
    local pipe = assert(io.popen(command, "r"))
    for path in pipe:lines() do
        files[#files + 1] = { path = path, spec = spec }
    end
    assert(pipe:close())
end
assert(#files > 0, "no player action or emote XML files found")

local rawByPath = {}
local rawPathByName = { actions = {}, emote = {} }
for _, fileInfo in ipairs(files) do
    local path = fileInfo.path
    local spec = fileInfo.spec
    local file = assert(path:match("/([^/]+)$"))
    local xml = readFile(path)
    rawByPath[path] = {
        file = file,
        folder = spec.folder,
        sourceRoot = spec.sourceRoot,
        path = spec.mediaRoot .. file,
        extends = xml:match('<animNode[^>]-x_extends="([^"]+)"'),
        fields = parseFields(xml),
        conditions = parseArray(xml, "m_Conditions", parseCondition),
    }
    rawPathByName[spec.folder][string.lower(file)] = path
end

local resolved = {}
local resolving = {}
local function resolve(path)
    if resolved[path] then return resolved[path] end
    assert(not resolving[path], "cyclic x_extends chain: " .. path)
    resolving[path] = true
    local raw = assert(rawByPath[path], "missing catalog source: " .. path)
    local parent
    if raw.extends then
        local parentName = normalizePath(raw.extends)
        if not string.match(parentName, "%.xml$") then
            parentName = parentName .. ".xml"
        end
        local parentPath = rawPathByName[raw.folder][string.lower(parentName)]
            or raw.sourceRoot .. "/" .. parentName
        parent = resolve(parentPath)
    end
    local entry = {
        file = raw.file,
        folder = raw.folder,
        path = raw.path,
        extends = raw.extends,
        fields = mergeRecord(parent and parent.fields, raw.fields),
        conditions = mergeConditions(parent and parent.conditions, raw.conditions),
    }
    resolving[path] = nil
    resolved[path] = entry
    return entry
end

-- These are action-owned selector variables used by the vanilla timed-action
-- classes. Derived locomotion/sitting variables are intentionally excluded:
-- writing those would make the debug action overwrite live player state and
-- then clear it when the action exits.
local SAFE_SELECTORS = {
    AttachAnim = true,
    BandageType = true,
    FoodType = true,
    LootPosition = true,
    PourType = true,
    RackAiming = true,
    ReadType = true,
    RemoveBarricade = true,
    SitGroundAnim = true,
    Weapon = true,
    WeaponReloadType = true,
    WearClothingLocation = true,
}

local function actionName(conditions)
    for _, condition in ipairs(conditions or {}) do
        if condition.name == "PerformingAction" and condition.value
            and condition.value ~= ""
        then
            return condition.value
        end
    end
    return nil
end

local function emoteName(conditions)
    for _, condition in ipairs(conditions or {}) do
        if condition.name == "emote" and condition.value
            and condition.value ~= ""
        then
            return condition.value
        end
    end
    return nil
end

local function selectors(conditions)
    local result = {}
    local seen = {}
    for _, condition in ipairs(conditions or {}) do
        local name = condition.name
        local value = condition.value
        if name and name ~= "PerformingAction" and SAFE_SELECTORS[name]
            and value ~= nil and value ~= ""
        then
            local key = name .. "\000" .. tostring(value)
            if not seen[key] then
                result[#result + 1] = {
                    name = name,
                    kind = condition.kind,
                    value = value,
                }
                seen[key] = true
            end
        end
    end
    return result
end

local function quote(value)
    if value == nil then return "nil" end
    return string.format("%q", tostring(value))
end

local entries = {}
local stateCounts = {}
for _, fileInfo in ipairs(files) do
    local value = resolve(fileInfo.path)
    local fields = value.fields
    local action = actionName(value.conditions)
    local emote = emoteName(value.conditions)
    local isEmote = value.folder == "emote"
    -- AnimNode.isLooped defaults to true in the Java engine. Only an explicit
    -- m_Looped=false makes a node one-shot; this also preserves the default
    -- inherited by emote/looped.xml descendants.
    local looped = fields.looped == nil
        or string.lower(tostring(fields.looped)) == "true"
    local state = isEmote and "Emote" or action or "unbound"
    local entry = {
        state = state,
        mode = isEmote and "emote" or "action",
        folder = value.folder,
        file = value.file,
        path = value.path,
        extends = value.extends,
        node = fields.name,
        anim = fields.anim,
        action = action,
        emote = emote,
        looped = looped,
        speed = tonumber(fields.speed) or 1.0,
        playable = fields.anim ~= nil and fields.anim ~= ""
            and ((isEmote and emote ~= nil and emote ~= "")
                or (not isEmote and action ~= nil and action ~= "")),
        variables = isEmote and {} or selectors(value.conditions),
    }
    entries[#entries + 1] = entry
    stateCounts[entry.state] = (stateCounts[entry.state] or 0) + 1
end

table.sort(entries, function(left, right)
    if left.state ~= right.state then return left.state < right.state end
    return (left.file or "") < (right.file or "")
end)

local output = {}
local function line(value) output[#output + 1] = value end
line("-- GENERATED FILE. Do not edit by hand.")
line("-- Source: media/AnimSets/player/actions + player/emote ("
    .. tostring(#entries) .. " XML nodes)")
line("PNC = PNC or {}")
line("PNC.PlayerAnimationDebugCatalog = {")
line("    generatedCount = " .. tostring(#entries) .. ",")
line("    stateCounts = {")
local states = {}
for state in pairs(stateCounts) do states[#states + 1] = state end
table.sort(states)
for _, state in ipairs(states) do
    line("        [" .. quote(state) .. "] = "
        .. tostring(stateCounts[state]) .. ",")
end
line("    },")
line("    entries = {")
for _, entry in ipairs(entries) do
    line("        {")
    line("            state = " .. quote(entry.state) .. ",")
    line("            mode = " .. quote(entry.mode) .. ",")
    line("            folder = " .. quote(entry.folder) .. ",")
    line("            file = " .. quote(entry.file) .. ",")
    line("            path = " .. quote(entry.path) .. ",")
    line("            extends = " .. quote(entry.extends) .. ",")
    line("            node = " .. quote(entry.node) .. ",")
    line("            anim = " .. quote(entry.anim) .. ",")
    line("            action = " .. quote(entry.action) .. ",")
    line("            emote = " .. quote(entry.emote) .. ",")
    line("            looped = " .. tostring(entry.looped) .. ",")
    line("            speed = " .. tostring(entry.speed) .. ",")
    line("            playable = " .. tostring(entry.playable) .. ",")
    line("            variables = {")
    for _, variable in ipairs(entry.variables) do
        line("                { name = " .. quote(variable.name)
            .. ", kind = " .. quote(variable.kind)
            .. ", value = " .. quote(variable.value) .. " },")
    end
    line("            },")
    line("        },")
end
line("    },")
line("}")
line("")
line("return PNC.PlayerAnimationDebugCatalog")

local outputFile = assert(io.open(outputPath, "wb"))
outputFile:write(table.concat(output, "\n"))
outputFile:close()
print("Generated " .. outputPath .. " with " .. tostring(#entries) .. " entries")
