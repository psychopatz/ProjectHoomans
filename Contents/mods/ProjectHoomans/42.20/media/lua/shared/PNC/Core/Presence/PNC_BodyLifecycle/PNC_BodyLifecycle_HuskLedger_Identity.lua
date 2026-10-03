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

--[[
    PNC shell outfit identity.

    Every live shell is dressed with the persistent outfit "Naked", and the
    engine stores the persistent outfit id in the anonymous population record
    that a virtualized shell becomes. That id therefore survives where ModData
    does not, which makes it the one durable hint that a body is (or was) a PNC
    shell.

    The ids are LEARNED from shells PNC actually creates and persisted, so this
    never depends on the outfit script name or on a Lua-side outfit lookup.

    This is deliberately NOT used as a global husk rule: vanilla also dresses
    bathroom zombies with the "Naked" outfit, so matching on the outfit alone
    would delete ordinary zombies. It is only trusted in worlds that cannot
    legitimately contain vanilla zombies at all (zombie spawning disabled), plus
    the strict ledger path everywhere else.
]]
function Lifecycle.NoteShellOutfitID(outfitID)
    local ledger
    local key
    if outfitID == nil then
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

function Lifecycle.IsShellOutfitID(outfitID)
    local ledger
    if outfitID == nil then
        return false
    end
    ledger = ensureLoaded()
    return ledger.shellOutfitIds[tostring(outfitID)] == true
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

--[[
    Simple orphan rule for worlds that cannot spawn vanilla zombies.

    When `IsoWorld.getZombiesDisabled()` is true the engine creates no zombies
    at all: every gate (IsoChunk, the population manager, addZombiesInOutfit)
    is shut. Any body in such a world that carries no PNC ModData and is not
    owned by a foreign mod can therefore only be a shell PNC lost - the
    population manager handed a virtualized NPC body back without its ModData.

    That makes the reclaim independent of the persistent outfit id (which a
    Lua-created body cannot set in a disabled world) and independent of any
    recorded loss position: it just deletes the orphan.

    In a normal-population world this is false and the strict ledger path stays
    in force, because vanilla dresses bathroom zombies with the same "Naked"
    outfit that PNC uses.
]]
function Lifecycle.IsOrphanedShell(zombie)
    local ownership
    local ok
    local value
    if not zombie then
        return false
    end
    if not (Lifecycle.AreZombieSpawnsDisabled
        and Lifecycle.AreZombieSpawnsDisabled() == true)
    then
        return false
    end
    -- A reanimated player is a vanilla body that may exist in any world.
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
    return true
end

return Lifecycle
