local Provider = {}

function Provider.install(SemanticAdapters)
    function SemanticAdapters.identityName(context, npc)
        local safeString = context.Values.safeString
        local first = safeString(npc and npc.forename)
        local last = safeString(npc and npc.surname)
        if first ~= "" and last ~= "" then return first .. " " .. last end
        return first ~= "" and first or last
    end

    function SemanticAdapters.playerName(context, player)
        local safeString = context.Values.safeString
        local first = safeString(player and player.forename)
        local last = safeString(player and player.surname)
        if first ~= "" and last ~= "" then return first .. " " .. last end
        return first ~= "" and first or last
    end

    function SemanticAdapters.relationshipFor(context, npcID)
        local Runtime = context.Runtime
        local scenario = Runtime.scenario or {}
        local npc = scenario.npc or {}
        local relationship = npc.relationship or {}
        Runtime.relationships = Runtime.relationships or {}
        Runtime.relationships[npcID] = Runtime.relationships[npcID]
            or context.Values.copy(relationship)
        return Runtime.relationships[npcID]
    end

    function SemanticAdapters.relationshipSnapshotFor(context, npcID)
        return context.Values.copy(
            SemanticAdapters.relationshipFor(context, npcID)
        )
    end
end

return Provider
