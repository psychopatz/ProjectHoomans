-- Puppet Opera read-only and inspection request actions.
--
-- Preflight, snapshots, and traces stay separate from session mutation so
-- transport routing can keep their response contracts explicit.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}

local Opera = PNC.PuppetOpera
local Authority = Opera.Authority or {}
Opera.Authority = Authority
local Internal = Authority.Internal or {}
Authority.Internal = Internal
local Const = Internal.Const or PNC.Const or {}

local function handleReadonlyAction(player, session, args, action, ownerID)
    local accepted
    local reason
    if action == "preflight" then
        local preflight
        preflight, reason = Internal.buildPreflight(player, args)
        if not preflight then
            Internal.sendError(player, reason, session)
            return true, false, reason, true
        end
        Internal.sendToClient(player, Const.CMD_PUPPET_OPERA_STATE, {
            phase = session and session.phase
                or (preflight.ready and "ready" or "blocked"),
            blueprintId = preflight.blueprintId,
            preflight = preflight,
        })
        return true, true, { preflight = preflight }, true
    end
    if action == "snapshot" then
        if session then
            Internal.sendState(session, false)
        else
            Internal.sendToClient(player, Const.CMD_PUPPET_OPERA_STATE, {
                phase = "idle",
                blueprints = Opera.ListBlueprints(),
                lastSnapshot = Authority.LastSnapshots[ownerID],
            })
        end
        return true, true, "snapshot_sent", true
    end
    if action == "dump_trace" then
        if not session then
            local last = Authority.LastSnapshots[ownerID]
            if last then
                Internal.sendToClient(player, Const.CMD_PUPPET_OPERA_TRACE, last)
            else
                Internal.sendToClient(
                    player,
                    Const.CMD_PUPPET_OPERA_TRACE,
                    { trace = {} }
                )
            end
            return true, true, "trace_sent", true
        end
        accepted, reason = Internal.ownsRequest(session, player, args)
        if not accepted then return true, false, reason, true end
        Internal.sendToClient(
            player,
            Const.CMD_PUPPET_OPERA_TRACE,
            Opera.BuildSnapshot(session, true)
        )
        return true, true, "trace_sent", true
    end
    return false
end

Internal.handleReadonlyAction = handleReadonlyAction

return Authority

