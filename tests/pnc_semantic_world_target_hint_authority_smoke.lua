local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = {}
local objectName = "IsoObject"
local object = {
    getObjectName = function() return "IsoObject" end,
    getName = function() return objectName end,
    getSpriteName = function()
        return objectName == "chair" and nil or "trashcontainers_01_16"
    end,
    getSprite = function()
        return {
            getName = function()
                return objectName == "chair" and nil
                    or "trashcontainers_01_16"
            end,
        }
    end,
    getID = function() return 88 end,
}
local calls = 0
PNC = {
    NearbyResourceLocator = {
        FindObject = function(_, options)
            calls = calls + 1
            local candidate = {
                object = object,
                key = "trashcontainers_01_16@12:14:0#88",
                x = 12.5,
                y = 14.5,
                z = 0,
            }
            return options.accept(candidate) and candidate or nil
        end,
    },
    Semantics = {},
}

local Semantic = T.load(
    "PsychopatzCore",
    "common",
    "PsychopatzCore/Semantics/PsychopatzSemantic.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticWorldTargetCatalog.lua"
)
local Contract = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticTaskRequest.lua"
)
T.load(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/PNC_SemanticWorldTargetResolver.lua"
)
local Resolver = PNC.Semantics.WorldTargetResolver

local ir = Semantic.IR.New({
    rawText = "wait at the recycel bin",
    normalizedText = "wait at the recycel bin",
    intent = "REQUEST",
    speechAct = "REQUEST",
    action = "WAIT_AT",
    target = {
        kind = "phrase",
        text = "recycel bin",
        unresolved = true,
        clientHint = {
            version = 1,
            source = "client_loaded_world",
            kind = "recycle_bin",
            x = 12.5,
            y = 14.5,
            z = 0,
            score = 0.93,
        },
    },
    confidence = 0.94,
})
local request = Contract.FromIR(ir, {
    requestID = "dialogue:hint:1",
    rawText = ir.rawText,
    recipient = { id = "npc:alice" },
})
T.truthy(request and request.target and request.target.clientHint,
    "the task contract preserves a primitive client hint")
T.falsy(request.target.clientHint.object,
    "request normalization strips any live object from the hint")

local target, reason = Resolver.Resolve(request.target, {
    record = { x = 10, y = 10, z = 0 },
})
T.truthy(target, "the server resolves a hinted object through its own locator")
T.equal(reason, nil, "a valid client hint has no resolution error")
T.equal(target.kind, "recycle_bin", "the server keeps the canonical target kind")
T.equal(target.targetID, "trashcontainers_01_16@12:14:0#88",
    "the server, not the client, supplies the authoritative object identity")
T.equal(target.clientHintAccepted, true,
    "the server reports that the hint matched an authoritative object")
T.falsy(target.object, "the final assignment remains primitive")
T.equal(calls, 1, "a valid hint needs one bounded authoritative lookup")

local rejected = Resolver.Resolve({
    kind = "phrase",
    text = "bin",
    unresolved = true,
    clientHint = {
        kind = "campfire",
        x = 99999,
        y = 99999,
        z = 0,
        score = 1,
    },
}, { record = { x = 10, y = 10, z = 0 } })
T.truthy(rejected, "a bad hint falls back to server-side target discovery")
T.equal(rejected.clientHintAccepted, false,
    "a mismatched or stale hint is never treated as authoritative")
T.equal(rejected.clientHintRejected, true,
    "hint rejection remains visible to semantic diagnostics")

objectName = "chair"
local chairTarget, chairReason = Resolver.Resolve({
    kind = "phrase",
    text = "chair",
}, { record = { x = 10, y = 10, z = 0 } })
T.truthy(chairTarget, "catalog profiles support ordinary world objects")
T.equal(chairReason, nil, "a generic catalog object resolves without an LLM")
T.equal(chairTarget.kind, "chair",
    "the generic provider preserves the registered profile kind")
objectName = "IsoObject"

T.finish("pnc_semantic_world_target_hint_authority_smoke")
