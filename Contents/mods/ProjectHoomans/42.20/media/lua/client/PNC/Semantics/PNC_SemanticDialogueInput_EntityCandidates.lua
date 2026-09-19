-- Build a bounded, identity-checked candidate list for semantic resolution.
local EntityCandidates = {}

local function addCandidate(candidates, seen, candidate)
    if type(candidate) ~= "table" then return end
    local id = candidate.id or candidate.entityID or candidate.npcID
        or candidate.uuid
    id = tostring(id or "")
    if id == "" or seen[id] then return end
    seen[id] = true
    candidates[#candidates + 1] = candidate
end

function EntityCandidates.Build(view, source)
    local candidates = {}
    local seen = {}
    local explicit = source and (
        source.semanticEntityCandidates or source.semanticEntities
    ) or nil
    if type(explicit) == "table" then
        for index = 1, #explicit do
            addCandidate(candidates, seen, explicit[index])
        end
    end

    local npcID = view and view.spec and view.spec.npcID
        or source and source.npcID
    if source and source.identityState == "known" and npcID then
        addCandidate(candidates, seen, {
            id = npcID,
            entityType = "npc",
            name = source.npcFullName or source.npcName,
            aliases = {
                source.npcName,
                source.npcFirstName,
                source.npcFullName,
            },
            source = "conversation_npc",
        })
    end

    local playerID = view and view.session and view.session.characterUUID
        or source and source.characterUUID
    if source and source.playerNameKnown == true and playerID
        and tostring(playerID) ~= ""
        and tostring(playerID) ~= "unbound"
    then
        addCandidate(candidates, seen, {
            id = "player:" .. tostring(playerID),
            entityType = "player",
            name = source.playerFullName or source.playerName,
            aliases = {
                source.playerName,
                source.playerFirstName,
                source.playerFullName,
            },
            source = "conversation_player",
        })
    end

    -- Snapshots are ambient candidates only after the identity gateway
    -- confirms that their name is known to this conversation.
    local clientState = PNC.Network and PNC.Network.ClientState or nil
    local snapshots = clientState and clientState.snapshots or nil
    local presentations = clientState and clientState.npcPresentations or nil
    local identity = PNC.NPCIdentityPresentation
    local snapshotCount = 0
    if type(snapshots) == "table" then
        for id, snapshot in pairs(snapshots) do
            if snapshotCount < 64 and type(snapshot) == "table" then
                local presentation = presentations and presentations[id] or nil
                local known = presentation
                    and presentation.state == "known"
                local name = presentation and presentation.displayName
                    or snapshot.displayName or snapshot.name
                if not known and identity
                    and type(identity.IsNameKnown) == "function"
                then
                    local ok, result = pcall(identity.IsNameKnown, snapshot)
                    known = ok and result == true
                end
                if known and identity
                    and type(identity.GetName) == "function"
                then
                    local ok, result = pcall(identity.GetName, snapshot)
                    if ok and result then name = result end
                end
                if known and name and tostring(name) ~= "" then
                    addCandidate(candidates, seen, {
                        id = id,
                        entityType = "npc",
                        name = name,
                        aliases = { name },
                        source = "known_snapshot",
                    })
                    snapshotCount = snapshotCount + 1
                end
            end
        end
    end
    return candidates
end

return EntityCandidates
