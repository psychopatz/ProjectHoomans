-- Client map provider for creating a fishing zone around the clicked tile.

PNC = PNC or {}

local Commands = PNC.MapCommands
local Const = PNC.Const or {}

local function tr(key)
    return getText and getText(key) or key
end

Commands.RegisterProvider("fishing_zone", {
    order = 21,
    label = function()
        return tr("UI_PNC_MapCommand_FishingZone") .. " ("
            .. tostring(Const.FISHING_ZONE_RADIUS or 12) .. ")"
    end,
    canExecute = function(selection, target)
        if #selection <= 0 then return false, "no NPC selected" end
        if not target or target.x == nil or target.y == nil then
            return false, "invalid zone center"
        end
        return true
    end,
    execute = function(_, target)
        Commands.LastTarget = {
            x = target.x, y = target.y, z = target.z or 0,
        }
        return Commands.Dispatch("fishing_zone", target, {
            radius = Const.FISHING_ZONE_RADIUS or 12,
        })
    end,
})

return Commands
