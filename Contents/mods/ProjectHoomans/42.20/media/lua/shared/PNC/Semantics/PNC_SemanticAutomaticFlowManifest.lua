-- Explicit registration manifest for the metadata-driven G0A generator.
return {
    schema = "pnc.automatic_flow_manifest.v1",
    owner = "ProjectHoomans",
    workflowKind = "automatic",
    templateVersion = 1,
    templates = {
        simple_command = 1,
        parameterized_task = 1,
        multi_stage_gift = 1,
    },
    generator = "PNC/Semantics/PNC_SemanticAutomaticFlowGenerator",
    generatedDefinitions = "PNC/Semantics/PNC_SemanticGeneratedAutomaticFlows",
    translationPaths = {
        EN = {
            "EN/Conversation/Semantic/DialogueContent.json",
        },
        TL = {
            "TL/Conversation/Semantic/DialogueContent.json",
        },
    },
}
