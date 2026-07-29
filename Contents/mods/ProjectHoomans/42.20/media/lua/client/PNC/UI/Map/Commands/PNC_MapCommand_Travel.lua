-- Debug/test provider for issuing durable movement journeys from the map.

PNC = PNC or {}

local Commands = PNC.MapCommands

Commands.RegisterProvider("travel", {
    order = 10,
    label = function(selection)
        if #selection == 1 then
            return "Move " .. tostring(selection[1].name) .. " here"
        end
        return "Move " .. tostring(#selection) .. " NPCs here"
    end,
    canExecute = function(selection, target)
        if not PNC.Client or not PNC.Client.CanUseDebug
            or not PNC.Client.CanUseDebug()
        then
            return false, "debug access required"
        end
        if #selection <= 0 then return false, "no NPC selected" end
        if not target or target.x == nil or target.y == nil then
            return false, "invalid destination"
        end
        return true
    end,
    execute = function(_, target)
        Commands.LastTarget = {
            x = target.x,
            y = target.y,
            z = target.z or 0,
        }
        return Commands.Dispatch("travel", target, {
            speedProfile = "walk",
            routeProvider = "direct",
            ownerRef = "debug_map_command",
        })
    end,
})

return Commands
