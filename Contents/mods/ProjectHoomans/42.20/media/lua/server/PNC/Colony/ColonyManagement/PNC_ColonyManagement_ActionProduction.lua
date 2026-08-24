if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ColonyManagement = PNC.ColonyManagement or {}
PNC.ColonyManagement.Internal = PNC.ColonyManagement.Internal or {}

local Management = PNC.ColonyManagement
local Internal = Management.Internal
local Definitions = PNC.NeedsDefinitions


local canUseDebug = Internal.canUseDebug

function Internal.handleProductionAction(player, args, action)
    local ok
    local reason
    local details
    if action == "research_queue_technology" then
        details, reason = PNC.ResearchService.Commands.QueueTechnology(
            player, tostring(args.technologyId or ""))
        ok = details ~= nil
    elseif action == "research_study_blueprint" then
        details, reason = PNC.ResearchService.Commands.StudyBlueprint(
            player, args.recordIndex)
        ok = details ~= nil
    elseif action == "research_reverse_engineer" then
        details, reason = PNC.ResearchService.Commands.ReverseEngineer(
            player, args.recordIndex)
        ok = details ~= nil
    elseif action == "blueprint_debug_create" then
        if canUseDebug(player) then
            ok, reason = PNC.ResearchService.Commands.CreateBlueprint(
                player, tostring(args.recipeKey or ""))
        else
            ok, reason = false, "not_authorized"
        end
    elseif action == "production_debug_spear_kit" then
        if canUseDebug(player) then
            ok, details =
                PNC.ResearchService.Commands.CreateSpearTestKit(player)
            reason = ok and "SPEAR_TEST_KIT_CREATED" or details
        else
            ok, reason = false, "not_authorized"
        end
    elseif action == "craft_queue" then
        details, reason = PNC.CraftingService.Commands.QueueCraft(
            player, args.recipeId, args.quantity)
        ok = details ~= nil
    elseif action == "disassemble_queue" then
        details, reason = PNC.CraftingService.Commands.QueueDisassembly(
            player, args.recordIndex)
        ok = details ~= nil
    elseif action == "building_queue" then
        details, reason = PNC.BuildingService.Queue(player, args)
        ok = details ~= nil
    elseif action == "building_debug_get_items" then
        details, reason = PNC.BuildingService.DebugGrantMaterials(player, args)
        ok = details ~= nil
    else
        return nil
    end
    return { ok = ok, reason = reason, details = details }
end

return Management
