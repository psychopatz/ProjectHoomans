local T = require "tests/support/test"
local suggestions = dofile(
    T.path("ProjectHoomans", "common_lua", "PNC/")
        .. "ConvoEngine/UI/Dialogue/"
        .. "CompanionCheckIn.lua"
)

local expected = {
    "question.needs",
    "question.health",
    "question.gossip",
}

assert(type(suggestions) == "table", "Hoomans ConvoEngine UI projection did not return a table")
assert(#suggestions == #expected, "Hoomans companion check-in offer count changed")
for index, expectedID in ipairs(expected) do
    local row = suggestions[index]
    assert(row.id == expectedID, "Hoomans ConvoEngine UI projection reordered " .. expectedID)
    assert(row.patternID and row.patternID ~= "", "ConvoEngine offer lost its semantic pattern reference")
    assert(row.labelKey and row.utteranceKey, "Core did not generate UI translation keys")
    assert(row.labelFallback and row.utteranceFallback, "ConvoEngine offer lost EN fallback data")
    assert(row.display == nil, "ConvoEngine offer must not embed multi-locale display data")
end

local needs = suggestions[1]
assert(needs.dialogueFollowUp == "NEEDS_QUANTITY", "Needs follow-up metadata changed")
assert(needs.hubID == "whats_up", "Needs hub metadata changed")

local health = suggestions[2]
assert(health.target == "SELF", "Health target lost its typed semantic target")
assert(health.slots and health.slots.attribute == "health_state", "Health slot binding changed")
assert(health.extensions and health.extensions.topic == "medical", "Health extension metadata changed")

local gossip = suggestions[3]
assert(gossip.hubOnly == true, "Gossip hub-only constraint changed")
assert(gossip.hubRequiresSafeGossip == true, "Gossip safety constraint changed")

print("pnc_convo_ui_projection_smoke: PASS")
