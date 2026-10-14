PNC = PNC or {}
PNC.BodyLifecycle = PNC.BodyLifecycle or {}
PNC.BodyLifecycle.Internal = PNC.BodyLifecycle.Internal or {}

local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
local Core = PNC.Core
local Const = PNC.Const
local Deps = Internal.HuskLedgerStorage or {}
local ensureLoaded = Deps.ensureLoaded
local persist = Deps.persist
local noteIncrement = Deps.noteIncrement
local logDebug = Deps.logDebug

local function validEngineIdentity(value)
    local numeric
    if value == nil then
        return false
    end
    if tostring(value) == "" or tostring(value) == "0" then
        return false
    end
    numeric = tonumber(value)
    return numeric == nil or numeric ~= 0
end

--[[
    PNC shell outfit identity.

    New live shells use the PNC-only persistent outfit "PNCShellCarrier", and
    the engine stores its persistent outfit id in the anonymous population
    record that a virtualized shell becomes. That id therefore survives where
    ModData does not, which makes it a durable hint that a body is (or was) a
    PNC shell. Legacy saves may still contain the old "Naked" carrier and are
    handled by strict ledger and positional hints.

    The ids are LEARNED from shells PNC actually creates and persisted, so this
    never depends on the outfit script name or on a Lua-side outfit lookup.

    The general shell-outfit set is deliberately NOT used as a global husk
    rule: vanilla also dresses bathroom zombies with the "Naked" outfit, so
    matching on that set alone would delete ordinary zombies. The separate
    carrier set is only trusted after PNC has learned the id from a body it
    created.
]]
function Lifecycle.NoteShellOutfitID(outfitID)
    local ledger
    local key
    if not validEngineIdentity(outfitID) then
        return false
    end
    ledger = ensureLoaded()
    key = tostring(outfitID)
    if key == "" or ledger.shellOutfitIds[key] == true then
        return false
    end
    if Lifecycle.ShellOutfitCount() >= (tonumber(
        Const.HUSK_LEDGER_MAX_SHELL_OUTFITS) or 32)
    then
        -- Bounded: the engine picks a shell outfit id per call, so an unbounded
        -- set would grow the persisted diagnostics every session.
        return false
    end
    ledger.shellOutfitIds[key] = true
    persist(ledger)
    noteIncrement("HuskLedger.ShellOutfitsLearned")
    return true
end

-- A carrier id is a stricter subset of shell ids. Legacy Naked ids remain in
-- shellOutfitIds for positional husk matching, but they must never become a
-- global startup signature because vanilla bathroom zombies can share them.
function Lifecycle.NoteShellCarrierID(outfitID)
    local ledger
    local key
    if not validEngineIdentity(outfitID) then
        return false
    end
    ledger = ensureLoaded()
    key = tostring(outfitID)
    if key == "" or ledger.shellCarrierIds[key] == true then
        return false
    end
    -- The legacy shell-outfit set may already be full. Carrier ids are a
    -- separate, stronger namespace and must still be learnable; otherwise an
    -- old save permanently prevents the new durable PNCShellCarrier path.
    if Lifecycle.ShellCarrierCount()
        >= (tonumber(Const.HUSK_LEDGER_MAX_SHELL_CARRIERS)
            or tonumber(Const.HUSK_LEDGER_MAX_SHELL_OUTFITS)
            or 32)
    then
        return false
    end
    ledger.shellCarrierIds[key] = true
    if not ledger.shellOutfitIds[key]
        and Lifecycle.ShellOutfitCount()
            < (tonumber(Const.HUSK_LEDGER_MAX_SHELL_OUTFITS) or 32)
    then
        ledger.shellOutfitIds[key] = true
    end
    persist(ledger)
    noteIncrement("HuskLedger.ShellCarriersLearned")
    if Core and Core.LogInfo then
        pcall(Core.LogInfo, "PNC shell_carrier_learned outfitID=" .. key
            .. " carrierCount=" .. tostring(Lifecycle.ShellCarrierCount()))
    end
    return true
end

function Lifecycle.IsShellOutfitID(outfitID)
    local ledger
    if not validEngineIdentity(outfitID) then
        return false
    end
    ledger = ensureLoaded()
    return ledger.shellOutfitIds[tostring(outfitID)] == true
end

function Lifecycle.IsShellCarrierID(outfitID)
    local ledger
    if not validEngineIdentity(outfitID) then
        return false
    end
    ledger = ensureLoaded()
    return ledger.shellCarrierIds[tostring(outfitID)] == true
end

function Lifecycle.ShellOutfitCount()
    local ledger = ensureLoaded()
    local count = 0
    local _ = nil
    for _ in pairs(ledger.shellOutfitIds) do
        count = count + 1
    end
    return count
end

function Lifecycle.ShellCarrierCount()
    local ledger = ensureLoaded()
    local count = 0
    local _ = nil
    for _ in pairs(ledger.shellCarrierIds) do
        count = count + 1
    end
    return count
end

--[[
    Positive-only fallback for a restored shell whose ledger callback was
    missed. An unmarked zombie is not proof of PNC ownership: ordinary zombies
    can already exist in a save even when the current spawn setting is zero.
    The only anonymous fallback we trust is a persistent outfit id previously
    learned from a body PNC actually stamped with PNCShellCarrier. Legacy Naked
    bodies remain on the strict ledger/position migration path.
]]
function Lifecycle.IsOrphanedShell(zombie)
    local ownership
    local ok
    local value
    local outfitID
    if not zombie then
        return false
    end
    if zombie.isDead then
        ok, value = pcall(zombie.isDead, zombie)
        if ok and value == true then
            return false
        end
    end
    if zombie.isReanimatedPlayer then
        ok, value = pcall(zombie.isReanimatedPlayer, zombie)
        if ok and value == true then
            return false
        end
    end
    ownership = PNC.Compatibility and PNC.Compatibility.ActorOwnership
    if ownership and ownership.IsForeignOwned then
        ok, value = pcall(ownership.IsForeignOwned, zombie)
        if ok and value == true then
            return false
        end
    end
    if not zombie.getPersistentOutfitID
        or not Lifecycle.IsShellCarrierID
    then
        return false
    end
    ok, outfitID = pcall(zombie.getPersistentOutfitID, zombie)
    if not ok or not validEngineIdentity(outfitID) then
        return false
    end
    return Lifecycle.IsShellCarrierID(outfitID) == true
end

return Lifecycle
