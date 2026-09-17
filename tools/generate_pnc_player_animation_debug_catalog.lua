-- Generates the player-animation debug catalog from the vanilla player
-- actions/emotes and the Project Hoomans player/zombie AnimSets. Run from the
-- ProjectHoomans repository root with the installed Project Zomboid root as
-- the first argument:
--
--     lua tools/generate_pnc_player_animation_debug_catalog.lua \
--         "/path/to/ProjectZomboid/projectzomboid"
--
-- A second argument may override the generated catalog path. A third argument
-- may override the packaged mod root. The generator also emits static bridge
-- XMLs below common/media/AnimSets/player/actions and
-- common/media/AnimSets/player/emote. Those XMLs are loaded by the player's
-- existing action/emote graphs; they are deliberately not runtime-generated.

local pzRoot = arg and arg[1] or os.getenv("PZ_ROOT")
assert(pzRoot and pzRoot ~= "", "missing Project Zomboid root argument")
pzRoot = string.gsub(pzRoot, "/+$", "")

local outputPath = arg and arg[2]
    or "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/Debug/"
        .. "PNC_PlayerAnimationDebugCatalog.lua"
local modRoot = arg and arg[3]
    or os.getenv("PNC_MOD_ROOT") or "Contents/mods/ProjectHoomans"
local commonRoot = modRoot .. "/common"
local bridgeRoot = commonRoot .. "/media/AnimSets/player/actions"
local bridgeMediaRoot = "media/AnimSets/player/actions/"
local emoteBridgeRoot = commonRoot .. "/media/AnimSets/player/emote"
local emoteBridgeMediaRoot = "media/AnimSets/player/emote/"

local sourceSpecs = {
    {
        id = "native_actions",
        source = "player_native",
        folder = "actions",
        statePrefix = "player/actions",
        sourceRoot = pzRoot .. "/media/AnimSets/player/actions",
        mediaRoot = "media/AnimSets/player/actions/",
        minDepth = 1,
    },
    {
        id = "native_emotes",
        source = "player_native",
        folder = "emote",
        statePrefix = "player/emote",
        sourceRoot = pzRoot .. "/media/AnimSets/player/emote",
        mediaRoot = "media/AnimSets/player/emote/",
        minDepth = 1,
    },
    {
        id = "mod_player",
        source = "player_mod",
        statePrefix = "player",
        sourceRoot = commonRoot .. "/media/AnimSets/player",
        mediaRoot = "media/AnimSets/player/",
        minDepth = 2,
    },
    {
        id = "mod_zombie",
        source = "zombie",
        statePrefix = "zombie",
        sourceRoot = commonRoot .. "/media/AnimSets/zombie",
        mediaRoot = "media/AnimSets/zombie/",
        minDepth = 2,
    },
}

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
        -- Build 42's AnimNode parser does not expose m_UpperOnly, but the
        -- zombie source XML still uses it as authorial metadata. The
        -- generator consumes an explicit false value to select a full-body
        -- player-emote bridge and never copies this unsupported field.
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

local rawFiles = {}
local filesBySpec = {}
for _, spec in ipairs(sourceSpecs) do
    filesBySpec[spec.id] = {}
    for _, path in ipairs(listFiles(spec)) do
        local relative = relativePath(spec, path)
        -- Bridge files are generated into the mod player action folder. They
        -- are represented by source entries below and must not be imported a
        -- second time as original mod-player XMLs.
        if not (spec.id == "mod_player"
                and (string.match(relative, "^actions/PNC_PlayerBridge_")
                    or string.match(relative, "^actions/PNC_PH_")
                    or string.match(relative, "^emote/PNC_PH_")))
        then
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

local function parentRelative(raw)
    local directory = raw.relative:match("^(.+)/[^/]+$") or ""
    local parent = normalizePath(
        directory .. "/" .. tostring(raw.extends))
    if not string.match(parent, "%.xml$") then parent = parent .. ".xml" end
    return parent
end

local resolved = {}
local resolving = {}
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

-- These are action-owned selector variables used by vanilla timed actions.
-- Derived locomotion/sitting variables are intentionally excluded: writing
-- those would overwrite live player state and then clear it on action exit.
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

-- A zombie AnimSet may intentionally reuse a player clip so the same visual
-- asset is available to IsoZombie. That does not make it a second player
-- animation. Build the set from entries that the player lab can already play,
-- then omit only the redundant zombie catalog/bridge row below. The authored
-- zombie XML remains untouched because the zombie state machine still needs it.
local playerCatalogClips = {}
for _, raw in ipairs(rawFiles) do
    if raw.spec.source == "player_native"
        or raw.spec.source == "player_mod"
    then
        local value = resolve(raw)
        local fields = value.fields
        local hasClip = fields.anim ~= nil and fields.anim ~= ""
        local playable
        if raw.spec.source == "player_mod" then
            playable = hasClip
        else
            local isEmote = raw.spec.id == "native_emotes"
            local action = isEmote and nil or actionName(value.conditions)
            local emote = isEmote and emoteName(value.conditions) or nil
            playable = hasClip and ((isEmote and emote ~= nil
                and emote ~= "") or (not isEmote and action ~= nil
                and action ~= ""))
        end
        if playable then playerCatalogClips[fields.anim] = true end
    end
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

local function rootState(relative)
    return relative:match("^([^/]+)/") or relative
end

local function xmlEscape(value)
    value = tostring(value or "")
    value = string.gsub(value, "&", "&amp;")
    value = string.gsub(value, "<", "&lt;")
    value = string.gsub(value, ">", "&gt;")
    value = string.gsub(value, '"', "&quot;")
    return value
end

local function safeBoolean(value, default)
    if value == nil or value == "" then return default end
    return string.lower(tostring(value)) == "true"
end

-- These clips are known full-body poses in the player skeleton. The explicit
-- m_UpperOnly=false metadata remains the primary signal; this fallback keeps
-- the bridge useful if a source file is later simplified and drops that
-- legacy zombie-only field.
local FULL_BODY_PREVIEW_CLIPS = {
    Bob_Asleep = true,
    Bob_Awake = true,
    Bob_EmotePassOut_Back = true,
    Bob_SatChair = true,
    Bob_SatChairIn = true,
    Bob_SitGround_ActionIdle = true,
    Bob_SitGround_Idle = true,
    Bob_SitGround_Making = true,
    Bob_SitGround_RubHands = true,
    Bob_SitGround_SleepIdle = true,
}

local function wantsFullBodyPreview(value)
    if value.spec.source == "zombie" then
        if value.fields.upperOnly ~= nil and value.fields.upperOnly ~= "" then
            return safeBoolean(value.fields.upperOnly, true) == false
        end
        return FULL_BODY_PREVIEW_CLIPS[value.fields.anim] == true
    end
    -- SatChair/SatChairIn are native action nodes whose normal conditions are
    -- owned by PlayerSitOnFurnitureState. The lab has no furniture target, so
    -- preview those two clips through the same explicitly labeled full-body
    -- emote bridge used for reusable zombie pose clips.
    return value.spec.source == "player_native"
        and value.spec.id == "native_actions"
        and FULL_BODY_PREVIEW_CLIPS[value.fields.anim] == true
end

local function safeName(value)
    local result = string.gsub(tostring(value or ""), "[^%w]+", "_")
    result = string.gsub(result, "^_+", "")
    result = string.gsub(result, "_+$", "")
    return result ~= "" and result or "Animation"
end

local SHORT_STATE_NAMES = {
    ["hitreaction"] = "HR",
    ["hitreactionpvp"] = "PVP",
    ["walktoward"] = "WT",
    ["walktoward-network"] = "WTN",
    ["pathfind"] = "PF",
    ["bumped"] = "BUMP",
    ["attack"] = "ATK",
    ["attack-network"] = "ATKN",
    ["idle"] = "IDLE",
}

local function stableShortHash(value)
    local hash = 0
    value = tostring(value or "")
    for index = 1, #value do
        hash = (hash * 31 + string.byte(value, index)) % 16777216
    end
    return string.format("%06x", hash)
end

local function bridgeStem(value)
    local stem = safeName(value.fields.name or value.file)
    stem = string.gsub(stem, "^PNC_Anim_", "")
    stem = string.gsub(stem, "^PNC_", "")
    stem = string.gsub(stem, "^Anim_", "")
    return stem ~= "" and stem or "Animation"
end

local function bridgeStateSuffix(value)
    local state = rootState(value.relative)
    return SHORT_STATE_NAMES[state]
        or string.upper(string.sub(safeName(state), 1, 6))
end

-- The alias is intentionally short, but it is not allowed to collide with a
-- vanilla/authored player node or another generated alias. Only the final
-- collision fallback carries a path-derived hash.
local usedBridgeNames = {}
for _, raw in ipairs(rawFiles) do
    if raw.fields.name and raw.fields.name ~= "" then
        usedBridgeNames[string.lower(raw.fields.name)] = true
    end
end
-- Reserve every vanilla player node, not only the native action/emote subset
-- imported into the catalog. This keeps a generated alias from shadowing a
-- player node in another vanilla state directory.
local vanillaPlayerRoot = pzRoot .. "/media/AnimSets/player"
for _, path in ipairs(listFiles({
    sourceRoot = vanillaPlayerRoot,
    minDepth = 1,
})) do
    local fields = parseFields(readFile(path))
    if fields.name and fields.name ~= "" then
        usedBridgeNames[string.lower(fields.name)] = true
    end
end

local function bridgeName(value)
    local base = "PNC_PH_" .. bridgeStem(value)
    local candidates = {
        base,
        base .. "_" .. bridgeStateSuffix(value),
        base .. "_" .. stableShortHash(value.spec.id .. "/"
            .. value.relative),
    }
    for _, candidate in ipairs(candidates) do
        local key = string.lower(candidate)
        if not usedBridgeNames[key] then
            usedBridgeNames[key] = true
            return candidate
        end
    end

    local index = 2
    while true do
        local candidate = candidates[3] .. "_" .. tostring(index)
        local key = string.lower(candidate)
        if not usedBridgeNames[key] then
            usedBridgeNames[key] = true
            return candidate
        end
        index = index + 1
    end
end

local function writeTag(lines, tag, value)
    if value ~= nil and value ~= "" then
        lines[#lines + 1] = "\t<" .. tag .. ">" .. xmlEscape(value)
            .. "</" .. tag .. ">"
    end
end

local function writeBridge(value, name, bridgeMode)
    local fields = value.fields
    local fullBody = bridgeMode == "full_body_emote"
    local outputRoot = fullBody and emoteBridgeRoot or bridgeRoot
    local outputMediaRoot = fullBody and emoteBridgeMediaRoot
        or bridgeMediaRoot
    local bridgePath = outputRoot .. "/" .. name .. ".xml"
    local lines = {
        '<?xml version="1.0" encoding="utf-8"?>',
        "<animNode>",
    }
    writeTag(lines, "m_Name", name)
    writeTag(lines, "m_AnimName", fields.anim)
    writeTag(lines, "m_Priority", fields.priority)
    writeTag(lines, "m_ConditionPriority", fields.conditionPriority)
    writeTag(lines, "m_deferredBoneAxis", fields.deferredBoneAxis)
    writeTag(lines, "m_SyncTrackingEnabled", fields.syncTrackingEnabled)
    writeTag(lines, "m_useDeferredMovement", fields.useDeferredMovement)
    writeTag(lines, "m_deferredRotationScale", fields.deferredRotationScale)
    -- AnimNode defaults to looped=true. Emit the resolved value so the bridge
    -- remains deterministic even when the source inherited that default.
    writeTag(lines, "m_Looped", tostring(safeBoolean(fields.looped, true)))
    writeTag(lines, "m_EarlyTransitionOut", fields.earlyTransitionOut)
    writeTag(lines, "m_StopAnimOnExit", fields.stopAnimOnExit)
    writeTag(lines, "m_SpeedScale", tonumber(fields.speed) or "1.00")
    writeTag(lines, "m_BlendTime", fields.blendTime)
    writeTag(lines, "m_BlendOutTime", fields.blendOutTime)
    lines[#lines + 1] = "\t<m_Conditions>"
    lines[#lines + 1] = "\t\t<m_Name>"
        .. (fullBody and "emote" or "PerformingAction") .. "</m_Name>"
    lines[#lines + 1] = "\t\t<m_Type>STRING</m_Type>"
    lines[#lines + 1] = "\t\t<m_Value>" .. xmlEscape(name) .. "</m_Value>"
    lines[#lines + 1] = "\t</m_Conditions>"
    if fullBody then
        -- Player emotes are a native, replicated sub-state. A root mask is
        -- the supported way to let the emote drive the complete skeleton;
        -- m_UpperOnly is a zombie-state field and is ignored by Build 42's
        -- AnimNode parser.
        if not safeBoolean(fields.looped, true) then
            lines[#lines + 1] = "\t<m_Events>"
            lines[#lines + 1] = "\t\t<m_EventName>EmoteFinishing</m_EventName>"
            lines[#lines + 1] = "\t\t<m_Time>End</m_Time>"
            lines[#lines + 1] = "\t\t<m_ParameterValue></m_ParameterValue>"
            lines[#lines + 1] = "\t</m_Events>"
        end
        lines[#lines + 1] = "\t<m_SubStateBoneWeights>"
        lines[#lines + 1] = "\t\t<boneName>Bip01</boneName>"
        lines[#lines + 1] = "\t\t<includeDescendants>true</includeDescendants>"
        lines[#lines + 1] = "\t</m_SubStateBoneWeights>"
    end
    lines[#lines + 1] = "</animNode>"

    local file = assert(io.open(bridgePath, "wb"))
    file:write(table.concat(lines, "\n"), "\n")
    file:close()
    return outputMediaRoot .. name .. ".xml"
end

-- Bridge every non-redundant source node with a resolved clip. The bridge is
-- a visual player preview, not a conversion of the source state machine:
-- zombie-only conditions/events/scalars are intentionally not copied. An
-- explicitly full-body zombie node is routed through a native player emote
-- bridge; all other imported nodes use the player action context.
assert(os.execute("mkdir -p " .. shellQuote(bridgeRoot)))
assert(os.execute("mkdir -p " .. shellQuote(emoteBridgeRoot)))

local entries = {}
local stateCounts = {}
local bridgeCount = 0
local fullBodyBridgeCount = 0
local sourceCounts = {}
local generatedBridgeFiles = {}
local dedupedZombieRows = 0
local dedupedZombieClips = {}
for _, raw in ipairs(rawFiles) do
    local value = resolve(raw)
    local fields = value.fields
    local spec = value.spec
    local duplicateZombieClip = spec.source == "zombie"
        and fields.anim ~= nil and fields.anim ~= ""
        and playerCatalogClips[fields.anim] == true
    if duplicateZombieClip then
        dedupedZombieRows = dedupedZombieRows + 1
        dedupedZombieClips[fields.anim] = true
    else
    local isNative = spec.source == "player_native"
    local isEmote = spec.id == "native_emotes"
    local action = isNative and actionName(value.conditions) or nil
    local emote = isNative and emoteName(value.conditions) or nil
    local hasClip = fields.anim ~= nil and fields.anim ~= ""
    local bridgeEligible = hasClip
    local looped = safeBoolean(fields.looped, true)
    local route
    local playable
    local bridgePath
    local bridgeFile
    local entryState
    local mode
    local selectedAction = action
    local selectedEmote = emote
    local variables = isNative and (isEmote and {} or selectors(value.conditions))
        or {}
    local fullBodyPreview = false
    local compatibility
    local unsupportedReason

    if isNative then
        entryState = isEmote and "Emote" or action or "unbound"
        fullBodyPreview = wantsFullBodyPreview(value)
        mode = (isEmote or fullBodyPreview) and "emote" or "action"
        route = fullBodyPreview and "player_emote_bridge" or "native_player"
        playable = hasClip and (fullBodyPreview or
            ((isEmote and emote ~= nil and emote ~= "")
                or (not isEmote and action ~= nil and action ~= "")))
        compatibility = fullBodyPreview and "full-body player emote preview"
            or "native player context"
        if not playable then
            unsupportedReason = "No supported player action/emote selector"
        end
        if playable and fullBodyPreview then
            local bridgeNameValue = bridgeName(value)
            bridgeFile = bridgeNameValue .. ".xml"
            selectedAction = nil
            selectedEmote = bridgeNameValue
            bridgePath = writeBridge(value, bridgeNameValue, "full_body_emote")
            generatedBridgeFiles["emote/" .. bridgeFile] = true
            bridgeCount = bridgeCount + 1
            fullBodyBridgeCount = fullBodyBridgeCount + 1
        end
    else
        entryState = spec.source == "zombie"
            and rootState(value.relative)
            or "player/" .. tostring(value.folder)
        fullBodyPreview = wantsFullBodyPreview(value)
        mode = fullBodyPreview and "emote" or "action"
        route = hasClip and bridgeEligible
            and (fullBodyPreview and "player_emote_bridge"
                or "player_bridge")
            or "zombie_only"
        playable = hasClip and bridgeEligible
        compatibility = playable and (fullBodyPreview
            and "experimental full-body player emote bridge"
            or "experimental player action bridge")
            or "source graph only"
        unsupportedReason = not hasClip
            and "Source XML has no resolved animation clip" or nil
        if playable then
            local bridgeNameValue = bridgeName(value)
            bridgeFile = bridgeNameValue .. ".xml"
            if fullBodyPreview then
                selectedAction = nil
                selectedEmote = bridgeNameValue
            else
                selectedAction = bridgeNameValue
            end
            bridgePath = writeBridge(value, bridgeNameValue,
                fullBodyPreview and "full_body_emote" or "action")
            generatedBridgeFiles[(fullBodyPreview and "emote/" or "actions/")
                .. bridgeFile] = true
            bridgeCount = bridgeCount + 1
            if fullBodyPreview then fullBodyBridgeCount = fullBodyBridgeCount + 1 end
        end
    end

    local entry = {
        state = entryState,
        source = spec.source,
        sourceState = isNative and spec.statePrefix
            or spec.statePrefix .. "/" .. tostring(value.folder),
        mode = mode,
        route = route,
        compatibility = compatibility,
        unsupportedReason = unsupportedReason,
        folder = value.folder,
        file = value.file,
        path = value.path,
        originalPath = value.path,
        bridgeFile = bridgeFile,
        bridgePath = bridgePath,
        extends = value.extends,
        node = fields.name,
        anim = fields.anim,
        action = selectedAction,
        emote = selectedEmote,
        fullBody = fullBodyPreview,
        looped = looped,
        speed = tonumber(fields.speed) or 1.0,
        playable = playable == true,
        variables = variables,
        transitionCount = value.transitionCount or 0,
        conditions = value.conditions,
        events = value.events,
    }
    entries[#entries + 1] = entry
    stateCounts[entry.state] = (stateCounts[entry.state] or 0) + 1
    sourceCounts[entry.source] = (sourceCounts[entry.source] or 0) + 1
    end
end

-- Remove only stale files previously generated by this generator. The targets
-- are the exact bridge directories and exact managed filename prefix;
-- authored player action/emote XMLs are never touched.
local function removeStaleBridges(root, directory)
    local stalePipe = assert(io.popen("find " .. shellQuote(root)
        .. " -maxdepth 1 -type f \\( -name 'PNC_PlayerBridge_*.xml'"
        .. " -o -name 'PNC_PH_*.xml' \\)"))
    for path in stalePipe:lines() do
        local file = path:match("([^/]+)$")
        if not generatedBridgeFiles[directory .. file] then
            assert(os.remove(path))
        end
    end
    assert(stalePipe:close())
end
removeStaleBridges(bridgeRoot, "actions/")
removeStaleBridges(emoteBridgeRoot, "emote/")

table.sort(entries, function(left, right)
    if left.state ~= right.state then return left.state < right.state end
    if left.source ~= right.source then return left.source < right.source end
    return (left.file or "") < (right.file or "")
end)

local function quote(value)
    if value == nil then return "nil" end
    return string.format("%q", tostring(value))
end

local output = {}
local function line(value) output[#output + 1] = value end
local dedupedZombieClipCount = 0
for _ in pairs(dedupedZombieClips) do
    dedupedZombieClipCount = dedupedZombieClipCount + 1
end
line("-- GENERATED FILE. Do not edit by hand.")
line("-- Sources: vanilla player, mod player, and zombie AnimSets ("
    .. tostring(#entries) .. " XML nodes; " .. tostring(bridgeCount)
    .. " static player bridges)")
line("PNC = PNC or {}")
line("PNC.PlayerAnimationDebugCatalog = {")
line("    generatedCount = " .. tostring(#entries) .. ",")
line("    bridgeCount = " .. tostring(bridgeCount) .. ",")
line("    fullBodyBridgeCount = " .. tostring(fullBodyBridgeCount) .. ",")
line("    dedupe = {")
line("        zombieRowsRemoved = " .. tostring(dedupedZombieRows) .. ",")
line("        zombieClipsRemoved = " .. tostring(dedupedZombieClipCount) .. ",")
line("        policy = \"resolved zombie m_AnimName already playable from player catalog\",")
line("    },")
line("    sourceCounts = {")
local sources = {}
for source in pairs(sourceCounts) do sources[#sources + 1] = source end
table.sort(sources)
for _, source in ipairs(sources) do
    line("        [" .. quote(source) .. "] = "
        .. tostring(sourceCounts[source]) .. ",")
end
line("    },")
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
    line("            source = " .. quote(entry.source) .. ",")
    line("            sourceState = " .. quote(entry.sourceState) .. ",")
    line("            mode = " .. quote(entry.mode) .. ",")
    line("            route = " .. quote(entry.route) .. ",")
    line("            compatibility = " .. quote(entry.compatibility) .. ",")
    line("            unsupportedReason = " .. quote(entry.unsupportedReason) .. ",")
    line("            folder = " .. quote(entry.folder) .. ",")
    line("            file = " .. quote(entry.file) .. ",")
    line("            path = " .. quote(entry.path) .. ",")
    line("            originalPath = " .. quote(entry.originalPath) .. ",")
    line("            bridgeFile = " .. quote(entry.bridgeFile) .. ",")
    line("            bridgePath = " .. quote(entry.bridgePath) .. ",")
    line("            extends = " .. quote(entry.extends) .. ",")
    line("            node = " .. quote(entry.node) .. ",")
    line("            anim = " .. quote(entry.anim) .. ",")
    line("            action = " .. quote(entry.action) .. ",")
    line("            emote = " .. quote(entry.emote) .. ",")
    line("            fullBody = " .. tostring(entry.fullBody) .. ",")
    line("            looped = " .. tostring(entry.looped) .. ",")
    line("            speed = " .. tostring(entry.speed) .. ",")
    line("            playable = " .. tostring(entry.playable) .. ",")
    line("            transitionCount = " .. tostring(entry.transitionCount) .. ",")
    line("            variables = {")
    for _, variable in ipairs(entry.variables or {}) do
        line("                { name = " .. quote(variable.name)
            .. ", kind = " .. quote(variable.kind)
            .. ", value = " .. quote(variable.value) .. " },")
    end
    line("            },")
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
line("return PNC.PlayerAnimationDebugCatalog")

local outputFile = assert(io.open(outputPath, "wb"))
outputFile:write(table.concat(output, "\n"))
outputFile:close()
print("Generated " .. outputPath .. " with " .. tostring(#entries)
    .. " entries and " .. tostring(bridgeCount) .. " player bridges")
