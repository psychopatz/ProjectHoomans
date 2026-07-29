-- Generates the in-game NPC animation debug catalog from the shipped
-- AnimSets/zombie XML files. Run from the ProjectHoomans repository root:
--     lua tools/generate_pnc_animation_debug_catalog.lua

local sourceRoot =
    "Contents/mods/ProjectHoomans/common/media/AnimSets/zombie"
local outputPath =
    "Contents/mods/ProjectHoomans/42.19/media/lua/client/PNC/Debug/"
        .. "PNC_AnimationDebugCatalog.lua"

local function readFile(path)
    local file = assert(io.open(path, "rb"))
    local value = file:read("*a")
    file:close()
    return value
end

local function firstTag(xml, tag)
    return xml:match("<" .. tag .. ">(.-)</" .. tag .. ">")
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
    local kind = firstTag(block, "m_Type") or ""
    local value
    if kind == "BOOL" then
        value = firstTag(block, "m_BoolValue")
    elseif kind == "GTR" or kind == "LESS" then
        value = firstTag(block, "m_FloatValue")
    else
        value = firstTag(block, "m_StringValue")
    end
    return {
        name = firstTag(block, "m_Name"),
        kind = kind ~= "" and kind or nil,
        value = value,
    }
end

local function parseEvent(block)
    return {
        name = firstTag(block, "m_EventName"),
        time = firstTag(block, "m_Time")
            or firstTag(block, "m_TimePc"),
        parameter = firstTag(block, "m_ParameterValue"),
    }
end

local function parseArray(xml, tag, parser)
    local result = {}
    for block in xml:gmatch("<" .. tag .. ">(.-)</" .. tag .. ">") do
        result[#result + 1] = parser(block)
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

local function mergeArray(parent, child)
    local result = cloneTable(parent or {})
    for index, value in ipairs(child or {}) do
        result[index] = mergeRecord(result[index], value)
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
local command = 'find "' .. sourceRoot
    .. '" -mindepth 2 -type f -name "*.xml" | sort'
local pipe = assert(io.popen(command, "r"))
for path in pipe:lines() do files[#files + 1] = path end
assert(pipe:close())

local rawByPath = {}
for _, path in ipairs(files) do
    local relative = assert(
        path:match("/zombie/(.+)$"),
        "unrecognized animation path: " .. path
    )
    local state = assert(relative:match("^([^/]+)/"))
    local folder, file = assert(relative:match("^(.+)/([^/]+)$"))
    local xml = readFile(path)
    rawByPath[path] = {
        state = state,
        folder = folder,
        file = file,
        path = "media/AnimSets/zombie/" .. relative,
        extends = xml:match('<animNode[^>]-x_extends="([^"]+)"'),
        fields = parseFields(xml),
        conditions = parseArray(xml, "m_Conditions", parseCondition),
        events = parseArray(xml, "m_Events", parseEvent),
        transitionCount = select(
            2,
            xml:gsub("<m_Transitions>", "")
        ),
    }
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
        local parentPath = normalizePath(
            sourceRoot .. "/" .. raw.folder .. "/" .. raw.extends
        )
        parent = resolve(parentPath)
    end
    local entry = {
        state = raw.state,
        folder = raw.folder,
        file = raw.file,
        path = raw.path,
        extends = raw.extends,
        fields = mergeRecord(parent and parent.fields, raw.fields),
        conditions = mergeArray(
            parent and parent.conditions,
            raw.conditions
        ),
        events = mergeArray(parent and parent.events, raw.events),
        transitionCount = raw.transitionCount,
    }
    resolving[path] = nil
    resolved[path] = entry
    return entry
end

local entries = {}
local stateCounts = {}
for _, path in ipairs(files) do
    local value = resolve(path)
    entries[#entries + 1] = value
    stateCounts[value.state] = (stateCounts[value.state] or 0) + 1
end
table.sort(entries, function(left, right)
    if left.state ~= right.state then return left.state < right.state end
    return left.file < right.file
end)

local function quote(value)
    if value == nil then return "nil" end
    return string.format("%q", tostring(value))
end

local output = {}
local function line(value) output[#output + 1] = value end
line("-- GENERATED FILE. Do not edit by hand.")
line("-- Source: common/media/AnimSets/zombie ("
    .. tostring(#entries) .. " XML nodes)")
line("PNC = PNC or {}")
line("PNC.AnimationDebugCatalog = {")
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
    local fields = entry.fields
    line("        {")
    line("            state = " .. quote(entry.state) .. ",")
    line("            folder = " .. quote(entry.folder) .. ",")
    line("            file = " .. quote(entry.file) .. ",")
    line("            path = " .. quote(entry.path) .. ",")
    line("            extends = " .. quote(entry.extends) .. ",")
    line("            node = " .. quote(fields.name) .. ",")
    line("            anim = " .. quote(fields.anim) .. ",")
    line("            looped = "
        .. tostring(fields.looped == "true") .. ",")
    line("            speed = "
        .. tostring(tonumber(fields.speed) or 1.0) .. ",")
    line("            playable = "
        .. tostring(fields.anim ~= nil and fields.anim ~= "") .. ",")
    line("            transitionCount = "
        .. tostring(entry.transitionCount or 0) .. ",")
    line("            conditions = {")
    for _, condition in ipairs(entry.conditions or {}) do
        line("                { name = " .. quote(condition.name)
            .. ", kind = " .. quote(condition.kind)
            .. ", value = " .. quote(condition.value) .. " },")
    end
    line("            },")
    line("            events = {")
    for _, event in ipairs(entry.events or {}) do
        line("                { name = " .. quote(event.name)
            .. ", time = " .. quote(event.time)
            .. ", parameter = " .. quote(event.parameter) .. " },")
    end
    line("            },")
    line("        },")
end
line("    },")
line("}")
line("")
line("return PNC.AnimationDebugCatalog")

local outputFile = assert(io.open(outputPath, "wb"))
outputFile:write(table.concat(output, "\n"))
outputFile:close()
print("Generated " .. outputPath .. " with " .. tostring(#entries) .. " entries")
