-- Read-only discovery surface for semantic actions and NLU trigger patterns.
--
-- Feature modules continue to own registration and execution. This catalog
-- only observes the live registries so tools can discover newly loaded
-- capabilities without maintaining a second hardcoded list.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.CapabilityCatalog or {}
PNC.Semantics.CapabilityCatalog = Catalog

Catalog.VERSION = 1

local function normalized(value)
    value = string.upper(tostring(value or ""))
    return string.gsub(value, "[%s%-]+", "_")
end

local function copyPublic(value, depth, seen)
    if type(value) ~= "table" then
        return value
    end
    depth = tonumber(depth) or 0
    if depth >= 8 then
        return "<depth_limit>"
    end
    seen = seen or {}
    if seen[value] then
        return "<cycle>"
    end
    seen[value] = true
    local output = {}
    local key
    local item
    for key, item in pairs(value) do
        if type(key) == "string" or type(key) == "number" then
            if type(item) == "table" then
                output[key] = copyPublic(item, depth + 1, seen)
            elseif type(item) ~= "function"
                and type(item) ~= "userdata"
                and type(item) ~= "thread"
            then
                output[key] = item
            end
        end
    end
    seen[value] = nil
    return output
end

local function appendUnique(list, seen, value)
    value = tostring(value or "")
    if value == "" or seen[value] then return end
    seen[value] = true
    list[#list + 1] = value
end

local function semanticRegistry()
    local core = PsychopatzCore and PsychopatzCore.Semantics
    return core and core.Registry or nil
end

local function transportFor(source)
    if source == "command_adapter" then return "companion_command" end
    if source == "task_adapter" then return "semantic_task" end
    if source == "gift_lifecycle" then return "inventory_transfer" end
    return nil
end

local function addAction(rows, byID, action, source, definition)
    action = normalized(action)
    if action == "" then return end
    local row = byID[action]
    if not row then
        row = {
            id = action,
            sources = {},
            transports = {},
            recognized = false,
            dispatchable = false,
        }
        byID[action] = row
        rows[#rows + 1] = row
    end

    local sourceSeen = {}
    for index = 1, #row.sources do sourceSeen[row.sources[index]] = true end
    appendUnique(row.sources, sourceSeen, source)
    row.recognized = true

    local transport = transportFor(source)
    if transport then
        local transportSeen = {}
        for index = 1, #row.transports do
            transportSeen[row.transports[index]] = true
        end
        appendUnique(row.transports, transportSeen, transport)
        row.dispatchable = true
    end

    if type(definition) == "table" then
        if type(definition.frame) == "table" then
            row.frame = copyPublic(definition.frame)
        end
        if type(definition.destinations) == "table" then
            row.destinations = copyPublic(definition.destinations)
        end
        if type(definition.requires) == "table" then
            row.requires = copyPublic(definition.requires)
        end
        if type(definition.metadata) == "table" then
            row.metadata = copyPublic(definition.metadata)
        end
        for _, field in ipairs({
            "workflowKind", "templateVersion", "contractVersion",
            "targetScope", "triggerFrames", "requiredSlots",
            "optionalSlots", "permissionGate", "outcomeMapping",
            "responsePools", "translationOwner",
        }) do
            if definition[field] ~= nil then
                row[field] = copyPublic(definition[field])
            end
        end
        if definition.capabilityID or definition.commandID
            or definition.handlerID or definition.route
        then
            row.binding = {
                id = definition.capabilityID,
                owner = definition.owner,
                route = definition.route,
                commandID = definition.commandID,
                handlerID = definition.handlerID,
                arguments = copyPublic(definition.arguments),
                requires = copyPublic(definition.requires),
                result = copyPublic(definition.result),
            }
            row.bindingID = definition.capabilityID
            row.bindingStatus = "registered"
        end
    end
end

local triggerFrame

function Catalog.ListActions()
    local rows = {}
    local byID = {}
    local semantics = PNC.Semantics
    local policy = semantics.DialoguePolicy

    if policy and type(policy.GetCommandActions) == "function" then
        for _, action in ipairs(policy.GetCommandActions()) do
            addAction(rows, byID, action, "dialogue_policy")
        end
    elseif policy and policy.Internal
        and type(policy.Internal.CommandActions) == "table"
    then
        for action in pairs(policy.Internal.CommandActions) do
            addAction(rows, byID, action, "dialogue_policy")
        end
    end

    local commandAdapter = semantics.CommandAdapter
    if commandAdapter and type(commandAdapter.Actions) == "table" then
        for action, definition in pairs(commandAdapter.Actions) do
            addAction(rows, byID, action, "command_adapter", definition)
        end
    end

    local taskAdapter = semantics.TaskAdapter
    if taskAdapter and type(taskAdapter.Actions) == "table" then
        for action, definition in pairs(taskAdapter.Actions) do
            addAction(rows, byID, action, "task_adapter", definition)
        end
    end

    local giftCapability = semantics.GiftCapability
    if type(giftCapability) == "table" then
        addAction(rows, byID, "GIFT", "gift_lifecycle", giftCapability)
    end

    local constraints = semantics.ContextConstraints
    if constraints and type(constraints.Actions) == "table" then
        for action, definition in pairs(constraints.Actions) do
            addAction(rows, byID, action, "context_constraint", definition)
        end
    end

    -- Some semantic actions are intentionally handled by dialogue policy
    -- branches rather than a task/command adapter (for example GIFT). They
    -- still belong in the discoverable action catalog because their NLU
    -- patterns can trigger flow branches.
    local registry = semanticRegistry()
    if registry and type(registry.GetPatterns) == "function" then
        for _, pattern in ipairs(registry.GetPatterns()) do
            local emit = pattern and pattern.emit
            if type(emit) == "table" and emit.action then
                addAction(rows, byID, emit.action, "nlu_pattern", {
                    frame = triggerFrame(emit),
                })
            end
        end
    end

    table.sort(rows, function(left, right) return left.id < right.id end)
    return rows
end

local function matchLabel(match)
    if type(match) ~= "table" then return "" end
    local parts = {}
    for index = 1, #match do
        local token = match[index]
        if type(token) == "string" then
            parts[#parts + 1] = token
        elseif type(token) == "table" then
            if token.kind == "literal" then
                parts[#parts + 1] = tostring(token.value or "<literal>")
            elseif token.kind == "concept" then
                parts[#parts + 1] = "@" .. tostring(token.id or "concept")
            elseif token.kind == "any_phrase" then
                parts[#parts + 1] = "<" .. tostring(token.capture or "phrase") .. ">"
            else
                parts[#parts + 1] = "<" .. tostring(token.kind or "token") .. ">"
            end
        end
    end
    return table.concat(parts, " ")
end

local TRIGGER_FIELDS = {
    "intent", "speechAct", "action", "subject", "target", "reference",
    "identityClaim", "selfDirected", "stateType", "stateValue",
}

triggerFrame = function(emit)
    local frame = {}
    if type(emit) ~= "table" then return frame end
    for index = 1, #TRIGGER_FIELDS do
        local field = TRIGGER_FIELDS[index]
        local value = emit[field]
        local capturePlaceholder = type(value) == "string"
            and string.find(value, "^%$capture%.") ~= nil
        if not capturePlaceholder
            and (type(value) == "string"
                or type(value) == "number"
                or type(value) == "boolean")
        then
            frame[field] = value
        end
    end
    return frame
end

function Catalog.ListTriggers(options)
    local registry = semanticRegistry()
    if not registry or type(registry.GetPatterns) ~= "function" then
        return {}
    end
    local includeDetails = type(options) == "table"
        and options.includeDetails == true

    local output = {}
    for _, pattern in ipairs(registry.GetPatterns()) do
        if type(pattern) == "table" and type(pattern.id) == "string" then
            local emit = type(pattern.emit) == "table" and pattern.emit or {}
            local row = {
                id = pattern.id,
                owner = pattern.owner,
                confidence = pattern.confidence,
                priority = pattern.priority,
                label = matchLabel(pattern.match),
                frame = triggerFrame(emit),
            }
            if includeDetails then
                row.match = copyPublic(pattern.match)
                row.emit = copyPublic(emit)
            end
            output[#output + 1] = row
        end
    end
    table.sort(output, function(left, right) return left.id < right.id end)
    return output
end

function Catalog.ListConcepts(options)
    local registry = semanticRegistry()
    if not registry or type(registry.ListConcepts) ~= "function" then
        return {}
    end
    local includeDetails = type(options) == "table"
        and options.includeDetails == true
    local output = {}
    for _, id in ipairs(registry.ListConcepts()) do
        local definition = type(registry.GetConcept) == "function"
            and registry.GetConcept(id) or nil
        local row = {
            id = id,
            owner = definition and definition.owner or nil,
        }
        if includeDetails then
            row.aliases = definition and copyPublic(definition.aliases) or {}
            row.metadata = definition and copyPublic(definition.metadata) or {}
        end
        output[#output + 1] = row
    end
    return output
end

function Catalog.ListSpeechActs()
    local registry = semanticRegistry()
    if not registry or type(registry.ListSpeechActs) ~= "function" then
        return {}
    end
    return copyPublic(registry.ListSpeechActs())
end

function Catalog.Snapshot()
    local registry = semanticRegistry()
    return {
        schemaVersion = Catalog.VERSION,
        registryRevision = registry and type(registry.GetRevision) == "function"
            and registry.GetRevision() or nil,
        actions = Catalog.ListActions(),
        triggers = Catalog.ListTriggers(),
        concepts = Catalog.ListConcepts(),
        speechActs = Catalog.ListSpeechActs(),
    }
end

function Catalog.ListCommandActions()
    local output = {}
    for _, action in ipairs(Catalog.ListActions()) do
        output[#output + 1] = action.id
    end
    return output
end

-- Generation is deliberately downstream of capability registration. The
-- generator consumes this live catalog and returns data-only flow artifacts;
-- it never becomes a second parser or dispatch path.
local AutomaticFlowGenerator = require
    "PNC/Semantics/PNC_SemanticAutomaticFlowGenerator"
local generatedAutomaticFlows = require
    "PNC/Semantics/PNC_SemanticGeneratedAutomaticFlows"
local function automaticGenerationSignature()
    local values = {}
    for _, action in ipairs(Catalog.ListActions()) do
        values[#values + 1] = table.concat({
            tostring(action.id or ""),
            tostring(action.bindingID or ""),
            tostring(action.workflowKind or ""),
        }, "|")
    end
    return table.concat(values, ";")
end

Catalog.AutomaticFlowGeneration = AutomaticFlowGenerator.Register(
    Catalog,
    generatedAutomaticFlows
)
Catalog.AutomaticFlowGeneration.sourceSignature =
    automaticGenerationSignature()

function Catalog.EnsureAutomaticGeneration()
    local signature = automaticGenerationSignature()
    local current = Catalog.AutomaticFlowGeneration
    if type(current) == "table" and current.sourceSignature == signature then
        return current
    end
    current = AutomaticFlowGenerator.Regenerate(Catalog)
    current.sourceSignature = signature
    Catalog.AutomaticFlowGeneration = current
    return current
end

return Catalog
