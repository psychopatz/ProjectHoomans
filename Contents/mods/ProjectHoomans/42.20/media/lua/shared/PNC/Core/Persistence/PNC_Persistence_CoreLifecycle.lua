-- Project Hoomans bridge to PsychopatzCore's canonical actor lifecycle and GC.
-- Stores zero duplicate tombstones or GC databases inside Hoomans.

PNC = PNC or {}
PNC.Persistence = PNC.Persistence or {}

local Persistence = PNC.Persistence
local Adapter = Persistence.CoreLifecycle or {}
Persistence.CoreLifecycle = Adapter

Adapter.PROVIDER_ID = "ProjectHoomans.DurableRoots"

local VALID_DEATH_REASON_MAP = {
    departed = "departed",
    left = "departed",
    dismissed = "departed",
    exiled = "departed",
    retired = "retired",
    missing_permanent = "missing_permanent",
    player_death = "player_death",
    other = "other",
}

local function isServerAuthority()
    if PNC.Core and type(PNC.Core.IsAuthority) == "function" then
        return PNC.Core.IsAuthority() == true
    end
    local clientOnly = type(isClient) == "function" and isClient() == true
        and (type(isServer) ~= "function" or isServer() ~= true)
    return not clientOnly
end

local function worldAgeHours(options)
    if type(options) == "table" and tonumber(options.retiredAt) ~= nil then
        return math.max(0, tonumber(options.retiredAt))
    end
    if type(options) == "table" and tonumber(options.now) ~= nil then
        return math.max(0, tonumber(options.now))
    end
    if type(getGameTime) == "function" then
        local gt = getGameTime()
        if gt and type(gt.getWorldAgeHours) == "function" then
            local hours = tonumber(gt:getWorldAgeHours())
            if hours and hours == hours then return math.max(0, hours) end
        end
    end
    return 0
end

local function resolveCore(core)
    return core or PsychopatzCore
end

local function resolveRegistry(core)
    local c = resolveCore(core)
    local actors = c and c.Actors or nil
    return actors and actors.DefaultRegistry or nil, c
end

local function sortedKeys(tbl)
    local keys = {}
    for k in pairs(tbl or {}) do
        keys[#keys + 1] = k
    end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    return keys
end

local function buildMatchSet(ref, tombstone)
    local set = {}
    local function add(v)
        if type(v) ~= "string" or v == "" then return end
        set[v] = true
        if string.sub(v, 1, 4) == "npc:" then
            set[string.sub(v, 5)] = true
        elseif string.sub(v, 1, 6) == "actor:" then
            set[string.sub(v, 7)] = true
            set["npc:" .. v] = true
        else
            set["npc:" .. v] = true
        end
    end
    add(ref)
    if type(tombstone) == "table" then
        add(tombstone.ref)
        for _, alias in ipairs(tombstone.aliases or {}) do
            add(alias)
        end
    end
    return set
end

function Adapter.ResolveCanonicalActorID(recordOrID)
    if type(recordOrID) == "table" then
        local runtime = type(recordOrID.runtime) == "table"
            and recordOrID.runtime or nil
        local raw = recordOrID.coreActorID
            or (runtime and runtime.coreActorID)
            or recordOrID.actorID
            or recordOrID.actorId
            or recordOrID.id
        local text = raw ~= nil and tostring(raw) or ""
        return text ~= "" and text or nil
    end
    if type(recordOrID) == "string" or type(recordOrID) == "number" then
        local text = tostring(recordOrID)
        return text ~= "" and text or nil
    end
    return nil
end

function Adapter.MapDeathReason(reason)
    local raw = type(reason) == "string" and string.lower(reason) or ""
    return VALID_DEATH_REASON_MAP[raw] or "death"
end

function Adapter.RetireActor(recordOrID, reason, options)
    if not isServerAuthority() then
        return false, "server_authority_required"
    end
    options = type(options) == "table" and options or {}
    local record = type(recordOrID) == "table" and recordOrID or nil
    if record and record.runtime and record.runtime.coreLifecycleRetired == true
        and options.force ~= true
    then
        return true, "already_retired"
    end

    local reg, core = resolveRegistry(options.core)
    if not reg or type(reg.Retire) ~= "function" then
        return false, "core_registry_unavailable"
    end

    local actorID = Adapter.ResolveCanonicalActorID(recordOrID)
    if not actorID then
        return false, "actor_id_required"
    end

    local at = worldAgeHours(options)
    local liveActor = type(reg.Get) == "function" and reg:Get(actorID) or nil
    if liveActor and type(liveActor.providerLease) == "table"
        and liveActor.providerLease.provider == "ProjectHoomans"
        and liveActor.providerLease.state ~= "released"
        and Persistence.CoreProvider
        and type(Persistence.CoreProvider.Release) == "function"
    then
        local released = Persistence.CoreProvider.Release(liveActor, core, {
            provider = "ProjectHoomans",
            owner = "ProjectHoomans",
            reason = Adapter.MapDeathReason(reason),
            now = at,
        })
        if released and released.providerLease and type(reg.Commit) == "function" then
            reg:Commit(liveActor.actorId or actorID, {
                providerLease = released.providerLease,
            }, liveActor.revision)
        end
    end

    local label = options.label
        or (record and (record.displayName or record.name))
        or nil
    local aliases = options.aliases
    if not aliases and record and record.id ~= nil
        and tostring(record.id) ~= tostring(actorID)
    then
        aliases = { tostring(record.id) }
    end

    local retireSpec = {
        authority = "server",
        reason = Adapter.MapDeathReason(reason),
        retiredAt = at,
        graceHours = options.graceHours,
        label = label,
        owner = "ProjectHoomans",
        role = options.role
            or (record and (record.factionRole or record.role or record.tacticalClass))
            or nil,
        aliases = aliases,
        allowAlreadyRetired = options.allowAlreadyRetired ~= false,
        expectedLifecycleRevision = options.expectedLifecycleRevision,
    }
    local ts, retireReason = reg:Retire(actorID, retireSpec)
    if not ts then
        return false, retireReason or "core_retire_failed"
    end
    if record then
        record.runtime = type(record.runtime) == "table" and record.runtime or {}
        record.runtime.coreLifecycleRetired = true
    end
    -- Scrub dead non-leader NPC IDs from Hoomans faction memberIDs ONLY after RemoveRecord
    -- has retired the record (preserving Factions.OnNPCDeath's leadership-only contract).
    local recordID = record and record.id ~= nil and tostring(record.id) or nil
    if recordID and PNC.Registry and type(PNC.Registry.Get) == "function"
        and not PNC.Registry.Get(recordID)
        and PNC.Factions and type(PNC.Factions.Registry) == "table"
        and type(PNC.Factions.Registry.byID) == "table"
    then
        for _, fID in ipairs(sortedKeys(PNC.Factions.Registry.byID)) do
            local faction = PNC.Factions.Registry.byID[fID]
            if type(faction) == "table" and type(faction.memberIDs) == "table" then
                local changed = false
                for _, key in ipairs({ recordID, tostring(actorID) }) do
                    if faction.memberIDs[key] ~= nil and faction.leaderNPCID ~= key then
                        faction.memberIDs[key] = nil
                        changed = true
                    end
                end
                if changed and PNC.Factions.Internal
                    and type(PNC.Factions.Internal.touchFaction) == "function"
                then
                    PNC.Factions.Internal.touchFaction(faction)
                    if type(PNC.Factions.Internal.touchRegistry) == "function" then
                        PNC.Factions.Internal.touchRegistry()
                    end
                end
            end
        end
    end
    return true, retireReason or "retired", ts
end

function Adapter.HardDeleteRollback(recordOrID, reason, options)
    if not isServerAuthority() then
        return false, "server_authority_required"
    end
    options = type(options) == "table" and options or {}
    local record = type(recordOrID) == "table" and recordOrID or nil
    local reg = resolveRegistry(options.core)
    if not reg then
        return false, "core_registry_unavailable"
    end
    local actorID = Adapter.ResolveCanonicalActorID(recordOrID)
    if not actorID then
        return false, "actor_id_required"
    end
    local ok, deleteReason
    if type(reg.HardDelete) == "function" then
        ok, deleteReason = reg:HardDelete(actorID, {
            authority = "server",
            reason = reason or "rollback",
        })
    elseif type(reg.Remove) == "function" then
        ok, deleteReason = reg:Remove(actorID)
    else
        return false, "core_hard_delete_unavailable"
    end
    if not ok then
        return false, deleteReason or "core_hard_delete_failed"
    end
    if record then
        record.runtime = type(record.runtime) == "table" and record.runtime or {}
        record.runtime.coreLifecycleDeleted = true
    end
    return true, deleteReason or "hard_deleted"
end

local function collectStrongRefs(_, emit)
    -- 1. Active corpses / colony death markers awaiting burial/decay or reanimation.
    if PNC.Registry and type(PNC.Registry.DeathMarkers) == "table" then
        for _, markerID in ipairs(sortedKeys(PNC.Registry.DeathMarkers)) do
            local marker = PNC.Registry.DeathMarkers[markerID]
            if type(marker) == "table" and marker.id then
                local reason = marker.infected == true
                    and "active_infected_corpse_reanimation"
                    or "active_colony_corpse_marker"
                emit(tostring(marker.id), reason, {
                    corpseToken = marker.corpseToken,
                })
            end
        end
    end

    -- 2. Active non-terminal quests pinning giver or player owner.
    local questRepo = PNC.QuestRepository
    if questRepo and type(questRepo.State) == "table"
        and type(questRepo.State.byKey) == "table"
    then
        local terminal = questRepo.TERMINAL or {}
        for _, key in ipairs(sortedKeys(questRepo.State.byKey)) do
            local q = questRepo.State.byKey[key]
            if type(q) == "table" and not terminal[q.status] then
                if q.giverNPCID then
                    emit(tostring(q.giverNPCID), "active_quest_giver", {
                        questID = q.questID,
                    })
                end
                if q.ownerCharacterUUID and PNC.PlayerCharacters
                    and PNC.PlayerCharacters.Registry
                    and type(PNC.PlayerCharacters.Registry.byUUID) == "table"
                then
                    local pRec = PNC.PlayerCharacters.Registry.byUUID[q.ownerCharacterUUID]
                    if pRec and pRec.accountKey then
                        emit("player:" .. tostring(pRec.accountKey) .. ":" .. tostring(q.ownerCharacterUUID),
                            "active_quest_owner", { questID = q.questID })
                    end
                end
            end
        end
    end

    -- 3. Active faction leadership (not archived, not general rank-and-file dead).
    local factions = PNC.Factions
    if factions and type(factions.Registry) == "table"
        and type(factions.Registry.byID) == "table"
    then
        for _, fID in ipairs(sortedKeys(factions.Registry.byID)) do
            local faction = factions.Registry.byID[fID]
            if type(faction) == "table" and faction.status == "active" then
                if faction.leaderNPCID and faction.leaderNPCID ~= "" then
                    emit(tostring(faction.leaderNPCID), "active_faction_leader", {
                        factionID = fID,
                    })
                end
                if faction.ownerPlayerKey
                    and string.match(tostring(faction.ownerPlayerKey), "^player:[^:]+:char_[%w_%-]+$")
                then
                    emit(tostring(faction.ownerPlayerKey), "active_faction_owner", {
                        factionID = fID,
                    })
                end
            end
        end
    end

    -- 4. Durable social bonds held by live PNC records.
    if PNC.Registry then
        local recordMap = type(PNC.Registry.Data) == "table" and PNC.Registry.Data or nil
        local liveRecords = {}
        if recordMap then
            for _, rID in ipairs(sortedKeys(recordMap)) do
                liveRecords[#liveRecords + 1] = recordMap[rID]
            end
        elseif type(PNC.Registry.List) == "function" then
            liveRecords = PNC.Registry.List() or {}
            table.sort(liveRecords, function(a, b)
                return tostring(a and a.id or "") < tostring(b and b.id or "")
            end)
        end
        for _, record in ipairs(liveRecords) do
            if type(record) == "table" and record.alive ~= false
                and type(record.social) == "table"
                and type(record.social.relationships) == "table"
            then
                for _, targetKey in ipairs(sortedKeys(record.social.relationships)) do
                    local rel = record.social.relationships[targetKey]
                    local bond = type(rel) == "table" and rel.bond or nil
                    if type(bond) == "table" and type(bond.class) == "string"
                        and bond.class ~= "" and bond.class ~= "none"
                    then
                        emit(targetKey, "pnc_durable_bond", {
                            ownerNPC = tostring(record.id),
                            bondClass = bond.class,
                        })
                    end
                end
            end
        end
    end

    return true
end

local function collectWeakRefs(_, emit)
    local questRepo = PNC.QuestRepository
    if questRepo and type(questRepo.State) == "table"
        and type(questRepo.State.byKey) == "table"
    then
        local terminal = questRepo.TERMINAL or {}
        for _, key in ipairs(sortedKeys(questRepo.State.byKey)) do
            local q = questRepo.State.byKey[key]
            if type(q) == "table" and terminal[q.status] and q.giverNPCID then
                emit(tostring(q.giverNPCID), "terminal_quest_giver", {
                    questID = q.questID,
                })
            end
        end
    end

    local uniqueReg = PNC.UniqueNPCRegistry
    local worldStates = uniqueReg and uniqueReg.Internal
        and type(uniqueReg.Internal.Ensure) == "function"
        and uniqueReg.Internal.Ensure() or nil
    if type(worldStates) == "table" then
        for _, defID in ipairs(sortedKeys(worldStates)) do
            local entry = worldStates[defID]
            if type(entry) == "table" and entry.status == "dead"
                and entry.runtimeNpcId and entry.runtimeNpcId ~= ""
            then
                emit(tostring(entry.runtimeNpcId), "unique_npc_dead_ref", {
                    definitionId = defID,
                })
            end
        end
    end

    local factions = PNC.Factions
    if factions and type(factions.Registry) == "table"
        and type(factions.Registry.byID) == "table"
    then
        for _, fID in ipairs(sortedKeys(factions.Registry.byID)) do
            local faction = factions.Registry.byID[fID]
            if type(faction) == "table" then
                if faction.status ~= "active"
                    and faction.leaderNPCID and faction.leaderNPCID ~= ""
                then
                    emit(tostring(faction.leaderNPCID), "archived_faction_ref", {
                        factionID = fID,
                    })
                end
                if PNC.Registry and type(PNC.Registry.Get) == "function" then
                    for _, mid in ipairs(sortedKeys(faction.memberIDs)) do
                        if not PNC.Registry.Get(mid) and faction.leaderNPCID ~= mid then
                            emit(tostring(mid), "dead_faction_member_ref", {
                                factionID = fID,
                            })
                        end
                    end
                end
            end
        end
    end

    return true
end

local function onBeforePurge(ref, ctx)
    local matchSet = buildMatchSet(ref, ctx and ctx.tombstone)
    local compacted = 0

    local factions = PNC.Factions
    if factions and type(factions.Registry) == "table"
        and type(factions.Registry.byID) == "table"
    then
        for _, fID in ipairs(sortedKeys(factions.Registry.byID)) do
            local faction = factions.Registry.byID[fID]
            if type(faction) == "table" then
                local changed = false
                for _, mid in ipairs(sortedKeys(faction.memberIDs)) do
                    if matchSet[mid] then
                        faction.memberIDs[mid] = nil
                        compacted = compacted + 1
                        changed = true
                    end
                end
                if faction.leaderNPCID and matchSet[faction.leaderNPCID] then
                    faction.leaderNPCID = nil
                    compacted = compacted + 1
                    changed = true
                end
                if changed and factions.Internal and type(factions.Internal.touchFaction) == "function" then
                    factions.Internal.touchFaction(faction)
                    if type(factions.Internal.touchRegistry) == "function" then
                        factions.Internal.touchRegistry()
                    end
                end
            end
        end
    end

    if PNC.MedicalCareService and type(PNC.MedicalCareService.OnNPCDeath) == "function" then
        for matchKey in pairs(matchSet) do
            local cancelled = PNC.MedicalCareService.OnNPCDeath(matchKey)
            if type(cancelled) == "number" and cancelled > 0 then
                compacted = compacted + cancelled
            end
        end
    end

    if PNC.QuestService and type(PNC.QuestService.OnNPCDeath) == "function" then
        for matchKey in pairs(matchSet) do
            local failed = PNC.QuestService.OnNPCDeath(matchKey)
            if type(failed) == "number" and failed > 0 then
                compacted = compacted + failed
            end
        end
    end

    local uniqueReg = PNC.UniqueNPCRegistry
    local worldStates = uniqueReg and uniqueReg.Internal
        and type(uniqueReg.Internal.Ensure) == "function"
        and uniqueReg.Internal.Ensure() or nil
    if type(worldStates) == "table" then
        for _, defID in ipairs(sortedKeys(worldStates)) do
            local entry = worldStates[defID]
            if type(entry) == "table" and entry.status == "dead"
                and entry.runtimeNpcId and matchSet[tostring(entry.runtimeNpcId)]
            then
                entry.runtimeNpcId = nil
                entry.tombstonePurged = true
                compacted = compacted + 1
                if PNC.HoomansWorldView and type(PNC.HoomansWorldView.Touch) == "function" then
                    PNC.HoomansWorldView.Touch("unique_npc_tombstone_purged")
                end
            end
        end
    end

    return true, compacted
end

function Adapter.EnsureGCProvider(core)
    if not isServerAuthority() then return false, "server_authority_required" end
    local c = resolveCore(core)
    local gc = c and c.Actors and c.Actors.GC or nil
    if not gc or type(gc.RegisterReferenceProvider) ~= "function" then
        return false, "core_gc_unavailable"
    end
    return gc.RegisterReferenceProvider(Adapter.PROVIDER_ID, {
        owner = "ProjectHoomans",
        maxRefs = 2048,
        CollectStrongRefs = collectStrongRefs,
        CollectWeakRefs = collectWeakRefs,
        OnBeforePurge = onBeforePurge,
    })
end

Adapter.EnsureGCProvider()

local function registerHook()
    if isServerAuthority() then
        Adapter.EnsureGCProvider()
    end
end

if Events and Events.OnInitGlobalModData
    and type(Events.OnInitGlobalModData.Add) == "function"
    and not Adapter._gcInitHookRegistered
then
    Adapter._gcInitHookRegistered = true
    Events.OnInitGlobalModData.Add(registerHook)
end

if Events and Events.OnServerStarted
    and type(Events.OnServerStarted.Add) == "function"
    and not Adapter._gcServerHookRegistered
then
    Adapter._gcServerHookRegistered = true
    Events.OnServerStarted.Add(registerHook)
end

return Adapter
