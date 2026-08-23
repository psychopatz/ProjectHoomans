local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
local Core = PNC.Core
local Const = PNC.Const

local function notifyBodyRemoval(record, zombie, reason)
    local network = PNC.Network
    if network and network.BroadcastBodyRemoval then
        network.BroadcastBodyRemoval(
            record and record.id or nil,
            Internal.GetStartupBodyInstanceID(zombie),
            Internal.normalizeOnlineID(zombie),
            reason
        )
    end
end

local function removeShell(record, zombie, reason)
    local now = Core.Now()
    local id = record and record.id or nil
    local instanceID = Internal.GetStartupBodyInstanceID(zombie)
    local reg
    if PNC.LiveBodyControl and PNC.LiveBodyControl.ApplyHumanizedBodyFlags then
        -- Positional legacy shells may have lost every PNC marker, so the
        -- managed-only safety predicate cannot recognize them yet. Apply the
        -- harmless body flags directly before removal: no teeth, no target,
        -- useless, and no lunge are effective immediately.
        PNC.LiveBodyControl.ApplyHumanizedBodyFlags(zombie)
        if PNC.LiveBodyControl.SuppressZombieSounds then
            PNC.LiveBodyControl.SuppressZombieSounds(zombie)
        end
    else
        Internal.clearBodyCombat(zombie)
    end
    notifyBodyRemoval(record, zombie, reason)
    Internal.removeZombie(zombie)
    if record then
        record.runtime = record.runtime or {}
        record.runtime.materializeRetryAt = now
            + (tonumber(Const.BODY_SHELL_RESPAWN_DELAY_MS) or 50)
        record.runtime.startupBodyHint = nil
        reg = Internal.registry()
        if reg and reg.LiveByID
            and reg.LiveByID[tostring(record.id)] == zombie
        then
            Internal.detachLiveBody(record, reason)
        end
        Internal.noteCleanup(record, "stale_cleaned", reason)
        Internal.mark(
            record,
            record.presenceState or Const.PRESENCE_ABSTRACT,
            "stale_cleaned",
            reason
        )
    end
    Core.LogWarn("PNC persisted_shell_repaired npc=" .. tostring(id or "orphan")
        .. " bodyInstanceID=" .. tostring(instanceID or "nil")
        .. " reason=" .. tostring(reason))
    return true
end

Internal.NotifyStartupBodyRemoval = notifyBodyRemoval
Internal.RemoveStartupShell = removeShell
