local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = {}
PNC = {}

local Semantic = T.load(
    "PsychopatzCore",
    "common",
    "PsychopatzCore/Semantics/PsychopatzSemantic.lua"
)
local Catalog = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticCatalog.lua"
)
local GeneratedLexicon = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticGeneratedLexicon.lua"
)
local Policy = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialoguePolicy.lua"
)
local EntityResolver = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticEntityResolver.lua"
)
local ReferenceResolver = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueReferenceResolver.lua"
)

local Parser = Semantic.Parser
local retrieve = Parser.Parse("Retrieve me some water.")
T.equal(retrieve.action, "FETCH", "WordNet retrieve synonym maps to FETCH")
T.equal(retrieve.object.category, "WATER", "retrieve keeps the existing object slot")

local grab = Parser.Parse("Grab some food.")
T.equal(grab.action, "FETCH", "the base grab lemma remains an executable alias")
T.equal(grab.diagnostics.fuzzyMatch, false,
    "the base lemma does not depend on fuzzy matching")

local pickUp = Parser.Parse("Pick up some food.")
T.equal(pickUp.action, "FETCH", "multiword WordNet synonym maps to FETCH")
T.equal(pickUp.object.category, "FOOD", "pick up keeps the object slot")

local takeHold = Parser.Parse("Take hold of some food.")
T.equal(takeHold.action, "FETCH", "sense-selected phrase maps to FETCH")
T.equal(takeHold.object.category, "FOOD", "take hold of keeps the object slot")

local followingForm = Catalog.ResolveVerbForm("FOLLOWING")
T.equal(followingForm.concept, "FOLLOW",
    "WordNet progressive morphology resolves to the reviewed follow concept")
T.equal(followingForm.lemma, "follow",
    "follow morphology retains its selected WordNet lemma")
T.equal(followingForm.form, "PROGRESSIVE",
    "follow morphology retains its grammatical form")
local registeredFollowing = Semantic.Registry.LookupVerbForm("following")
T.equal(registeredFollowing.concept, "FOLLOW",
    "the generated form is registered in the existing Core index")

local stopFollowing = Parser.Parse("Please stop following me.")
T.equal(stopFollowing.action, "STOP",
    "the opt-in progressive form maps to the existing stop action")
T.equal(stopFollowing.diagnostics.matchedPattern, "pnc.command.stop_following",
    "following is accepted only by the explicit stop-following grammar")
T.equal(stopFollowing.analysis.symbols[3].matchType, "verb_form",
    "the parser retains form provenance on the recognized verb")
T.equal(stopFollowing.analysis.symbols[3].verbForm.form, "PROGRESSIVE",
    "the matched rule sees the progressive form tag")

local followingStatement = Parser.Parse("I was following you.")
T.falsy(followingStatement.action,
    "a progressive statement is not converted into a gameplay command")
T.equal(followingStatement.diagnostics.noMatch, true,
    "the statement stays unresolved without a matching conversation rule")

local grabsForm = Catalog.ResolveVerbForm("grabs")
T.equal(grabsForm.concept, "FETCH",
    "third-person morphology resolves to the selected game concept")
T.equal(grabsForm.lemma, "grab",
    "third-person morphology retains its base lemma")
T.equal(grabsForm.form, "THIRD_PERSON",
    "third-person morphology retains its grammatical form")
local grabs = Parser.Parse("Grabs some food.")
T.falsy(grabs.action,
    "a third-person form cannot satisfy an imperative FETCH pattern")
T.equal(grabs.diagnostics.noMatch, true,
    "a third-person form without a conversation rule remains unmatched")
T.equal(grabs.diagnostics.fuzzyMatch, false,
    "exact morphology does not depend on fuzzy action recognition")
T.equal(Policy.Decide(grabs, nil, { llmEnabled = false }).branch,
    "ASK_CLARIFICATION", "an unmatched form is not approved as a command")

local grabbedForm = Catalog.ResolveVerbForm("GRABBED")
T.equal(grabbedForm.concept, "FETCH",
    "WordNet past morphology resolves to the selected game concept")
T.equal(grabbedForm.lemma, "grab",
    "past morphology retains its base lemma")
T.equal(grabbedForm.form, "PAST",
    "past morphology retains its grammatical form")
local grabbed = Parser.Parse("Grabbed me some food.")
T.falsy(grabbed.action,
    "a past-tense form is not accepted as an executable FETCH command")

local grabbingForm = Catalog.ResolveVerbForm("grabbing")
T.equal(grabbingForm.concept, "FETCH",
    "WordNet progressive morphology resolves to the selected game concept")
T.equal(grabbingForm.lemma, "grab",
    "progressive morphology retains its base lemma")
T.equal(grabbingForm.form, "PROGRESSIVE",
    "progressive morphology retains its grammatical form")
local grabbing = Parser.Parse("Grabbing me some food.")
T.falsy(grabbing.action,
    "a progressive form is not accepted as an executable FETCH command")
T.equal(grabbing.diagnostics.noMatch, true,
    "a progressive form cannot be captured as an item request")

local verbFormAsItem = Parser.Parse("Bring me grabbing")
T.falsy(verbFormAsItem.action,
    "a recognized verb form is not reclassified as an item name")
T.equal(verbFormAsItem.diagnostics.noMatch, true,
    "verb morphology stays out of generic entity captures")

local pickedUpForm = Catalog.ResolveVerbForm("Picked up")
T.equal(pickedUpForm.lemma, "pick up",
    "multiword morphology resolves to the selected phrase lemma")
T.equal(pickedUpForm.form, "PAST",
    "multiword past morphology retains its grammatical form")
local pickedUp = Parser.Parse("Picked up some food.")
T.falsy(pickedUp.action,
    "a past form cannot satisfy an imperative FETCH pattern")
T.equal(pickedUp.diagnostics.noMatch, true,
    "a past form without a statement rule remains unmatched")
T.equal(pickedUp.diagnostics.fuzzyMatch, false,
    "exact past morphology does not use fuzzy action matching")
local pickedUpDecision = Policy.Decide(pickedUp, nil, { llmEnabled = false })
T.equal(pickedUpDecision.branch, "ASK_CLARIFICATION",
    "an unmatched past-form report is sent to clarification")
T.equal(pickedUpDecision.actionIntent, nil,
    "the decision contains no executable FETCH candidate")

PNC.Semantics.DialogueInput = { Internal = {} }
local DialogueInput = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticDialogueInput_Actions.lua"
)
local blockedCandidate = DialogueInput.Internal.DispatchAction({}, {
    sequence = "morphology:1",
    ir = pickedUp,
    decision = pickedUpDecision,
}, "Picked up some food.")
T.equal(blockedCandidate, nil,
    "an unmatched past-form report never enters gameplay dispatch")

local originalAlias = Parser.Parse("Can you bring me some water?")
T.equal(originalAlias.action, "FETCH", "authored aliases remain registered")
T.equal(originalAlias.object.category, "WATER",
    "authored aliases keep existing object interpretation")

-- The worker and some tests load the catalog with dofile while its submodules
-- use require. A reload must still validate the registry state, not one
-- module-load closure's bookkeeping.
Catalog = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticCatalog.lua"
)
T.equal(Catalog.registered, true, "catalog reload keeps generated aliases valid")
T.equal(Parser.Parse("Retrieve me some water.").action, "FETCH",
    "generated alias survives a catalog reload")

local gotMatches = Semantic.Registry.GetAliasMatches("got")
T.equal(#gotMatches, 1, "ambiguous got form is not imported for FETCH")
T.equal(gotMatches[1].id, "HAVE", "authored got meaning remains HAVE")
T.equal(Catalog.ResolveVerbForm("got"), nil,
    "the ambiguous got form is not assigned WordNet morphology")
for _, alias in ipairs(GeneratedLexicon.aliasesByConcept.FETCH) do
    local matches = Semantic.Registry.GetAliasMatches(alias)
    T.truthy(#matches > 0, "generated alias is present in the existing registry")
    for _, match in ipairs(matches) do
        T.equal(match.id, "FETCH", "generated aliases do not collide with other concepts")
    end
end
for _, alias in ipairs(GeneratedLexicon.aliasesByConcept.FOLLOW) do
    local matches = Semantic.Registry.GetAliasMatches(alias)
    T.truthy(#matches > 0, "generated FOLLOW lemma is present in the registry")
    for _, match in ipairs(matches) do
        T.equal(match.id, "FOLLOW", "generated FOLLOW lemma keeps its concept")
    end
end

local index = EntityResolver.BuildIndex({
    {
        id = "npc:sarah",
        entityType = "npc",
        name = "Sarah Connor",
        aliases = { "Sarah" },
    },
})
local router = Semantic.DialogueRouter.New({
    stateSpec = { maxEvents = 4 },
    parser = Parser.Parse,
    contextResolver = ReferenceResolver.Resolve,
    policy = Policy,
    context = {
        llmEnabled = false,
        semanticEntityIndex = index,
    },
})
local routed = router:Preview("Retrieve some water to Sarah.", nil,
    { timestamp = 100 })
T.equal(routed.ir.action, "FETCH", "new alias uses the existing dialogue router")
T.equal(routed.ir.object.category, "WATER",
    "new alias preserves the existing object role")
T.equal(routed.ir.target.id, "npc:sarah",
    "existing entity resolution still binds the target")
T.equal(routed.ir.target.unresolved, false,
    "known target remains resolved")

local unsupportedFrom = Parser.Parse("Take the rifle from the locker.")
T.equal(unsupportedFrom.source, nil,
    "lexical expansion does not invent a general FROM relation")
T.truthy(Catalog.registered, "generated and authored concepts register together")

T.finish("pnc_semantic_generated_lexicon_smoke")
