local Callbacks = {}
local Policy = require
    "PNC/UI/Base/PNC_BaseBuildingPlacementPolicy"
local BuildAudit = require "PNC/Core/Diagnostics/PNC_BuildAudit"

function Callbacks.Attach(cursor, Placement, deps, window, recipe)
    cursor.onPlacement = function(target)
        local valid, reason, normalized, invalid, conflictingOrder =
            Policy.ValidateCurrentFootprint(cursor.pncFootprint)
        cursor.pncFootprint = normalized or cursor.pncFootprint
        cursor.pncInvalidFootprint = invalid
        cursor.pncCollisionOrder = conflictingOrder
        cursor.pncPlacementError = reason
        if not valid then
            -- The placement clicked into an area the server would reject. Tell
            -- the player now instead of only rendering the cursor tooltip.
            local Shared = require "PNC/UI/Shared/PNC_ColonyUIShared"
            if BuildAudit.Enabled() then
                BuildAudit.Log("placement_rejected", {
                    "object=" .. tostring(cursor.objectInfoName),
                    "reason=" .. tostring(reason),
                })
            end
            BuildAudit.TracePlacement("pnc_build_placement_rejected",
                { "object=" .. tostring(cursor.objectInfoName),
                    "reason=" .. tostring(reason) })
            Shared.NotifyBuildFailure(reason)
            deps.fail(reason)
            cursor.canBeBuild = false
            return false
        end
        local options = {
            recipeKey = cursor.recipeKey,
            objectInfoName = cursor.objectInfoName,
            x = target.x, y = target.y, z = target.z,
            north = target.north, nSprite = target.nSprite,
            sprite = target.sprite,
        }
        if recipe.facilityDefinitionId then
            options.facilityDefinitionId = recipe.facilityDefinitionId
            options.facilityBaseId = recipe.facilityBaseId
            options.facilityExpectedRevision =
                recipe.facilityExpectedRevision
        end
        local traceId = "build?"
        if BuildAudit.Enabled() then
            traceId = BuildAudit.TraceId()
            options.requestId = traceId
            BuildAudit.Log("placement_confirm", {
                BuildAudit.RequestField(traceId),
                "object=" .. tostring(cursor.objectInfoName),
                "facility=" .. tostring(options.facilityDefinitionId),
                "x=" .. tostring(options.x),
                "y=" .. tostring(options.y),
                "z=" .. tostring(options.z),
            })
        end
        local sent, sendReason = PNC.Client.RequestColonyAction(
            "building_queue", options)
        if sent == false then
            -- The order never left the client. Keep the cursor alive so the
            -- player can retry instead of losing the placement silently.
            if BuildAudit.Enabled() then
                BuildAudit.Log("request_blocked", {
                    BuildAudit.RequestField(traceId),
                    "action=building_queue",
                    "reason=" .. tostring(sendReason),
                })
            end
            deps.fail(sendReason or "BUILD_QUEUE_FAILED")
            cursor.canBeBuild = false
            return false
        end
        Placement.HideTooltip(cursor)
        if Placement.activeCursor == cursor then Placement.activeCursor = nil end
        if window then window.buildPlacement = nil end
        deps.closeFacilityPlacementUI(cursor)
        deps.restoreOwnerAfterPlacing(window)
    end
    cursor.onCancel = function()
        if BuildAudit.Enabled() then
            BuildAudit.Log("placement_native_cancel", {
                "object=" .. tostring(cursor.objectInfoName),
            })
        end
        Placement.HideTooltip(cursor)
        if Placement.activeCursor == cursor then Placement.activeCursor = nil end
        if window then window.buildPlacement = nil end
        deps.closeFacilityPlacementUI(cursor)
        deps.restoreOwnerAfterPlacing(window)
    end
    return cursor
end

return Callbacks
