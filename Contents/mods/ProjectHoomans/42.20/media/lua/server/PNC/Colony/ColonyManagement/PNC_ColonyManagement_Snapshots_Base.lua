if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ColonyManagement = PNC.ColonyManagement or {}
PNC.ColonyManagement.Internal = PNC.ColonyManagement.Internal or {}

local Management = PNC.ColonyManagement
local Internal = Management.Internal
local Deps = Internal.SnapshotDeps or {}
local resolveSnapshotOwner = Deps.resolveSnapshotOwner
local playerFactionForSnapshot = Deps.playerFactionForSnapshot
local activeColonyForFaction = Deps.activeColonyForFaction
local snapshotIdentityStatus = Deps.snapshotIdentityStatus

function Management.BuildBaseSnapshot(player)
    local ownershipContext, identityReason, resolverAvailable =
        resolveSnapshotOwner(player)
    local playerFaction, factionReason = playerFactionForSnapshot(
        player, ownershipContext, resolverAvailable)
    local colony = activeColonyForFaction(playerFaction)
    local base = colony and PNC.BaseService
        and PNC.BaseService.GetForColony(colony.id) or nil
    local faction = playerFaction and {
        id = playerFaction.id,
        name = playerFaction.name,
        revision = playerFaction.revision,
    } or nil
    local colonySnapshot = colony and {
        id = colony.id,
        factionID = playerFaction and playerFaction.id or nil,
    } or nil
    local identityStatus = snapshotIdentityStatus(
        ownershipContext,
        identityReason,
        resolverAvailable,
        playerFaction,
        factionReason
    )
    --[[
        The Base window's Facilities tab prices every build requirement against
        the stockpile, so this projection has to carry the stockpile rows. It
        did not, and every requirement therefore read as "0 in stock" no matter
        how full the stockpile was, which disabled BUILD and made the server
        reject the order with MISSING_MATERIALS.

        Trim what only the Colony Storage window renders (journal activity,
        storage metrics, debug authorization): this payload is polled every few
        seconds while the window is open, and the rows are the only part the
        build UI needs.
    ]]
    local storage
    if PNC.ColonyStorageService
        and type(PNC.ColonyStorageService.BuildSnapshot) == "function"
    then
        storage = PNC.ColonyStorageService.BuildSnapshot(
            player, { includeRows = true }, ownershipContext)
        if storage then
            storage.activity = nil
            storage.metrics = nil
            storage.debugAuthorized = nil
        end
    end
    --[[
        The Buildings tab reads snapshot.building for its queue. The base
        projection never carried it, so the tab showed "NO MATCHING RECIPES"
        and an empty blueprint queue while the same data was only available
        through the heavier management projection.

        Only the queue travels: the recipe catalog is derived from
        SpriteConfigManager on both sides, so the client rebuilds it locally and
        prices it against the stockpile rows above. Shipping a few hundred
        descriptors with per-requirement stock on a two-second poll would be
        pure payload.
    ]]
    local building
    if colony and PNC.BuildingService
        and type(PNC.BuildingService.BuildQueueProjection) == "function"
    then
        building = {
            queue = PNC.BuildingService.BuildQueueProjection(colony,
                storage and storage.storageId or storage and storage.id or nil),
            generation = PNC.BuildRecipeCatalog
                and PNC.BuildRecipeCatalog.Generation or nil,
        }
    end
    --[[
        The Facilities tab gates workstation builds on researched technologies.
        It read snapshot.research, which this projection never carried, so a
        learned technology still reported RESEARCH REQUIRED forever.

        Only the learned id list travels: the full research projection walks
        every stockpile record looking for books and blueprints, which is far
        too heavy for a two-second poll, and the gate only needs to know what is
        already known.
    ]]
    local research
    if colony and PNC.ResearchRepository
        and type(PNC.ResearchRepository.Get) == "function"
    then
        local state = PNC.ResearchRepository.Get(colony.id, false)
        research = {
            learnedTechnologyIds = state and PNC.Core.DeepCopy(
                state.learnedTechnologyIds) or {},
            knowledgeRevision = state and state.knowledgeRevision or 0,
        }
    end
    return {
        colony = colonySnapshot,
        faction = faction,
        settlement = base and Internal.BuildSettlementSnapshot(base, {}) or nil,
        storage = storage,
        building = building,
        research = research,
        identityStatus = identityStatus,
        generatedAt = PNC.NeedsUtils.WorldAgeHours(),
    }
end


return Management
