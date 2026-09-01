-- Client map provider for creating a lumber zone around the clicked tile.
PNC = PNC or {}

local Commands = PNC.MapCommands
local Const = PNC.Const or {}

Commands.RegisterProvider("lumber_zone", {
    order = 20,
    label = function()
        return "Assign lumber zone ("
            .. tostring(Const.LUMBER_DEFAULT_RADIUS or 12)
            .. " tiles)"
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
        return Commands.Dispatch("lumber_zone", target, {
            radius = Const.LUMBER_DEFAULT_RADIUS or 12,
        })
    end,
})

return Commands
