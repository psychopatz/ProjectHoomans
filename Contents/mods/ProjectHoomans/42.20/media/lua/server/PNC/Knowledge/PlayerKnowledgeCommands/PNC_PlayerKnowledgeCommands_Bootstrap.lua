if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Commands = PNC.PlayerKnowledgeCommands
local H = Commands.Internal
local Network = PNC.Network
local Core = PNC.Core

function Commands.HandleBootstrap(player, args)
    args = type(args) == "table" and args or {}
    local context, reason = H.ContextFor(player, "player_bootstrap")
    if context and PNC.SocialProfiles and PNC.SocialProfiles.GetPlayerProfile then
        context.socialProfile = PNC.SocialProfiles.GetPlayerProfile(
            context.characterUUID
        )
    end
    if context and PNC.PlayerCharacters
        and PNC.PlayerCharacters.GetRegistryRecord
    then
        local playerRecord = PNC.PlayerCharacters.GetRegistryRecord(
            context.characterUUID
        )
        if playerRecord then
            context.forename = playerRecord.forename
            context.surname = playerRecord.surname
            context.displayName = playerRecord.displayName
        end
    end
    local payload
    if not context then
        payload = { requestID = args.requestID, state = "error", reason = reason }
    else
        local committed, commitReason = PNC.PersistenceCoordinator.Commit(
            "player_bootstrap"
        )
        if not committed then
            payload = { requestID = args.requestID, state = "error",
                reason = commitReason, context = context }
            Network.SendPlayerBootstrap(player, payload)
            return payload
        end
        local snapshots
        local scopedRequest = args.scope == "live"
            or args.scope == "interest"
        local requestedNPCIDs
        if scopedRequest then
            requestedNPCIDs = type(args.npcIDs) == "table"
                and args.npcIDs or {}
        end
        snapshots, reason = PNC.NPCKnowledge.BuildKnownSnapshotsForPlayer(
            player,
            requestedNPCIDs
        )
        if not snapshots then
            payload = { requestID = args.requestID, state = "error", reason = reason }
        else
            for index = 1, #snapshots do
                snapshots[index] = H.SanitizeSnapshot(snapshots[index])
                snapshots[index].characterUUID = context.characterUUID
                snapshots[index].accountKey = context.accountKey
                snapshots[index].bindingRevision = context.bindingRevision
            end
            local chunkCount = math.max(1, math.ceil(
                #snapshots / H.BootstrapChunkSize
            ))
            local knowledgeRevision = tonumber(PNC.NPCKnowledge.Registry
                and PNC.NPCKnowledge.Registry.revision) or 0
            for chunkIndex = 1, chunkCount do
                local chunk = {}
                local first = (chunkIndex - 1) * H.BootstrapChunkSize + 1
                local last = math.min(#snapshots,
                    chunkIndex * H.BootstrapChunkSize)
                for index = first, last do chunk[#chunk + 1] = snapshots[index] end
                payload = {
                    requestID = args.requestID,
                    scope = requestedNPCIDs
                        and tostring(args.scope) or "all",
                    state = chunkIndex == chunkCount and "known" or "loading",
                    context = context,
                    snapshots = chunk,
                    chunkIndex = chunkIndex,
                    chunkCount = chunkCount,
                    knowledgeRevision = knowledgeRevision,
                }
                Network.SendPlayerBootstrap(player, payload)
            end
            Commands.Diagnostics[context.characterUUID] = {
                accountKey = context.accountKey,
                characterUUID = context.characterUUID,
                bindingRevision = context.bindingRevision,
                bootstrapRevision = knowledgeRevision,
                knowledgeRevision = knowledgeRevision,
                migrationResult = PNC.PlayerCharacters.Registry.migration
                    and PNC.PlayerCharacters.Registry.migration.status,
                aliases = Core.DeepCopy(
                    PNC.PlayerCharacters.Registry.uuidAliases or {}
                ),
            }
            return payload
        end
    end
    Network.SendPlayerBootstrap(player, payload)
    return payload
end
