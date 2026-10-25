-- Ordered production foundation and persistence composition.

local function loadCorePersistence(load)
    local Semantic = load(
        "PsychopatzCore", "common",
        "PsychopatzCore/Semantics/PsychopatzSemantic.lua", "semantic"
    )
    load("PsychopatzCore", "common", "PsychopatzCore/Translation/PsychopatzCustomTranslationManager.lua", "translation")
    load("PsychopatzCore", "common", "PsychopatzCore/Translation/PsychopatzCoreTranslation.lua", "translation")
    load("ProjectHoomans", "shared", "PNC/Core/Base/PNC_Constants.lua", "network")
    load("ProjectHoomans", "shared", "PNC/Core/Networking/PNC_Network.lua", "network")
    -- Persistence captures these owner tables when its submodules are
    -- loaded. Keep the worker composition order aligned with the native
    -- shared composition instead of allowing nil load-order seams.
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Base/PNC_Core.lua", "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Base/PNC_Types.lua", "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Identity/PNC_Identity.lua", "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Archetypes/Registry/PNC_Archetypes.lua",
        "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Identity/PNC_Identity_Profile.lua", "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Factions/PNC_FactionConstants.lua", "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Factions/PNC_FactionArchetypes.lua", "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Factions/PNC_FactionEmblems.lua", "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Factions/PNC_FactionDiplomacyMath.lua", "persistence"
    )
    -- FactionTypes captures EntityRef at module load time; load the real
    -- player/NPC key owner before its normalization functions are defined.
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Relationships/PNC_EntityRef.lua", "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Factions/PNC_FactionTypes.lua", "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Relationships/PNC_EntityRef.lua", "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Relationships/PNC_SocialProfileConstants.lua",
        "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Relationships/PNC_SocialProfileGenerator.lua",
        "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Relationships/PNC_SocialProfileTypes.lua",
        "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Conduct/PNC_ConductConstants.lua", "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Conduct/PNC_ConductTypes.lua", "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Relationships/PNC_RelationshipTypes.lua", "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Persistence/PNC_Persistence.lua", "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Quests/PNC_QuestDefinitions.lua", "quest_authority"
    )
    load(
        "ProjectHoomans", "server",
        "PNC/Networking/PNC_ServerCommandRouter.lua", "quest_authority"
    )
    load(
        "ProjectHoomans", "server",
        "PNC/Quests/PNC_QuestRepository.lua", "quest_authority"
    )
    load(
        "ProjectHoomans", "server",
        "PNC/Quests/PNC_QuestService.lua", "quest_authority"
    )
    load(
        "ProjectHoomans", "server",
        "PNC/Networking/Handlers/PNC_ServerSemanticQuestCommandHandler.lua",
        "quest_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Base/PNC_Core.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Relationships/PNC_EntityRef.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Identity/PNC_Identity.lua",
        "social_authority"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Traits/PNC_NPCTraitRegistry.lua",
        "persona_catalog"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Traits/PNC_NPCTraitDefinitions.lua",
        "persona_catalog"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Traits/PNC_NPCTraitEffects.lua",
        "persona_catalog"
    )
    -- SAVE rehydration uses the production inventory persistence facade and
    -- its deterministic baseline generator. Load the same narrow production
    -- dependencies before the worker's adapter installs any inventory seam.
    -- Archetype bootstrap is production-owned, but its native INFO logger
    -- writes stdout. The worker stdout is a JSON-lines transport, so contain
    -- that diagnostic only for this bootstrap window and restore the owner.
    local productionLogInfo = PNC.Core and PNC.Core.LogInfo
    if PNC.Core then PNC.Core.LogInfo = function() end end
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Archetypes/Registry/PNC_Archetypes.lua",
        "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Archetypes/Registry/PNC_ArchetypeLoader.lua",
        "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Equipment/PNC_Equipment_Items.lua",
        "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Equipment/PNC_Equipment_Slots.lua",
        "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Equipment/PNC_Equipment.lua",
        "persistence"
    )
    load(
        "ProjectHoomans", "shared",
        "PNC/Core/Inventory/PNC_Inventory.lua",
        "persistence"
    )
    if PNC.Core and type(productionLogInfo) == "function" then
        PNC.Core.LogInfo = productionLogInfo
    end
    return Semantic
end

return loadCorePersistence
