-- Disposable fixture orchestration for the production Combat Observatory.
-- The worker owns only fixture setup; all decisions/snapshots come from
-- ProjectHoomans production Lua modules.
local CombatObservatory = {}

local MAX_MOMENTS = 8
local MAX_OPERATIONS = 12
local MAX_TRANSITIONS = 4

local function requireProduction()
    local Moment = PNC.Semantics.CombatMoment
        or require "PNC/Semantics/PNC_SemanticCombatMoment"
    local Arbiter = PNC.Semantics.CombatBanterArbiter
        or require "PNC/Semantics/PNC_SemanticCombatBanterArbiter"
    local Encounter = PNC.Semantics.CombatEncounterIntent
        or require "PNC/Semantics/PNC_SemanticCombatEncounterIntent"
    local Observatory = PNC.Semantics.CombatObservatory
        or require "PNC/Semantics/PNC_SemanticCombatObservatory"
    return Moment, Arbiter, Encounter, Observatory
end

local function boundedCount(map)
    local count = 0
    for _ in pairs(type(map) == "table" and map or {}) do
        count = count + 1
    end
    return count
end

local function buildRecord(context, payload)
    local Values = context.Values
    local scenarioNPC = context.Runtime.scenario
        and context.Runtime.scenario.npc or {}
    local source = type(payload.record) == "table"
        and payload.record or {}
    local record = Values.copy(source)
    record.id = tostring(
        record.id or record.npcID
            or scenarioNPC.npcID or scenarioNPC.identitySeed or "npc_fixture"
    )
    record.alive = record.alive ~= false
    record.runtime = type(record.runtime) == "table" and record.runtime or {}
    return record
end

local function buildMoments(Moment, definitions)
    definitions = type(definitions) == "table" and definitions or {}
    if boundedCount(definitions) > MAX_MOMENTS then
        return nil, "combat_observatory_too_many_moments"
    end
    local output = {}
    for id, definition in pairs(definitions) do
        if type(id) ~= "string" or id == ""
            or type(definition) ~= "table"
        then
            return nil, "combat_observatory_moment_invalid"
        end
        output[id] = Moment.Build(definition)
    end
    return output
end

local function momentFor(moments, operation)
    local id = tostring(operation.momentID or "")
    if id == "" then return nil end
    return moments[id]
end

local function operationSpec(context, operation, moment)
    local spec = context.Values.copy(
        type(operation.spec) == "table" and operation.spec or {}
    )
    spec.moment = moment
    return spec
end

local function runOperations(
    context, Moment, Arbiter, Encounter, record, moments, operations
)
    operations = type(operations) == "table" and operations or {}
    if #operations > MAX_OPERATIONS then
        return nil, "combat_observatory_too_many_operations"
    end
    local gates = {}
    local results = {}
    for index = 1, #operations do
        local operation = operations[index]
        if type(operation) ~= "table" then
            return nil, "combat_observatory_operation_invalid"
        end
        local kind = tostring(operation.kind or "")
        local moment = momentFor(moments, operation)
        if kind == "reserve" then
            if not moment then
                return nil, "combat_observatory_moment_missing"
            end
            local spec = operationSpec(context, operation, moment)
            local accepted, reason, burst, gate = Arbiter.Reserve(spec)
            results[#results + 1] = {
                kind = kind,
                accepted = accepted == true,
                reason = reason,
                burstCount = burst,
            }
            if gate and operation.gateID then
                gates[tostring(operation.gateID)] = gate
            end
        elseif kind == "begin" then
            if not moment then
                return nil, "combat_observatory_moment_missing"
            end
            local spec = operationSpec(context, operation, moment)
            local gate, reason, burst = Arbiter.Begin(spec)
            local gateID = tostring(operation.gateID or "")
            if gate and gateID ~= "" then gates[gateID] = gate end
            results[#results + 1] = {
                kind = kind,
                accepted = gate ~= nil,
                reason = reason,
                burstCount = burst,
            }
        elseif kind == "consider" then
            if not moment then
                return nil, "combat_observatory_moment_missing"
            end
            local gate = gates[tostring(operation.gateID or "")]
            local spec = operationSpec(context, operation, moment)
            local accepted, reason = Arbiter.Consider(gate, spec)
            results[#results + 1] = {
                kind = kind,
                accepted = accepted == true,
                reason = reason,
            }
        elseif kind == "presentation" then
            if not moment then
                return nil, "combat_observatory_moment_missing"
            end
            local spec = operationSpec(context, operation, moment)
            local row = Arbiter.RecordPresentation(spec)
            results[#results + 1] = {
                kind = kind,
                accepted = row and row.accepted == true,
                reason = row and row.reason,
            }
        else
            return nil, "combat_observatory_operation_unknown"
        end
    end
    return results
end

local function applyEncounter(Encounter, record, payload)
    local transitions = type(payload.encounterTransitions) == "table"
        and payload.encounterTransitions or {}
    if #transitions > MAX_TRANSITIONS then
        return false, "combat_observatory_too_many_transitions"
    end
    for index = 1, #transitions do
        local row = transitions[index]
        if type(row) ~= "table" then
            return false, "combat_observatory_transition_invalid"
        end
        Encounter.OnHordeTransition(
            record,
            row.phase,
            row.episodeID,
            row.now
        )
    end
    local resolution = payload.resolveIntent
    if type(resolution) == "table" then
        Encounter.Resolve(
            record,
            resolution.intent,
            resolution.eventRef,
            resolution.source or "semantic_harness",
            resolution.now
        )
    end
    return true
end

function CombatObservatory.fixture(context, payload)
    payload = type(payload) == "table" and payload or {}
    local Moment, Arbiter, Encounter, Observatory = requireProduction()
    local record = buildRecord(context, payload)
    local moments, momentReason = buildMoments(Moment, payload.moments)
    if not moments then return nil, momentReason end

    Arbiter.ResetRuntime()
    Encounter.ResetRuntime()
    local encounterOK, encounterReason = applyEncounter(
        Encounter, record, payload
    )
    if not encounterOK then return nil, encounterReason end
    local operations, operationReason = runOperations(
        context,
        Moment,
        Arbiter,
        Encounter,
        record,
        moments,
        payload.operations
    )
    if not operations then return nil, operationReason end

    context.Runtime.combatObservatoryRecord = record
    local inspectOptions = context.Values.copy(
        type(payload.inspect) == "table" and payload.inspect or {}
    )
    inspectOptions.npcID = inspectOptions.npcID or record.id
    local view = Observatory.Inspect(record, inspectOptions)
    view.ok = true
    view.type = "combat_observatory_fixture"
    view.sourceKind = "FIXTURE"
    view.workerKind = "production_lua"
    view.operations = operations
    return view
end

function CombatObservatory.inspect(context, payload)
    payload = type(payload) == "table" and payload or {}
    local _, _, _, Observatory = requireProduction()
    local record = context.Runtime.combatObservatoryRecord
    if not record then
        record = buildRecord(context, { record = payload.record })
    end
    local options = context.Values.copy(payload)
    options.record = nil
    options.npcID = options.npcID or record.id
    local view = Observatory.Inspect(record, options)
    view.ok = true
    view.type = "combat_observatory_inspection"
    view.sourceKind = context.Runtime.combatObservatoryRecord
        and "FIXTURE_RUNTIME" or "FIXTURE"
    view.workerKind = "production_lua"
    return view
end

return CombatObservatory
