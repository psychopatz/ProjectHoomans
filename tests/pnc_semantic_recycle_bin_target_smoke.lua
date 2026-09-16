local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = {}
local recycleBin = {
    getObjectName = function() return "IsoObject" end,
    getName = function() return nil end,
    getSpriteName = function() return "trashcontainers_01_16" end,
    getSprite = function()
        return { getName = function() return "trashcontainers_01_16" end }
    end,
    getID = function() return 88 end,
}
local calls = 0
PNC = {
    NearbyResourceLocator = {
        FindObject = function(_, options)
            calls = calls + 1
            local candidate = {
                object = recycleBin,
                key = "trashcontainers_01_16@12:14:0#88",
                x = 12.5, y = 14.5, z = 0,
            }
            return options.accept(candidate) and candidate or nil
        end,
    },
    Semantics = {},
}

T.load(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/PNC_SemanticWorldTargetResolver.lua"
)
local Resolver = PNC.Semantics.WorldTargetResolver
local target, reason = Resolver.Resolve({
    kind = "phrase",
    text = "recycle bin",
    unresolved = true,
}, { record = { x = 10, y = 10, z = 0 } })

T.equal(reason, nil, "recycle-bin phrase resolves without an LLM")
T.truthy(target, "recycle-bin target is found")
T.equal(target.kind, "recycle_bin", "alias selects the object provider")
T.equal(target.targetID, "trashcontainers_01_16@12:14:0#88",
    "object identity is stable and primitive")
T.equal(target.x, 12.5, "object approach x is retained")
T.equal(target.y, 14.5, "object approach y is retained")
T.falsy(target.object, "Java object does not cross the plan boundary")
T.equal(calls, 1, "object lookup is bounded")

T.finish("pnc_semantic_recycle_bin_target_smoke")
