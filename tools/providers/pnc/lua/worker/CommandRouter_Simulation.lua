-- Semantic Lab control metadata for the semantic worker router.

local Persona = require "worker/CommandRouter_Persona"
local RuntimeControls = require "worker/CommandRouter_Simulation_RuntimeControls"
local ActorControls = require "worker/CommandRouter_Simulation_ActorControls"
local AdvancedControls = require "worker/CommandRouter_Simulation_AdvancedControls"
local Simulation = {}

local function simulationControlCatalog(context, payload)
    local persona = Persona.catalog(context, payload)
    local controls = {}

    local function add(id, path, page, section, label, control, valueType, details)
        local row = {
            id = id,
            path = path,
            page = page,
            section = section,
            label = label,
            control = control,
            valueType = valueType,
        }
        for key, value in pairs(details or {}) do
            row[key] = value
        end
        controls[#controls + 1] = row
    end

    local function withNone(values)
        local result = { "none" }
        for index = 1, math.min(#(values or {}), 64) do
            if values[index] ~= "none" then
                result[#result + 1] = values[index]
            end
        end
        return result
    end

    local roles = withNone(persona.roles)
    local bondKinds = {}
    local traits = {}
    local playerTraitOptions = {}
    for index = 1, math.min(#(persona.relationshipKinds or {}), 64) do
        bondKinds[#bondKinds + 1] = persona.relationshipKinds[index].kind
    end
    for index = 1, math.min(#(persona.traits or {}), 64) do
        traits[#traits + 1] = {
            value = persona.traits[index].id,
            label = persona.traits[index].label or persona.traits[index].id,
        }
    end
    for index = 1, math.min(#(persona.playerTraits or {}), 64) do
        playerTraitOptions[#playerTraitOptions + 1] = {
            value = persona.playerTraits[index].id,
            label = persona.playerTraits[index].label
                or persona.playerTraits[index].id,
        }
    end

    RuntimeControls.append(add, context)


    ActorControls.append(
        add,
        context,
        persona,
        roles,
        traits,
        playerTraitOptions,
        bondKinds
    )


    AdvancedControls.append(add)

    add("runtime.nativeTranslations", "runtime.nativeTranslations", "Advanced", "Worker seams", "Native translations · Advanced JSON", "advanced_json", "object")

    return {
        schema = "semantic.simulation.control.catalog.v1",
        schemaVersion = 1,
        maxControls = 96,
        controls = controls,
    }
end


Simulation.catalog = simulationControlCatalog

function Simulation.handle(context, command, payload)
    local Runtime = context.Runtime
    local Values = context.Values

    if command == "SIMULATION_CONTROL_CATALOG" then
        return simulationControlCatalog(context, payload)
    end
    return false
end

return Simulation
