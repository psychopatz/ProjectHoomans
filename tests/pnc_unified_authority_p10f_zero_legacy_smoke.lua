local T = require "tests/support/test"

T.addPackagePaths()

local function exists(path)
    local handle = io.open(path, "rb")
    if handle then
        handle:close()
        return true
    end
    return false
end

local deleted = {
    "client/PNC/Conversation/PNC_SocialFlavorDefinitions.lua",
    "client/PNC/Conversation/PNC_SocialFlavorDefinitions_Core.lua",
    "client/PNC/Conversation/PNC_SocialFlavorDefinitions_GroupA.lua",
    "client/PNC/Conversation/PNC_SocialFlavorDefinitions_GroupB.lua",
    "client/PNC/Conversation/PNC_SocialFlavorDefinitions_GroupC.lua",
    "client/PNC/Conversation/PNC_SocialFlavorDefinitions_Incapacitated.lua",
    "client/PNC/Conversation/PNC_SocialFlavorDefinitions_Incapacitated_Call.lua",
    "client/PNC/Conversation/PNC_SocialFlavorDefinitions_Incapacitated_Call_Ally.lua",
    "client/PNC/Conversation/PNC_SocialFlavorDefinitions_Incapacitated_Call_Hostile.lua",
    "client/PNC/Conversation/PNC_SocialFlavorDefinitions_Incapacitated_Call_Other.lua",
    "client/PNC/Conversation/PNC_SocialFlavorDefinitions_Incapacitated_Repeat.lua",
    "client/PNC/Conversation/PNC_SocialFlavorDefinitions_Incapacitated_Repeat_Lines.lua",
    "client/PNC/Conversation/PNC_SocialFlavorDefinitions_Incapacitated_Repeat_Lines_Ally.lua",
    "client/PNC/Conversation/PNC_SocialFlavorDefinitions_Incapacitated_Repeat_Lines_Hostile.lua",
    "client/PNC/Conversation/PNC_SocialFlavorDefinitions_Incapacitated_Repeat_Lines_Wider.lua",
    "client/PNC/Conversation/PNC_SocialFlavorDefinitions_Incapacitated_Shared.lua",
    "client/PNC/Conversation/PNC_SocialFlavorDefinitions_Incapacitated_Update.lua",
    "client/PNC/Conversation/PNC_SocialFlavorDefinitions_LeaderDeath.lua",
    "client/PNC/Conversation/PNC_SocialFlavorDefinitions_LeaderDeath_Close.lua",
    "client/PNC/Conversation/PNC_SocialFlavorDefinitions_LeaderDeath_Wider.lua",
    "client/PNC/Compatibility/Mods/Bandits/PNC_Bandits_HoomansFlavorDefinitions.lua",
    "client/PNC/Compatibility/Mods/Necroa/PNC_Necroa_HoomansFlavorDefinitions.lua",
    "client/PNC/Compatibility/Mods/ProjectALife/PNC_ProjectALife_FlavorDefinitions.lua",
    "shared/PNC/Conversation/PNC_ConversationToolReplyCatalog.lua",
    "shared/PNC/Core/Commands/PNC_CompanionCommandFlavor.lua",
    "shared/PNC/Core/Commands/PNC_CompanionCommandFlavorDefinitions.lua",
    "shared/PNC/Core/Commands/PNC_CompanionCommandFlavorDefinitions_Base.lua",
    "shared/PNC/Core/Commands/PNC_CompanionCommandFlavorDefinitions_Core.lua",
    "shared/PNC/Core/Commands/PNC_CompanionCommandFlavorDefinitions_TypedA.lua",
    "shared/PNC/Core/Commands/PNC_CompanionCommandFlavorDefinitions_TypedB.lua",
    "shared/PNC/Core/Social/PNC_FlavorTextResolver.lua",
    "shared/PNC/Core/Social/PNC_FlavorTextResolver_Constants.lua",
    "shared/PNC/Core/Identity/PNC_FlavorAddress.lua",
    "client/PNC/Conversation/PNC_SocialFlavorPresentation.lua",
}

for _, relative in ipairs(deleted) do
    T.falsy(
        exists(T.path("ProjectHoomans", "42.20", "media/lua/" .. relative)),
        "retired first-party legacy file remains: " .. relative
    )
end

local oldTranslation = {
    "EN/Conversation/Flavor/Combat.json",
    "EN/Conversation/Flavor/Incapacitated.json",
    "EN/Conversation/Flavor/Social.json",
    "EN/Conversation/ToolReplies/Commands.json",
    "TL/Conversation/Flavor/Combat.json",
    "TL/Conversation/Flavor/Incapacitated.json",
    "TL/Conversation/Flavor/Social.json",
    "TL/Conversation/ToolReplies/Commands.json",
}
for _, relative in ipairs(oldTranslation) do
    T.falsy(
        exists(T.path("ProjectHoomans", "common/media/translation/" .. relative)),
        "retired first-party translation file remains: " .. relative
    )
end

local sourcePath = T.repository
    .. "/tools/semantic_harness/codebuilder/sources/"
    .. "semantic_dialogue_content.json"
local handle = assert(io.open(sourcePath, "rb"))
local source = handle:read("*a")
handle:close()

for _, marker in ipairs({
    ".migrated.",
    "MIGRATED_",
    "legacySource",
    "migrated_events",
    "semanticAuthority",
    "responsePoolID",
    "semanticVariantID",
}) do
    T.falsy(
        source:find(marker, 1, true),
        "canonical Dialogue Content retains migration marker: " .. marker
    )
end

local catalogs = {
    "ProjectHoomans/42.20/media/lua/shared/PNC/Semantics/"
        .. "SemanticDialogueResponseCatalog/PNC_SemanticDialogueResponseCatalog_"
        .. "CompanionCommands.lua",
    "ProjectHoomans/42.20/media/lua/shared/PNC/Semantics/"
        .. "SemanticDialogueResponseCatalog/PNC_SemanticDialogueResponseCatalog_"
        .. "ToolReplies.lua",
    "ProjectHoomans/42.20/media/lua/shared/PNC/Semantics/"
        .. "SemanticDialogueResponseCatalog/PNC_SemanticDialogueResponseCatalog_"
        .. "Compatibility.lua",
}
for _, relative in ipairs(catalogs) do
    local catalogHandle = assert(io.open(
        T.repository .. "/Contents/mods/ProjectHoomans/42.20/media/lua/"
            .. relative:gsub("^ProjectHoomans/42%.20/media/lua/", ""),
        "rb"
    ))
    local catalog = catalogHandle:read("*a")
    catalogHandle:close()
    for _, marker in ipairs({
        "fallback =",
        'kind = "literal"',
        "compatibilityFlavorID",
        "Flavor.Resolve",
    }) do
        T.falsy(
            catalog:find(marker, 1, true),
            relative .. " retains first-party wording/legacy marker: " .. marker
        )
    end
end

T.finish("pnc_unified_authority_p10f_zero_legacy_smoke")

