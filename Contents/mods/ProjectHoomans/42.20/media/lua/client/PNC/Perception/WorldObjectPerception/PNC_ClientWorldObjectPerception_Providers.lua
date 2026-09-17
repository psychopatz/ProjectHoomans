-- Ordered provider hub for client-local world-object perception.
-- Each built-in classifier registers as a spoke, then this hub attaches the
-- shared primitive fact composition used by snapshot assembly.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and PsychopatzCore.RuntimeRole.AllowsClientCode
    and not PsychopatzCore.RuntimeRole.AllowsClientCode()
then return end

local Perception = PNC.Perception.WorldObjects
local Internal = Perception.Internal

require "PNC/Perception/WorldObjectPerception/PNC_ClientWorldObjectPerception_ProvidersSemantic"
require "PNC/Perception/WorldObjectPerception/PNC_ClientWorldObjectPerception_ProvidersRoom"
require "PNC/Perception/WorldObjectPerception/PNC_ClientWorldObjectPerception_ProvidersSurfaces"
require "PNC/Perception/WorldObjectPerception/PNC_ClientWorldObjectPerception_ProvidersWater"
require "PNC/Perception/WorldObjectPerception/PNC_ClientWorldObjectPerception_ProvidersCampfire"

local function text(value, maximum)
    return Internal.Text(value, maximum)
end

local function describeObject(object, square, record, context)
    local metadata = record and record.metadata or {}
    local facts = {
        nativeName = Internal.ObjectName(metadata),
        objectName = text(metadata.objectName, 96),
        displayName = text(metadata.displayName, 96),
        spriteName = text(metadata.spriteName, 96),
        objectKey = text(record and record.objectKey, 128),
        targetID = text(record and record.targetID, 128),
        resourceKey = text(record and record.resourceKey, 128),
        usage = {},
        jobs = {},
        capabilities = {},
        diagnostics = {},
        providerStates = {},
    }
    for index = 1, #Perception.ProviderOrder do
        local id = Perception.ProviderOrder[index]
        local provider = Perception.Providers[id]
        if provider then
            local ok, result = pcall(provider.describe, object, square,
                record, context)
            if ok and type(result) == "table" then
                Internal.MergeFacts(facts, result)
            elseif not ok then
                facts.providerStates[#facts.providerStates + 1] = {
                    id = id, status = "error",
                }
            end
        end
    end
    if #facts.usage == 0 then facts.usage = nil end
    if #facts.jobs == 0 then facts.jobs = nil end
    if #facts.capabilities == 0 then facts.capabilities = nil end
    if #facts.diagnostics == 0 then facts.diagnostics = nil end
    if #facts.providerStates == 0 then facts.providerStates = nil end
    return facts
end

-- Keep the shared fact composer public for future perception domains and
-- focused tests; providers themselves remain independently replaceable.
Internal.DescribeObject = describeObject

return Perception
