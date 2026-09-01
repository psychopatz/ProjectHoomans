-- Client map provider for selecting a lumber work region on the world map.
PNC = PNC or {}

local Commands = PNC.MapCommands

Commands.RegisterProvider("lumber_zone", {
    order = 20,
    region = true,
    label = "Select lumber work region",
    canExecute = function(selection, target)
        if #selection <= 0 then return false, "no NPC selected" end
        if not target or target.x == nil or target.y == nil then
            return false, "invalid map target"
        end
        return true
    end,
    execute = function(_, target, map, provider)
        return Commands.BeginRegionSelection(provider, target, map)
    end,
    executeRegion = function(_, target, _, region)
        return Commands.Dispatch("lumber_zone", target, {
            region = region,
        })
    end,
})

return Commands
