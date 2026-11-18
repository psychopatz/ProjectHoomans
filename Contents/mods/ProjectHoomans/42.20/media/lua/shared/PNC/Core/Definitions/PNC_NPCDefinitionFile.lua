-- One data-only file format for editor storage and authority-side discovery.
require "PNC/Core/Identity/PNC_NPCAuthoring"
local Json = require "PsychopatzCore/Bridge/PsychopatzBridgeJson"
PNC.NPCDefinitionFile = PNC.NPCDefinitionFile or {}
local File = PNC.NPCDefinitionFile
local B = PNC.NPCAuthoring.Blueprint
local R = PNC.NPCAuthoring.Registry
local limits = { maxString = 65536, maxDepth = 12, maxCollection = 512 }
function File.Encode(blueprint, produced)
    local serialized, reason = B.Serialize(blueprint)
    if not serialized then return nil, reason end
    return Json.Encode({ schemaId = R.SCHEMA_ID, schemaVersion = 2,
        authoringSchemaVersion = R.SCHEMA_VERSION, kind = "ProjectHoomans.UniqueNPC",
        produced = produced == true, definition = serialized }, limits)
end
function File.Decode(content)
    local payload = content and Json.Decode(content, limits)
    if type(payload) ~= "table" or payload.schemaId ~= R.SCHEMA_ID
        or payload.schemaVersion ~= 2 or payload.authoringSchemaVersion ~= R.SCHEMA_VERSION
        or payload.kind ~= "ProjectHoomans.UniqueNPC" then return nil, "unsupported_schema" end
    local blueprint, reason = B.Deserialize(payload.definition)
    if not blueprint then return nil, reason end
    return blueprint, nil, payload.produced == true
end
return File
