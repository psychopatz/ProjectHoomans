-- Explicit registration manifest for the metadata-driven G0A generator.
return {
    schema = "pnc.automatic_flow_manifest.v1",
    owner = "ProjectHoomans",
    workflowKind = "simple_command",
    templateVersion = 1,
    generator = "PNC/Semantics/PNC_SemanticAutomaticFlowGenerator",
    generatedDefinitions = "PNC/Semantics/PNC_SemanticGeneratedAutomaticFlows",
    translationPaths = {
        EN = "EN/Conversation/Semantic/Generated.json",
        TL = "TL/Conversation/Semantic/Generated.json",
    },
}
