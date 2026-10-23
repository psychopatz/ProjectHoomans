-- Explicit synthetic-scenario compatibility policy.
--
-- This provider is never used for SAVE source snapshots.  It preserves the
-- deterministic historical fixture contract while normal save-backed worlds
-- query and mutate the production RelationshipService.

local Provider = {}

function Provider.install(SemanticAdapters)
    function SemanticAdapters.developerTestRelationshipFor(context, npcID)
        local Runtime = context.Runtime
        local Values = context.Values
        local scenario = Runtime.scenario or {}
        local npc = scenario.npc or {}
        local relationship = npc.relationship or {}
        Runtime.relationships = Runtime.relationships or {}
        if not Runtime.relationships[npcID] then
            local resolved = Values.copy(relationship)
            local current = resolved.state or resolved.relationshipState
            local states = PNC.RelationshipStates
            if states and type(states.ResolveState) == "function" then
                local state = states.ResolveState({
                    approval = resolved.approval,
                    respect = resolved.respect,
                    familiarity = resolved.familiarity,
                    state = current,
                })
                resolved.state = state
                resolved.relationshipState = state
            end
            local starting = npc.startingRelationship
            local startingKind = type(starting) == "table"
                and tostring(starting.kind or "") or ""
            local bond = type(resolved.bond) == "table"
                and resolved.bond or { class = "none" }
            if bond.class == "none" and startingKind ~= "" then
                local family = {
                    mother = true, father = true,
                    sister = true, brother = true,
                }
                local class = family[startingKind] and "family"
                    or startingKind == "lover" and "lover"
                    or startingKind == "friend" and "friend" or nil
                if class then
                    resolved.bond = {
                        schemaVersion = 1,
                        class = class,
                        kind = class == "family" and startingKind or nil,
                        establishedAt = tonumber(Runtime.now) or 0,
                        source = "starting_companion",
                    }
                end
            end
            local resolvedBond = type(resolved.bond) == "table"
                and resolved.bond or { class = "none" }
            if resolvedBond.class == "none"
                and (tonumber(resolved.approval) or 0) >= 80
                and (tonumber(resolved.respect) or 0) >= 50
                and (tonumber(resolved.familiarity) or 0) >= 60
                and resolved.state ~= "rival"
                and resolved.state ~= "enemy"
            then
                resolved.bond = {
                    schemaVersion = 1,
                    class = "friend",
                    kind = nil,
                    establishedAt = tonumber(Runtime.now) or 0,
                    source = "relationship_milestone",
                }
                resolved.revision = (tonumber(resolved.revision) or 0) + 1
                Runtime.socialEvents = Runtime.socialEvents or {}
                Runtime.socialEvents[#Runtime.socialEvents + 1] = {
                    type = "friendship_established",
                    eventID = "social:friendship_established:"
                        .. tostring(npcID),
                    at = tonumber(Runtime.now) or 0,
                }
                while #Runtime.socialEvents > 20 do
                    table.remove(Runtime.socialEvents, 1)
                end
            end
            if resolved.bond then
                npc.relationship = npc.relationship or {}
                npc.relationship.bond = Values.copy(resolved.bond)
            end
            Runtime.relationships[npcID] = resolved
        end
        return Runtime.relationships[npcID]
    end
end

return Provider
