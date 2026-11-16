local T = require "tests/support/test"

T.addPackagePaths()

local indexContent = [[
{"schemaVersion":2,"kind":"ProjectHoomans.DefinitionIndex","entries":[
{"definitionType":"npc","fileName":"Example.txt","displayName":"Example"},
{"definitionType":"starter","fileName":"Family.txt","displayName":"Family"}
]}
]]

local function readerFor(content)
    local lines = {}
    for line in string.gmatch(content, "([^\n]*)\n?") do
        lines[#lines + 1] = line
    end
    local index = 0
    return {
        readLine = function()
            index = index + 1
            return lines[index]
        end,
        close = function() end,
    }
end

getFileReader = function(path)
    if path == "Hoomans/UniqueNPCIndex.txt" then
        return readerFor(indexContent)
    end
    return nil
end

PNC = {}
local Database = require "PNC/Core/Definitions/PNC_DefinitionDatabase"
local npcEntries = Database.List("npc")
local starterEntries = Database.List("starter")
local index = Database.ReadIndex()

T.equal(#npcEntries, 1,
    "definition index lists NPC entries without crashing")
T.equal(npcEntries[1].fileName, "Example.txt",
    "definition index preserves the NPC filename")
T.equal(#starterEntries, 1,
    "definition index lists starter entries independently")
T.equal(#index.files, 1,
    "definition index exposes its derived NPC file list")
T.equal(index.files[1], "Example.txt",
    "derived NPC file list contains the expected filename")

T.finish("pnc_definition_database_smoke")
