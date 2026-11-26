-- Declarative Lua & AnimSet XML exporter for Puppet Opera blueprints.
--
-- Emits clean, diff-friendly Lua modules that register directly into
-- `PNC.PuppetOpera.Blueprints`, plus optional starter AnimSet XML templates
-- for `anim_vars` tracks using `<m_TrackTimeToVariable>PNC_AnimProgress`.

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}
PNC.PuppetOpera.Exporter = PNC.PuppetOpera.Exporter or {}

local Opera = PNC.PuppetOpera
local Exporter = Opera.Exporter
local Blueprints = Opera.Blueprints
    or require "PNC/Core/PuppetOpera/PNC_PuppetOpera_Blueprints"

Exporter.EXPORT_ROOT = "Hoomans/Opera Exports/"

local function isArray(tbl)
    if type(tbl) ~= "table" then return false end
    local count = 0
    for k in pairs(tbl) do
        if type(k) ~= "number" or k < 1 or k ~= math.floor(k) then
            return false
        end
        count = count + 1
    end
    return count > 0 and count == #tbl
end

local function isIdentifier(key)
    return type(key) == "string"
        and string.match(key, "^[%a_][%w_]*$") ~= nil
end

local function escapeString(str)
    str = tostring(str or "")
    str = string.gsub(str, "\\", "\\\\")
    str = string.gsub(str, "\"", "\\\"")
    str = string.gsub(str, "\n", "\\n")
    str = string.gsub(str, "\r", "")
    return "\"" .. str .. "\""
end

local serializeValue

serializeValue = function(value, indent, depth)
    depth = depth or 0
    if depth > 12 then return "nil" end
    local valueType = type(value)
    if valueType == "nil" then return "nil" end
    if valueType == "boolean" then return value and "true" or "false" end
    if valueType == "number" then
        if value ~= value or value == math.huge or value == -math.huge then
            return "0"
        end
        return tostring(value)
    end
    if valueType == "string" then return escapeString(value) end
    if valueType ~= "table" then return "nil" end

    local nextIndent = indent .. "    "
    if isArray(value) then
        local lines = { "{" }
        for i = 1, #value do
            lines[#lines + 1] = nextIndent
                .. serializeValue(value[i], nextIndent, depth + 1) .. ","
        end
        lines[#lines + 1] = indent .. "}"
        return table.concat(lines, "\n")
    end

    local keys = {}
    for k in pairs(value) do
        if type(k) == "string" or type(k) == "number" then
            keys[#keys + 1] = k
        end
    end
    if #keys == 0 then return "{}" end
    table.sort(keys, function(a, b)
        return tostring(a) < tostring(b)
    end)

    local lines = { "{" }
    for _, k in ipairs(keys) do
        local keyText = isIdentifier(k) and k
            or ("[" .. (type(k) == "number" and tostring(k) or escapeString(k)) .. "]")
        lines[#lines + 1] = nextIndent .. keyText .. " = "
            .. serializeValue(value[k], nextIndent, depth + 1) .. ","
    end
    lines[#lines + 1] = indent .. "}"
    return table.concat(lines, "\n")
end

local function safeFileStem(id)
    id = tostring(id or "")
    if id == "" then return nil end
    local stem = string.gsub(id, "[^%w%._%-]", "_")
    stem = string.gsub(stem, "%.+", "_")
    if stem == "" then return nil end
    return stem
end

function Exporter.FormatLua(definition)
    if type(definition) ~= "table" then return nil, "definition_required" end
    local normalized, reason = Blueprints.Normalize(definition.id, definition)
    if not normalized then return nil, reason end

    local lines = {
        "-- Auto-exported Puppet Opera Scene Blueprint",
        "-- Scene ID: " .. tostring(normalized.id),
        "-- Drop into media/lua/shared/PNC/Core/PuppetOpera/ or load via require.",
        "",
        "PNC = PNC or {}",
        "PNC.PuppetOpera = PNC.PuppetOpera or {}",
        "",
        "local Registry = PNC.PuppetOpera.Blueprints",
        "    or require \"PNC/Core/PuppetOpera/PNC_PuppetOpera_Blueprints\"",
        "if type(Registry) ~= \"table\" or type(Registry.Register) ~= \"function\" then",
        "    return false",
        "end",
        "",
        "local blueprint = " .. serializeValue(normalized, "", 0),
        "",
        "Registry.Register(blueprint.id, blueprint)",
        "return blueprint",
        "",
    }
    return table.concat(lines, "\n"), normalized
end

local function collectAnimVarTracks(normalized)
    local specs = {}
    local seen = {}
    for _, beat in ipairs(normalized.beats or {}) do
        for actorID, rawTrack in pairs(beat.tracks or {}) do
            local variants = {}
            if type(rawTrack.byKind) == "table" then
                for kind, v in pairs(rawTrack.byKind) do
                    variants[#variants + 1] = { kind = kind, track = v }
                end
            else
                local actorDef = normalized.actors and normalized.actors[actorID]
                variants[#variants + 1] = {
                    kind = actorDef and actorDef.kind or "nearby_live_npc",
                    track = rawTrack,
                }
            end
            for _, entry in ipairs(variants) do
                local t = entry.track
                if type(t) == "table" and t.route == "anim_vars" then
                    local key = tostring(entry.kind) .. ":"
                        .. tostring(t.style) .. ":"
                        .. tostring(t.role) .. ":"
                        .. tostring(t.phase)
                    if not seen[key] then
                        seen[key] = true
                        specs[#specs + 1] = {
                            kind = entry.kind,
                            style = tostring(t.style or "custom"),
                            role = tostring(t.role or "Actor"),
                            phase = tostring(t.phase or "play"),
                            clip = tostring(t.clip or t.anim or t.style or "Bob_Idle"),
                            looped = beat.mode == "sustained"
                                or beat.mode == "locomotive",
                            phaseLocked = beat.phaseLock ~= "none",
                        }
                    end
                end
            end
        end
    end
    return specs
end

function Exporter.FormatAnimSetXML(definition)
    if type(definition) ~= "table" then return nil, "definition_required" end
    local normalized, reason = Blueprints.Normalize(definition.id, definition)
    if not normalized then return nil, reason end
    local specs = collectAnimVarTracks(normalized)
    if #specs == 0 then return nil, "no_anim_vars_tracks" end

    local blocks = {
        "<!-- Starter AnimSet XML nodes for Puppet Opera scene: "
            .. tostring(normalized.id) .. " -->",
        "<!-- Place zombie nodes under media/AnimSets/zombie/idle/ & walktoward/ -->",
        "<!-- Place player nodes under media/AnimSets/player/slowidleblend/ -->",
    }
    for _, spec in ipairs(specs) do
        local targetSet = spec.kind == "local_player" and "player" or "zombie"
        local nodeName = "PNC_Anim_" .. spec.style .. "_" .. spec.role .. "_" .. spec.phase
        local lines = {
            "",
            "<!-- Target: media/AnimSets/" .. targetSet .. "/ -->",
            "<?xml version=\"1.0\" encoding=\"utf-8\"?>",
            "<animNode>",
            "  <m_Name>" .. nodeName .. "</m_Name>",
            "  <m_AnimName>" .. spec.clip .. "</m_AnimName>",
            "  <m_Priority>100</m_Priority>",
            "  <m_ConditionPriority>1000</m_ConditionPriority>",
            "  <m_Looped>" .. (spec.looped and "true" or "false") .. "</m_Looped>",
            "  <m_BlendTime>0.12</m_BlendTime>",
            "  <m_SpeedScale>1.0</m_SpeedScale>",
            "  <m_SyncTrackingEnabled>false</m_SyncTrackingEnabled>",
            "  <m_maxTorsoTwist>0.0</m_maxTorsoTwist>",
            "  <m_useDeferredMovement>false</m_useDeferredMovement>",
        }
        if spec.phaseLocked then
            lines[#lines + 1] = "  <m_TrackTimeToVariable>PNC_AnimProgress</m_TrackTimeToVariable>"
        end
        lines[#lines + 1] = "  <m_Conditions><m_Name>PNC_AnimActive</m_Name><m_Type>BOOL</m_Type><m_BoolValue>true</m_BoolValue></m_Conditions>"
        lines[#lines + 1] = "  <m_Conditions><m_Name>PNC_AnimStyle</m_Name><m_Type>STRING</m_Type><m_Value>" .. spec.style .. "</m_Value></m_Conditions>"
        lines[#lines + 1] = "  <m_Conditions><m_Name>PNC_AnimRole</m_Name><m_Type>STRING</m_Type><m_Value>" .. spec.role .. "</m_Value></m_Conditions>"
        lines[#lines + 1] = "  <m_Conditions><m_Name>PNC_AnimPhase</m_Name><m_Type>STRING</m_Type><m_Value>" .. spec.phase .. "</m_Value></m_Conditions>"
        lines[#lines + 1] = "</animNode>"
        blocks[#blocks + 1] = table.concat(lines, "\n")
    end
    return table.concat(blocks, "\n") .. "\n", specs
end

local function writeTextFile(relativePath, content)
    if type(getFileWriter) ~= "function" then
        return false, "file_writer_unavailable"
    end
    local writer = getFileWriter(relativePath, true, false)
    if not writer then return false, "file_writer_open_failed" end
    writer:write(tostring(content or ""))
    writer:close()
    return true, relativePath
end

function Exporter.Export(definition, options)
    options = type(options) == "table" and options or {}
    local luaText, normalizedOrReason = Exporter.FormatLua(definition)
    if not luaText then return false, normalizedOrReason end
    local normalized = normalizedOrReason
    local stem = safeFileStem(normalized.id)
    if not stem then return false, "export_file_stem_invalid" end

    if options.publish ~= false then
        Blueprints.Register(normalized.id, normalized)
    end

    local luaPath = Exporter.EXPORT_ROOT .. stem .. ".lua"
    local wroteLua, luaErr = writeTextFile(luaPath, luaText)
    if not wroteLua then return false, luaErr end

    local xmlPath = nil
    if options.includeXml ~= false then
        local xmlText = Exporter.FormatAnimSetXML(normalized)
        if xmlText then
            local targetXml = Exporter.EXPORT_ROOT .. stem .. "_animset.xml"
            local wroteXml = writeTextFile(targetXml, xmlText)
            if wroteXml then xmlPath = targetXml end
        end
    end

    return true, {
        id = normalized.id,
        luaPath = luaPath,
        xmlPath = xmlPath,
        published = options.publish ~= false,
    }
end

return Exporter
