local Lifecycle = PNC and PNC.BodyLifecycle
if not Lifecycle then
    return
end

local Internal = Lifecycle.Internal
local Deps = Internal and Internal.HuskLedgerDebug
if not Deps then
    return
end

local Core = PNC.Core
local Const = PNC.Const
local noteIncrement = Deps.noteIncrement
local noteGauge = Deps.noteGauge
local logDebug = Deps.logDebug
local worldAgeHours = Deps.worldAgeHours
local persist = Deps.persist
local ensureLoaded = Deps.ensureLoaded
local isMarkedZombie = Deps.isMarkedZombie
local ENTRY_LAYOUT = Deps.ENTRY_LAYOUT

local function clampLimit(value, fallback, maximum)
    local number = math.floor(tonumber(value) or fallback)
    if number < 1 then
        number = 1
    end
    if maximum and number > maximum then
        number = maximum
    end
    return number
end

local function censusBodies(now)
    local census = PNC.WorldCensus
    if census and census.GetAll then
        local bodies = census.GetAll(now, false)
        if type(bodies) == "table" then
            return bodies
        end
    end
    if getCell then
        local cell = getCell()
        local list = cell and cell.getZombieList and cell:getZombieList() or nil
        local output = {}
        local index
        if list and list.size and list.get then
            for index = 0, list:size() - 1 do
                output[#output + 1] = list:get(index)
            end
        end
        return output
    end
    return nil
end

local function estimateEntryBytes(entry)
    local bytes = 24
    local index
    for index = 1, #ENTRY_LAYOUT do
        local value = entry[ENTRY_LAYOUT[index]]
        if type(value) == "string" then
            bytes = bytes + #value + 4
        elseif type(value) == "number" then
            bytes = bytes + 10
        elseif value ~= nil then
            bytes = bytes + 4
        end
    end
    return bytes
end

function Lifecycle.BuildHuskDebugSnapshot(options)
    local ledger = ensureLoaded()
    local reaper = Lifecycle.HuskReaper
    local entries = {}
    local outfitRows = {}
    local outfits = {}
    local totals = {
        bodies = 0, marked = 0, unmarked = 0, fingerprint = 0, orphans = 0,
        bytes = 0,
    }
    local entryLimit
    local outfitLimit
    local hours
    local bodies
    local index
    options = type(options) == "table" and options or {}
    entryLimit = clampLimit(options.entryLimit
        or Const.HUSK_DEBUG_MAX_ENTRIES or 12, 12, 64)
    outfitLimit = clampLimit(options.outfitLimit
        or Const.HUSK_DEBUG_MAX_OUTFITS or 8, 8, 24)
    hours = worldAgeHours()
    for index = 1, #ledger.entries do
        local entry = ledger.entries[index]
        totals.bytes = totals.bytes + estimateEntryBytes(entry)
        if #entries < entryLimit then
            entries[#entries + 1] = {
                npcId = entry.npcId,
                x = entry.x,
                y = entry.y,
                z = entry.z,
                outfitId = entry.outfitId,
                ageHours = math.max(0,
                    math.floor((hours - (tonumber(entry.at) or hours)) * 10)
                        / 10),
                attempts = tonumber(entry.attempts) or 0,
                abandoned = entry.abandoned == true,
                reason = entry.reason,
            }
        end
    end
    bodies = censusBodies(Core and Core.Now and Core.Now() or 0)
    if type(bodies) == "table" then
        for index = 1, #bodies do
            local zombie = bodies[index]
            if zombie then
                totals.bodies = totals.bodies + 1
                if isMarkedZombie(zombie) then
                    totals.marked = totals.marked + 1
                else
                    local outfitId = zombie.getPersistentOutfitID
                        and zombie:getPersistentOutfitID() or nil
                    local key = tostring(outfitId)
                    local row = outfits[key]
                    totals.unmarked = totals.unmarked + 1
                    if Lifecycle.IsOrphanedShell(zombie) then
                        totals.orphans = totals.orphans + 1
                    end
                    if not row then
                        row = {
                            id = outfitId,
                            key = key,
                            count = 0,
                            shell = Lifecycle.IsShellOutfitID(outfitId),
                        }
                        outfits[key] = row
                        outfitRows[#outfitRows + 1] = row
                    end
                    row.count = row.count + 1
                    if row.shell then
                        totals.fingerprint = totals.fingerprint + 1
                    end
                end
            end
        end
    end
    table.sort(outfitRows, function(left, right)
        if left.shell ~= right.shell then
            return left.shell == true
        end
        if left.count ~= right.count then
            return left.count > right.count
        end
        return tostring(left.key) < tostring(right.key)
    end)
    while #outfitRows > outfitLimit do
        outfitRows[#outfitRows] = nil
    end
    local outfitIds = {}
    local outfitId = nil
    for outfitId in pairs(ledger.shellOutfitIds) do
        outfitIds[#outfitIds + 1] = tostring(outfitId)
    end
    table.sort(outfitIds)
    while #outfitIds > outfitLimit do
        outfitIds[#outfitIds] = nil
    end
    return {
        available = true,
        ledger = {
            entries = #ledger.entries,
            maxEntries = tonumber(Const.HUSK_LEDGER_MAX_ENTRIES) or 48,
            writes = tonumber(ledger.writes) or 0,
            refreshes = tonumber(ledger.refreshes) or 0,
            reaped = tonumber(ledger.reaped) or 0,
            expired = tonumber(ledger.expired) or 0,
            skipped = tonumber(ledger.skipped) or 0,
            seeds = tonumber(ledger.seeds) or 0,
            ttlHours = tonumber(Const.HUSK_LEDGER_TTL_HOURS) or 168,
            estimatedBytes = totals.bytes,
        },
        shellOutfits = {
            count = Lifecycle.ShellOutfitCount(),
            ids = table.concat(outfitIds, ","),
        },
        reaper = {
            active = reaper and reaper.loggedActive == true or false,
            reaped = reaper and tonumber(reaper.reaped) or 0,
            pending = reaper and #(reaper.pending or {}) or 0,
            failed = reaper and tonumber(reaper.failed) or 0,
            abandoned = reaper and tonumber(reaper.abandoned) or 0,
            fingerprintReaps = reaper
                and tonumber(reaper.fingerprintReaps) or 0,
        },
        bodies = {
            disabled = Lifecycle.AreZombieSpawnsDisabled
                and Lifecycle.AreZombieSpawnsDisabled() == true or false,
            total = totals.bodies,
            marked = totals.marked,
            unmarked = totals.unmarked,
            fingerprint = totals.fingerprint,
            orphans = totals.orphans,
            outfits = outfitRows,
        },
        entries = entries,
        truncated = #ledger.entries > #entries,
    }
end

--[[
    One-line live diagnosis for the husk lane, for the debug console.
]]
function Lifecycle.DebugHuskReport(limit)
    local snapshot = Lifecycle.BuildHuskDebugSnapshot({
        entryLimit = limit or (Const.HUSK_DEBUG_MAX_ENTRIES or 12),
    })
    local ledger = snapshot.ledger
    local reaper = snapshot.reaper
    local bodies = snapshot.bodies
    local parts = {}
    local index
    for index = 1, #bodies.outfits do
        local row = bodies.outfits[index]
        parts[#parts + 1] = tostring(row.key) .. "x" .. tostring(row.count)
            .. (row.shell and "*" or "")
    end
    return table.concat({
        "ledger=" .. tostring(ledger.entries),
        "writes=" .. tostring(ledger.writes),
        "shellOutfits=" .. tostring(snapshot.shellOutfits.count),
        "shellOutfitIds=" .. tostring(snapshot.shellOutfits.ids),
        "zombiesDisabled=" .. tostring(bodies.disabled),
        "bodies=" .. tostring(bodies.total),
        "marked=" .. tostring(bodies.marked),
        "unmarked=" .. tostring(bodies.unmarked),
        "fingerprint=" .. tostring(bodies.fingerprint),
        "orphans=" .. tostring(bodies.orphans),
        "reaped=" .. tostring(reaper.reaped),
        "abandoned=" .. tostring(reaper.abandoned),
        "estBytes=" .. tostring(ledger.estimatedBytes),
        "unmarkedOutfits=" .. table.concat(parts, ","),
    }, " ")
end

--[[
    Drop every recorded loss and persist the empty ledger. Safe to call at any
    time; the reaper simply has nothing to reclaim until new losses arrive.
]]
function Lifecycle.ClearHuskLedger()
    local ledger = ensureLoaded()
    ledger.entries = {}
    ledger.index = {}
    persist(ledger)
    noteGauge("HuskLedger.Entries", 0)
    return true
end

--[[
    Seed the ledger from persisted body hints.

    A save created before this lifecycle existed already contains husks whose
    losses were never observed, so nothing can arm a reap for them. Every
    deserialized record that still carries a body hint (the engine persistent
    outfit id plus the position its shell last occupied) is exactly a shell that
    the population manager may hand back unmarked. Seeding is authority-only,
    once per session, and bounded by the ledger cap; an entry whose hint no
    longer matches any body simply expires.
]]
function Lifecycle.SeedHuskLedgerFromRecords(now)
    local reg = Internal.registry and Internal.registry() or nil
    local seeded = 0
    local budget = tonumber(Const.HUSK_LEDGER_MAX_ENTRIES) or 256
    if Lifecycle.HuskLedgerSeeded == true then
        return 0
    end
    if not (Core and Core.IsAuthority and Core.IsAuthority() == true) then
        return 0
    end
    if not reg or not reg.ForEach or not reg.EnsureLoaded then
        return 0
    end
    reg.EnsureLoaded()
    if reg.Loaded ~= true then
        -- Wait for the registry to exist before deciding a record is bodyless.
        return 0
    end
    Lifecycle.HuskLedgerSeeded = true
    reg.ForEach(function(record)
        local hint
        local registry
        local zombie
        if seeded >= budget then
            return
        end
        if not record or record.alive == false then
            return
        end
        if Const.PRESENCE_CORPSE ~= nil
            and record.presenceState == Const.PRESENCE_CORPSE
        then
            return
        end
        hint = record.runtime and record.runtime.startupBodyHint or nil
        if not hint or hint.instanceID == nil then
            return
        end
        registry = Internal.registry and Internal.registry() or nil
        zombie = registry and registry.GetLiveZombie
            and registry.GetLiveZombie(record.id) or nil
        if zombie and Internal.isBodyAttached(zombie) == true then
            return
        end
        if Lifecycle.NoteLostBody(record, nil, "startup_seed") then
            seeded = seeded + 1
        end
    end)
    if seeded > 0 then
        noteIncrement("HuskLedger.Seeds")
        logDebug("PNC husk ledger seeded from persisted body hints count="
            .. tostring(seeded))
    end
    return seeded
end

function Lifecycle.BuildHuskLedgerDiagnostics()
    local ledger = ensureLoaded()
    return {
        entries = #ledger.entries,
        writes = tonumber(ledger.writes) or 0,
        refreshes = tonumber(ledger.refreshes) or 0,
        reaped = tonumber(ledger.reaped) or 0,
        expired = tonumber(ledger.expired) or 0,
        skipped = tonumber(ledger.skipped) or 0,
        lastFactory = Lifecycle.BodyFactory
            and Lifecycle.BodyFactory.lastFactory or nil,
    }
end


