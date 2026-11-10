-- Ordered world-knowledge, social-authority, and recruitment composition.

local function loadWorldAuthority(load)
    -- Keep the production NPC Knowledge service on the worker boundary.
    -- The adapter later fills these same tables with scenario-owned identity
    -- and registry methods; the service never receives a second store.
    PNC = PNC or {}
    PNC.Registry = PNC.Registry or {}
    PNC.PlayerCharacters = PNC.PlayerCharacters or {}
    PNC.PlayerContext = PNC.PlayerContext or {}
    -- World Knowledge is loaded through the same production module loader so
    -- worker scenarios exercise the portable Core ledger and Hoomans owner
    -- adapter, rather than a JSON-only substitute.
    load(
        "PsychopatzCore", "common",
        "PsychopatzCore/WorldKnowledge/PsychopatzWorldFact.lua",
        "world_knowledge"
    )
    load(
        "PsychopatzCore", "common",
        "PsychopatzCore/WorldKnowledge/PsychopatzWorldFactLedger.lua",
        "world_knowledge"
    )
    load(
        "PsychopatzCore", "common",
        "PsychopatzCore/WorldKnowledge/PsychopatzActorWorldKnowledge.lua",
        "world_knowledge"
    )
    load(
        "PsychopatzCore", "common",
        "PsychopatzCore/WorldKnowledge/PsychopatzWorldKnowledge.lua",
        "world_knowledge"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/WorldKnowledge/PNC_WorldKnowledge.lua",
        "world_knowledge"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/WorldKnowledge/PNC_WorldKnowledge_PZ.lua",
        "world_knowledge"
    )
    PNC.Relationships = PNC.Relationships or {}
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Compatibility/PNC_Compatibility_API.lua",
        "compatibility"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Knowledge/PNC_KnowledgeRegistry.lua",
        "knowledge_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Knowledge/PNC_KnowledgeBuiltins.lua",
        "knowledge_authority"
    )
    load(
        "ProjectHoomans", "server",
        "PNC/Knowledge/PNC_NPCKnowledgeService.lua",
        "knowledge_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Relationships/PNC_SocialProfileConstants.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Relationships/PNC_SocialProfileGenerator.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Relationships/PNC_SocialProfileTypes.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Relationships/PNC_SocialTraits.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Relationships/PNC_SocialProfileMath.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Relationships/PNC_SocialEventDefinitions.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "shared",
    "PNC/Core/Relationships/PNC_RelationshipConstants.lua",
    "social_authority"
)
load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Relationships/PNC_RelationshipProposalPolicy.lua",
    "social_authority"
)
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Relationships/PNC_RelationshipKindRegistry.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Relationships/PNC_RelationshipStates.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Relationships/PNC_RelationshipTypes.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Relationships/PNC_RelationshipMath.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Conduct/PNC_ConductConstants.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Conduct/PNC_ConductTypes.lua",
        "social_authority"
    )
    -- SAVE-backed identity rehydration uses the production player registry.
    -- Load its complete owner before the social services capture their
    -- PlayerCharacters reference; the worker supplies only isolated ModData.
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Identity/PNC_PlayerCharacterConstants.lua",
        "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Identity/PNC_PlayerCharacterTypes.lua",
        "persistence"
    )
    load(
        "ProjectHoomans", "server",
        "PNC/Player/PNC_PlayerCharacterService.lua",
        "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Conduct/PNC_ConductMath.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Conduct/PNC_ConductDefinitions.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "server",
        "PNC/Social/PNC_ConductService.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "server",
        "PNC/Social/PNC_SocialProfileService.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "server",
        "PNC/Social/PNC_RelationshipService.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "server",
        "PNC/Social/PNC_SocialEventService.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "server",
        "PNC/Networking/Handlers/PNC_ServerSemanticSocialInteractionCommandHandler.lua",
        "social_authority"
    )
    -- Recruitment is a server-owned conversation effect. Keep the worker's
    -- dual-role authority composition aligned with the native server root so a
    -- recruit choice receives the same evaluation, persistence, and result path.
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Relationships/PNC_RelationshipGraph.lua",
        "recruitment_authority"
    )
load(
    "ProjectHoomans", "shared",
    "PNC/Core/Relationships/PNC_RelationshipPresentation.lua",
    "social_authority"
)
-- Reuse the production relationship-debug snapshot owner for the headless
-- inspector. It projects persisted memories, saturation, cooldowns, and the
-- directed relationship state without creating a harness social model.
load(
    "ProjectHoomans", "server",
    "PNC/Social/PNC_RelationshipDebug.lua",
    "diagnostics"
)
load(
        "ProjectHoomans", "shared",
        "PNC/Core/Factions/PNC_FactionConstants.lua",
        "recruitment_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Factions/PNC_FactionBalance.lua",
        "recruitment_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Factions/PNC_FactionArchetypes.lua",
        "recruitment_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Factions/PNC_FactionNameGenerator.lua",
        "recruitment_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Factions/PNC_FactionEmblems.lua",
        "recruitment_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Factions/PNC_FactionDiplomacyMath.lua",
        "recruitment_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Factions/PNC_FactionIncidentDefinitions.lua",
        "recruitment_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Factions/PNC_FactionIntent.lua",
        "recruitment_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Factions/PNC_FactionTypes.lua",
        "recruitment_authority"
    )
    load(
        "ProjectHoomans", "server",
        "PNC/Factions/PNC_FactionCore.lua",
        "recruitment_authority"
    )
    -- The native conversation departure authority delegates its gameplay
    -- mutation to this existing server service. Keep the worker on that same
    -- executor so Leave Group acceptance can prove the warning/confirm path
    -- and the real ownership/faction mutation rather than a mock response.
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Relationships/PNC_ColonistDeparturePolicy.lua",
        "departure_authority"
    )
    load(
        "ProjectHoomans", "server",
        "PNC/Colonists/PNC_ColonistDepartureService.lua",
        "departure_authority"
    )
    -- CommunityService is a native server dependency of recruitment.  Load
    -- the same shared value objects that the native shared composition loads
    -- before entering the service, so the worker does not create a weaker
    -- recruitment path just because it is headless.
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Communities/PNC_CommunityConstants.lua",
        "recruitment_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Communities/PNC_CommunityProfiles.lua",
        "recruitment_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Communities/PNC_CommunityMath.lua",
        "recruitment_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Communities/PNC_CommunityTypes.lua",
        "recruitment_authority"
    )
    -- Recruitment assignment is a production faction/community transaction.
    -- Keep the worker composition aligned with the native server root so a
    -- successful high-relationship proposal can complete the same ownership
    -- path instead of stopping at communities_unavailable.
    load(
        "ProjectHoomans", "server",
        "PNC/Communities/PNC_CommunityService.lua",
        "recruitment_authority"
    )
    load(
        "ProjectHoomans", "server",
        "PNC/Companions/PNC_DebugCompanionRecruit.lua",
        "recruitment_authority"
    )
end

return loadWorldAuthority
