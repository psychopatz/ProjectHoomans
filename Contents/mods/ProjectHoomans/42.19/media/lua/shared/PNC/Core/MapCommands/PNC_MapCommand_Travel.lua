-- Default debug movement command implemented through the durable journey API.

PNC = PNC or {}

local Service = PNC.MapCommandService

Service.RegisterHandler("travel", {
    authorize = function(_, _, _, _, context)
        if context and context.debugAuthorized == true then
            return true
        end
        return false, "debug_unauthorized"
    end,
    execute = function(_, npcIds, target, options)
        local accepted = 0
        local rejected = 0
        local details = {}
        local i
        local id
        local record
        local journey
        local reason
        for i = 1, #npcIds do
            id = npcIds[i]
            record = PNC.Registry and PNC.Registry.Get
                and PNC.Registry.Get(id) or nil
            if record and record.alive ~= false then
                journey, reason = PNC.Travel.Service.Start(record, {
                    destination = target,
                    routeProvider = options.routeProvider or "direct",
                    speedProfile = options.speedProfile or "walk",
                    ownerMod = "ProjectHoomans",
                    ownerRef = options.ownerRef or "debug_map_command",
                    visibility = options.visibility or "all",
                    arrivalAction = options.arrivalAction
                        or options.onArrival,
                    metadata = {
                        source = "map_command",
                        commandID = "travel",
                    },
                })
            else
                journey = nil
                reason = "npc_missing"
            end
            if journey then
                accepted = accepted + 1
            else
                rejected = rejected + 1
                details[#details + 1] = {
                    npcId = id,
                    reason = tostring(reason or "rejected"),
                }
            end
        end
        return {
            ok = accepted > 0,
            accepted = accepted,
            rejected = rejected,
            reason = accepted > 0 and nil or "no_npcs_accepted",
            details = details,
        }
    end,
})

return Service
