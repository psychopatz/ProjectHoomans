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
        local Values = context.Values
        local scenario = Runtime.scenario or {}
        local npc = scenario.npc or {}
        local relationship = npc.relationship or {}
        Runtime.relationships = Runtime.relationships or {}
        if not Runtime.relationships[npcID] then
            -- Identity is a read-only seam.  Relationship standing, durable
            -- bonds, memories, and events belong to the production
            -- RelationshipService; developer fixtures may opt into their
            -- explicit compatibility provider in SemanticAdapters_Core.
            Runtime.relationships[npcID] = Values.copy(relationship)
        end
        return Runtime.relationships[npcID]
    end

    function SemanticAdapters.relationshipSnapshotFor(context, npcID)
        return context.Values.copy(
            SemanticAdapters.relationshipFor(context, npcID)
        )
    end
    SemanticAdapters.identityRelationshipFor = SemanticAdapters.relationshipFor
    SemanticAdapters.identityRelationshipSnapshotFor =
        SemanticAdapters.relationshipSnapshotFor
end

return Provider
