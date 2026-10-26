local T = require "tests/support/test"
T.addPackagePaths()

PNC = {}
local Provider = T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticConversationMemoryProvider.lua")

T.falsy(Provider.IsBound(), "memory provider starts unbound")
T.equal(Provider.GetBackstory({}, "hometown"), nil,
    "unbound memory does not expose a record")

local implementation = {
    GetBackstory = function(record, kind)
        return { id = "fact:" .. tostring(kind) }
    end,
    GetBackstoryText = function(fact, language)
        return tostring(fact.id) .. ":" .. tostring(language)
    end,
    RenderText = function(template, arguments)
        return template
    end,
}
local bound, bindReason = Provider.Bind(implementation)
T.truthy(bound, bindReason)
T.truthy(Provider.IsBound(), "memory provider reports its binding")
T.equal(Provider.GetBackstory({}, "hometown").id, "fact:hometown",
    "bound memory delegates backstory lookup")
T.equal(Provider.GetBackstoryText({ id = "fact:hometown" }, "EN"),
    "fact:hometown:EN", "bound memory delegates text lookup")

T.finish("pnc_semantic_conversation_memory_provider_smoke")
