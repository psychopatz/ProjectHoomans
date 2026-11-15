local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = PsychopatzCore or {}
PNC = PNC or {
    Const = { MODULE = "PNC" },
    Core = { IsClientOnly = function() return false end, Now = function() return 100 end },
    Semantics = {},
    ConvoEngine = {},
}

require "PsychopatzCore/Semantics/PsychopatzSemantic"
require "PNC/Semantics/PNC_SemanticEngineFacts"
require "PNC/Semantics/PNC_SemanticEngineEvents"
require "PNC/ConvoEngine/Registry"
require "PNC/ConvoEngine/Dialogue/ResponseCatalog"

local ResponseCatalog = PNC.ConvoEngine.ResponseCatalog
local FlowRegistry = PNC.ConvoEngine.DialogueFlowRegistry
    or require "PNC/ConvoEngine/Dialogue/FlowRegistry"
local Generator = require "PNC/ConvoEngine/FlowGenerator"

-- Verify parameterized task / command / quest templateIDs resolve to non-empty fallbacks.
local okValid, resValid = ResponseCatalog.Preflight("semantic.s10a.valid.check", {
    variants = {
        { id = "default", templateID = "task.consume.active" },
        { id = "friendly", templateID = "command.follow.queued.friendly" },
        { id = "combat", templateID = "combat.horde.ack.engage_default" },
    },
}, { strictVariants = true })
T.truthy(okValid, "canonical ConvoPlan templates should pass strict Preflight")

-- Capture pre-failure counts so preflight failure is proven atomic (zero partial mutation).
local function countMap(tbl)
    local n = 0
    for _ in pairs(tbl or {}) do n = n + 1 end
    return n
end

local poolsBefore = countMap(ResponseCatalog.POOLS)
local poolRevBefore = ResponseCatalog.REVISION or 0
local flowRevBefore = FlowRegistry.GetRevision()

-- Build a synthetic catalog artifact containing both a valid pool and an invalid variant.
local brokenArtifact = {
    coverage = {
        { id = "BROKEN_ACTION", capabilityID = "pnc:task.broken" },
    },
    responsePools = {
        {
            id = "semantic.generated.parameterized_task.valid_canary.active",
            capabilityID = "pnc:task.canary",
            action = "VALID_CANARY",
            variants = {
                { id = "default", templateID = "task.consume.active" },
            },
        },
        {
            id = "semantic.generated.parameterized_task.broken_action.active",
            capabilityID = "pnc:task.broken",
            action = "BROKEN_ACTION",
            variants = {
                { id = "default", templateID = "task.consume.active" },
                { id = "broken_var", templateID = "missing.unresolvable.template" },
            },
        },
    },
    flows = {
        {
            id = "pnc.generated.parameterized_task.pnc.task.broken",
            nodes = {
                active = {
                    responsePool = "semantic.generated.parameterized_task.broken_action.active",
                },
            },
        },
    },
}

local fakeCatalog = { VERSION = 1 }
local okFail, errFail = pcall(function()
    Generator.Register(fakeCatalog, brokenArtifact)
end)
T.falsy(okFail, "preflight must fail closed on unresolvable automatic variant")
local errText = tostring(errFail or "")
T.truthy(string.find(errText, "pool=semantic.generated.parameterized_task.broken_action.active", 1, true),
    "diagnostic must name pool: " .. errText)
T.truthy(string.find(errText, "reason=", 1, true),
    "diagnostic must name reason: " .. errText)
T.truthy(string.find(errText, "capability=pnc:task.broken", 1, true),
    "diagnostic must name capability: " .. errText)
T.truthy(string.find(errText, "action=BROKEN_ACTION", 1, true),
    "diagnostic must name action: " .. errText)
T.truthy(string.find(errText, "template=missing.unresolvable.template", 1, true),
    "diagnostic must name template: " .. errText)
T.truthy(string.find(errText, "realization=broken_var", 1, true),
    "diagnostic must name realization: " .. errText)

-- Verify neither ResponseCatalog nor FlowRegistry was partially mutated by valid_canary.
T.falsy(ResponseCatalog.Get("semantic.generated.parameterized_task.valid_canary.active"),
    "canary pool must not leak into ResponseCatalog when batch preflight fails")
T.equal(countMap(ResponseCatalog.POOLS), poolsBefore, "pool count unchanged after failed preflight")
T.equal(ResponseCatalog.REVISION or 0, poolRevBefore, "ResponseCatalog revision unchanged")
T.equal(FlowRegistry.GetRevision(), flowRevBefore, "FlowRegistry revision unchanged")

print("pnc_s10a_flow_preflight_smoke PASS")
