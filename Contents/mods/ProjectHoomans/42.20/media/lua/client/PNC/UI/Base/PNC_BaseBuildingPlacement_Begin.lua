local Begin = {}
local Cursor = require
    "PNC/UI/Base/PNC_BaseBuildingPlacement_Cursor"
local Callbacks = require
    "PNC/UI/Base/PNC_BaseBuildingPlacement_BeginCallbacks"
local BuildAudit = require "PNC/Core/Diagnostics/PNC_BuildAudit"

function Begin.Start(Placement, deps, window, recipe)
    local class = Cursor.Create(Placement, deps.setBoundaryValidity,
        deps.setEngineInvalid)
    if not window or not recipe or not class then
        return deps.fail("PLACEMENT_UNAVAILABLE")
    end
    local character = deps.currentPlayer()
    if not character then return deps.fail("PLAYER_UNAVAILABLE") end
    -- A second click on the same BUILD/PLACE action used to cancel the live
    -- cursor and its overlay and then rebuild both, which reads as the overlay
    -- flashing away. The cursor is already in the requested state, so keep it.
    local existing = window.buildPlacement
    if existing and existing.pncPlacement == true
        and tostring(existing.pncFacilityDefinitionId or "")
            == tostring(recipe.facilityDefinitionId or "")
        and tostring(existing.objectInfoName or "")
            == tostring(recipe.objectInfoName or "")
    then
        BuildAudit.TracePlacement("pnc_build_placement_kept",
            { "object=" .. tostring(recipe.objectInfoName) })
        if BuildAudit.Enabled() then
            BuildAudit.Log("placement_kept", {
                "object=" .. tostring(recipe.objectInfoName),
                "facility=" .. tostring(recipe.facilityDefinitionId),
            })
        end
        return true
    end
    -- Cancelling here is what makes a repeated BUILD click flash the overlay:
    -- the old cursor is torn down before the new one exists. The reason tag
    -- separates this from a real user/tab cancel in the trace.
    Placement.Cancel(window, "placement_restart")

    local descriptor = PNC.BuildRecipeCatalog
        and PNC.BuildRecipeCatalog.Get(recipe.objectInfoName)
    local info = descriptor and descriptor.nativeObjectInfo or nil
    if not info and SpriteConfigManager
        and SpriteConfigManager.GetObjectInfo
    then
        info = SpriteConfigManager.GetObjectInfo(recipe.objectInfoName)
    end
    if not info then return deps.fail("BUILD_RECIPE_NOT_FOUND") end

    -- ISBuildIsoEntity creates a BaseCraftingLogic when no logic is passed.
    -- That constructor calls setContainers, so the native cursor must receive
    -- the same container list as the vanilla build menu. Passing nil here
    -- causes a Java-side NPE before the placement cursor can be shown.
    local containers
    if not ISInventoryPaneContextMenu then
        -- This module is supplied by the vanilla client, but the fallback
        -- cursor also runs in headless/test contexts where it is absent.
        pcall(require, "ISUI/ISInventoryPaneContextMenu")
    end
    if ISInventoryPaneContextMenu
        and type(ISInventoryPaneContextMenu.getContainers) == "function"
    then
        containers = ISInventoryPaneContextMenu.getContainers(character)
    end
    local cursor = class.new(class, character, info, 1, containers, nil)
    if not cursor then return deps.fail("PLACEMENT_CURSOR_FAILED") end
    cursor.pncPlacement = true
    cursor.player = character:getPlayerNum()
    cursor.character = character
    cursor.recipeKey = recipe.recipeKey
    cursor.objectInfoName = recipe.objectInfoName
    cursor.pncFacilityDefinitionId = recipe.facilityDefinitionId
    cursor.haveMaterial = function() return true end
    cursor.skipBuildAction = true
    cursor.dragNilAfterPlace = true
    cursor.pncFacilityPlacement = recipe.facilityDefinitionId ~= nil
    Callbacks.Attach(cursor, Placement, deps, window, recipe)


    local cell = getCell and getCell() or nil
    if not cell or type(cell.setDrag) ~= "function" then
        return deps.fail("PLACEMENT_CELL_UNAVAILABLE")
    end
    window.buildPlacement = cursor
    Placement.activeCursor = cursor
    cell:setDrag(cursor, cursor.player)
    BuildAudit.TracePlacement("pnc_build_placement_open", {
        "object=" .. tostring(cursor.objectInfoName),
        "facility=" .. tostring(recipe.facilityDefinitionId),
        "facility_ui=" .. tostring(cursor.pncFacilityPlacement == true),
    })
    if BuildAudit.Enabled() then
        BuildAudit.Log("placement_open", {
            "object=" .. tostring(cursor.objectInfoName),
            "facility=" .. tostring(recipe.facilityDefinitionId),
            "facility_ui=" .. tostring(cursor.pncFacilityPlacement == true),
        })
    end
    if cursor.pncFacilityPlacement then
        local placementUI = require
            "PNC/UI/Base/PNC_BaseBuildingPlacementModal"
        if placementUI and placementUI.Open then
            placementUI.Open({
                onBack = function()
                    Placement.Cancel(window, "placement_ui_back")
                    local buildUI = PNC and PNC.FacilityBuildUI or nil
                    if buildUI and buildUI.Reopen then
                        buildUI.Reopen()
                    end
                end,
            })
        end
    end
    -- Get the base window out of the way so the player can actually see the
    -- world while placing. It comes back on every teardown path.
    deps.hideOwnerWhilePlacing(window)
    Placement.lastError = nil
    return true
end


return Begin
