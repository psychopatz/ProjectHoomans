local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "client" },
    { "PsychopatzCore", "common" },
})

-- Exercise the repository cold, with an in-memory file/index mechanism.
-- Use the real blueprint schema and JSON codec; no window or playback runtime.
local files, entries = {}, {}
local indexFailure = false
local Database = { ROOT = "Hoomans", INDEX_PATH = "Hoomans/UniqueNPCIndex.txt" }
function Database.GetDirectory(kind) return "Hoomans/Opera Definitions" end
function Database.SafeFileName(name)
    if type(name) == "string" and name:match("^[%w%._%-]+%.txt$") then return name end
end
function Database.WriteFile(kind, name, content)
    T.equal(kind, "opera")
    files[name] = content
    return true
end
function Database.Upsert(kind, name, metadata)
    T.equal(kind, "opera")
    if indexFailure then return false, "index_write_failed" end
    entries[name] = metadata
    return true
end
function Database.ReadFile(kind, name)
    T.equal(kind, "opera")
    return files[name], files[name] and nil or "file_missing"
end
function Database.List(kind)
    T.equal(kind, "opera")
    local result = {}
    for _, entry in pairs(entries) do result[#result + 1] = entry end
    return result
end
PNC = { DefinitionDatabase = Database }
package.loaded["PNC/Core/Definitions/PNC_DefinitionDatabase"] = Database
local Storage = require "PNC/PuppetOpera/PNC_PuppetOperaStorage"
T.equal(Storage, PNC.PuppetOpera.Storage)
T.falsy(PNC.PuppetOperaDebugModel, "storage loaded editor state")
T.falsy(PNC.PuppetOpera.Client, "storage loaded playback client")
local Blueprints = PNC.PuppetOpera.Blueprints
local definition = Blueprints.Get("social.kiss_player_npc")
T.truthy(definition, "built-in schema fixture missing")
local ok, name, normalized = Storage.Save(definition)
T.truthy(ok, name)
T.equal(name, "social.kiss_player_npc.txt")
T.equal(entries[name].definitionType, "opera")
T.equal(entries[name].definitionId, definition.id)
local Json = require "PsychopatzCore/Bridge/PsychopatzBridgeJson"
local envelope = Json.Decode(files[name])
T.equal(envelope.schemaVersion, 1)
T.equal(envelope.kind, "ProjectHoomans.OperaDefinition")
T.equal(Storage.LoadFile(name).id, normalized.id)
T.equal(#Storage.List(), 1)
T.equal(#Storage.LoadAll(), 1)
local invalid, reason = Storage.LoadFile("../bad.txt")
T.falsy(invalid)
T.equal(reason, "invalid_file_name")
local saved = files[name]
files[name] = "{broken"
T.equal(Storage.List()[1].error, "invalid_json")
T.equal(#Storage.LoadAll(), 0, "corrupt definition entered playback candidates")
files[name] = saved
indexFailure = true
ok, reason = Storage.Save(definition)
T.falsy(ok)
T.equal(reason, "index_write_failed")
ok, reason = Storage.Save({ id = "../invalid" })
T.falsy(ok)
T.equal(reason, "definition_id_invalid")
T.falsy(PNC.PuppetOperaDebugModel)
print("PASS: cold Puppet Opera definition storage and failure contracts")
