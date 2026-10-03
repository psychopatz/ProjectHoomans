local Provider = {}

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
        priority = firstTag(xml, "m_Priority"),
        conditionPriority = firstTag(xml, "m_ConditionPriority"),
        deferredBoneAxis = firstTag(xml, "m_deferredBoneAxis"),
        syncTrackingEnabled = firstTag(xml, "m_SyncTrackingEnabled"),
        useDeferredMovement = firstTag(xml, "m_useDeferredMovement"),
        deferredRotationScale = firstTag(xml, "m_deferredRotationScale"),
        blendTime = firstTag(xml, "m_BlendTime"),
        blendOutTime = firstTag(xml, "m_BlendOutTime"),
        stopAnimOnExit = firstTag(xml, "m_StopAnimOnExit"),
        earlyTransitionOut = firstTag(xml, "m_EarlyTransitionOut"),
        upperOnly = firstTag(xml, "m_UpperOnly"),
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

local function parseEvent(block)
    local xml = block.contents
    return {
        id = block.id,
        name = firstTag(xml, "m_EventName"),
        time = firstTag(xml, "m_Time") or firstTag(xml, "m_TimePc"),
        parameter = firstTag(xml, "m_ParameterValue"),
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

local function mergeArray(parent, child)
    local result = cloneTable(parent or {})
    for index, value in ipairs(child or {}) do
        result[index] = mergeRecord(result[index], value)
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

local function shellQuote(value)
    return "'" .. string.gsub(tostring(value), "'", "'\\''") .. "'"
end

local function listFiles(spec)
    local command = "find " .. shellQuote(spec.sourceRoot)
        .. " -mindepth " .. tostring(spec.minDepth)
        .. " -type f -name '*.xml' | sort"
    local pipe = assert(io.popen(command, "r"))
    local files = {}
    for path in pipe:lines() do files[#files + 1] = path end
    assert(pipe:close())
    return files
end

local function relativePath(spec, path)
    local prefix = spec.sourceRoot .. "/"
    assert(string.sub(path, 1, #prefix) == prefix,
        "unrecognized animation path: " .. path)
    return string.sub(path, #prefix + 1)
end

local function collect(config)
    local rawFiles = {}
    local filesBySpec = {}
    for _, spec in ipairs(config.sourceSpecs) do
        filesBySpec[spec.id] = {}
        for _, path in ipairs(listFiles(spec)) do
            local relative = relativePath(spec, path)
            local generated = spec.id == "mod_player"
                and (string.match(relative, "^actions/PNC_PlayerBridge_")
                    or string.match(relative, "^actions/PNC_PH_")
                    or string.match(relative, "^emote/PNC_PH_"))
            if not generated then
                local xml = readFile(path)
                local raw = {
                    spec = spec,
                    pathOnDisk = path,
                    relative = relative,
                    file = relative:match("([^/]+)$"),
                    folder = relative:match("^(.+)/[^/]+$") or spec.folder,
                    path = spec.mediaRoot .. relative,
                    extends = xml:match('<animNode[^>]-x_extends="([^"]+)"'),
                    fields = parseFields(xml),
                    conditions = parseArray(xml, "m_Conditions", parseCondition),
                    events = parseArray(xml, "m_Events", parseEvent),
                    transitionCount = select(2, xml:gsub(
                        "<m_Transitions[^>]*>", "")),
                }
                rawFiles[#rawFiles + 1] = raw
                filesBySpec[spec.id][string.lower(relative)] = raw
            end
        end
    end
    assert(#rawFiles > 0, "no player or zombie animation XML files found")

    local resolved = {}
    local resolving = {}
    local function parentRelative(raw)
        local directory = raw.relative:match("^(.+)/[^/]+$") or ""
        local parent = normalizePath(
            directory .. "/" .. tostring(raw.extends)
        )
        if not string.match(parent, "%.xml$") then parent = parent .. ".xml" end
        return parent
    end

    local function resolve(raw)
        if resolved[raw.pathOnDisk] then return resolved[raw.pathOnDisk] end
        assert(not resolving[raw.pathOnDisk],
            "cyclic x_extends chain: " .. raw.pathOnDisk)
        resolving[raw.pathOnDisk] = true
        local parent
        if raw.extends then
            local parentKey = string.lower(parentRelative(raw))
            parent = filesBySpec[raw.spec.id][parentKey]
            assert(parent, "missing catalog parent: " .. raw.pathOnDisk
                .. " extends " .. tostring(raw.extends))
            parent = resolve(parent)
        end
        local entry = {
            spec = raw.spec,
            pathOnDisk = raw.pathOnDisk,
            relative = raw.relative,
            folder = raw.folder,
            file = raw.file,
            path = raw.path,
            extends = raw.extends,
            fields = mergeRecord(parent and parent.fields, raw.fields),
            conditions = mergeConditions(parent and parent.conditions,
                raw.conditions),
            events = mergeArray(parent and parent.events, raw.events),
            transitionCount = raw.transitionCount,
        }
        resolving[raw.pathOnDisk] = nil
        resolved[raw.pathOnDisk] = entry
        return entry
    end

    return {
        rawFiles = rawFiles,
        readFile = readFile,
        listFiles = listFiles,
        parseFields = parseFields,
        resolve = resolve,
    }
end

Provider.collect = collect
return Provider
