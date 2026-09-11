local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/Knowledge/")
PNC = {}
T.load(ROOT .. "PNC_KnowledgeRegistry.lua")
T.load(ROOT .. "PNC_KnowledgeBuiltins.lua")

local source = PNC.KnowledgeEvidenceSources.Get("radio_disclosure")
T.truthy(source, "radio introductions have a registered evidence source")
T.equal(source.reliability, 1,
    "radio introductions preserve authoritative fact reliability")
T.equal(source.mayConfirm, true,
    "radio introductions can confirm identity and faction facts")
T.equal(source.bypassDiscovery, true,
    "radio introductions do not require a face-to-face discovery path")
T.equal(PNC.KnowledgeDescriptors.Get("identity.name").presentation.topicID,
    "identity_name", "radio identity uses the name knowledge topic")
T.equal(PNC.KnowledgeDescriptors.Get("faction.identity").presentation.topicID,
    "faction", "radio faction uses the faction knowledge topic")

T.finish("pnc_radio_discovery_knowledge_smoke")
