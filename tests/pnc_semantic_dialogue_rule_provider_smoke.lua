local T = require "tests/support/test"
T.addPackagePaths()

PNC = {}
local Provider = T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticDialogueRuleProvider.lua")

T.falsy(Provider.IsBound(), "rule provider starts unbound")
local passed, reason = Provider.EvaluateGateStatus({}, {})
T.equal(passed, "UNKNOWN", "unbound rules fail closed")
T.equal(reason, "conversation_rules_unavailable",
    "unbound rules expose a bounded reason")

local implementation = {
    EvaluateGateStatus = function(gate, context)
        return "PASS", "test_bound"
    end,
}
local bound, bindReason = Provider.Bind(implementation)
T.truthy(bound, bindReason)
T.truthy(Provider.IsBound(), "rule provider reports its binding")
local status, statusReason = Provider.EvaluateGateStatus({}, {})
T.equal(status, "PASS", "bound rules delegate gate evaluation")
T.equal(statusReason, "test_bound", "bound rules preserve the reason")

local Kernel = T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticDialogueFlowKernel.lua")
T.equal(Kernel.Internal.Rules, Provider,
    "flow kernel consumes the semantic rule provider contract")

T.finish("pnc_semantic_dialogue_rule_provider_smoke")
