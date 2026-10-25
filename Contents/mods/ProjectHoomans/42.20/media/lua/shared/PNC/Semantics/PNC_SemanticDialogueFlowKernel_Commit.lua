-- Flow session commit and lifecycle mutation.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Kernel = PNC.Semantics.DialogueFlowKernel
local Internal = Kernel.Internal
local Registry = Internal.Registry
local copyValue = Internal.CopyValue
local contextStateFor = Internal.ContextStateFor
local readSession = Internal.ReadSession
local storeSession = Internal.StoreSession
local removeSession = Internal.RemoveSession
local sequenceFor = Internal.SequenceFor
local nodeFor = Internal.NodeFor
local setPending = Internal.SetPending
local completePendingFor = Internal.CompletePendingFor

local function newSession(preview, sequence)
    return {
        key = preview.key,
        speakerID = preview.speakerID,
        addresseeID = preview.addresseeID,
        active = {
            flowId = preview.flowId,
            nodeId = preview.toNodeId,
            slots = {},
            startedAt = sequence,
            lastSequence = sequence,
        },
        suspended = {},
        revision = 1,
        lastTransition = preview.transition,
    }
end

local function pushActive(session, maximum)
    if not session.active then return end
    session.suspended = session.suspended or {}
    session.suspended[#session.suspended + 1] = copyValue(session.active)
    while #session.suspended > maximum do table.remove(session.suspended, 1) end
end

local function completeActive(session, preview)
    local completed = session.active and session.active.flowId or nil
    session.active = nil
    session.completedFlowId = completed
    if preview.suspendedIndex then
        table.remove(session.suspended, preview.suspendedIndex)
    end
    if not session.active and #session.suspended > 0 then
        session.active = table.remove(session.suspended)
        session.resumedFlowId = session.active.flowId
    end
end

function Kernel.Commit(preview, ir, state, context, options)
    options = type(options) == "table" and options or {}
    if type(preview) ~= "table"
        or preview.kind ~= "semantic_dialogue_flow_preview"
    then
        return nil, "invalid_flow_preview"
    end
    local storage = contextStateFor(state, context)
    if not storage then return nil, "flow_state_unavailable" end
    local sequence = sequenceFor(state, storage)
    local session = readSession(storage, preview.key)
    local maximum = tonumber(
        storage.maxFlowStack or options.maxFlowStack
    ) or Kernel.DEFAULT_MAX_STACK
    local result = copyValue(preview)
    result.committed = true
    result.commitSequence = sequence

    if preview.transition == "hold" then
        result.status = "held"
        return result
    end

    if preview.transition == "start"
        or preview.transition == "interrupt_start"
    then
        local previewFlow = Registry.Get(preview.flowId)
        local previewNode = previewFlow
            and nodeFor(previewFlow, preview.toNodeId) or nil
        if previewNode and previewNode.terminal then
            if session and preview.transition == "interrupt_start" then
                -- A terminal response-only flow still interrupts the active
                -- conversation topic. Preserve the active flow as suspended
                -- so the next compatible turn can resume it.
                pushActive(session, maximum)
                session.active = nil
                session.lastTransition = preview.transition
                session.revision = (tonumber(session.revision) or 0) + 1
                storeSession(storage, session)
                result.status = "retired"
                result.active = nil
                result.suspended = copyValue(session.suspended)
                return result
            end
            -- A terminal gated branch is a response-only route. It must not
            -- create or interrupt a longer-lived flow session.
            result.status = "retired"
            result.active = session and copyValue(session.active) or nil
            result.suspended = session and copyValue(session.suspended) or {}
            return result
        end
        if not session then
            session = newSession(preview, sequence)
        elseif preview.transition == "interrupt_start" then
            pushActive(session, maximum)
            session.active = {
                flowId = preview.flowId,
                nodeId = preview.toNodeId,
                slots = {},
                startedAt = sequence,
                lastSequence = sequence,
            }
            session.revision = (tonumber(session.revision) or 0) + 1
        else
            session.active = session.active or {
                flowId = preview.flowId,
                nodeId = preview.toNodeId,
                slots = {},
                startedAt = sequence,
            }
            session.active.nodeId = preview.toNodeId
            session.active.lastSequence = sequence
        end
        session.lastTransition = preview.transition
        setPending(storage, preview)
        storeSession(storage, session)
        result.status = "started"
        result.active = copyValue(session.active)
        result.suspended = copyValue(session.suspended)
        return result
    end

    if not session then
        result.committed = false
        result.status = "stale_flow_session"
        return result
    end

    if preview.transition == "resume_match" and preview.suspendedIndex then
        local resumed = table.remove(session.suspended, preview.suspendedIndex)
        -- The resumed entry is already removed from the suspended stack. Keep
        -- the preview index only as diagnostic evidence; do not let the
        -- completion path remove a second stack entry.
        local completionPreview = copyValue(preview)
        completionPreview.suspendedIndex = nil
        if resumed then
            if session.active then
                session.suspended[#session.suspended + 1] = session.active
                while #session.suspended > maximum do
                    table.remove(session.suspended, 1)
                end
            end
            session.active = resumed
        end
        preview = completionPreview
    end

    if preview.transition == "cancel" then
        completeActive(session, preview)
        completePendingFor(storage, preview.flowId, "flow_cancelled")
    elseif session.active then
        session.active.nodeId = preview.toNodeId
        session.active.lastSequence = sequence
        session.active.slots = session.active.slots or {}
        for name, value in pairs(preview.slotValues or {}) do
            session.active.slots[name] = copyValue(value)
        end
        local flow = Registry.Get(session.active.flowId)
        local node = flow and nodeFor(flow, session.active.nodeId)
        if preview.toNodeId == "complete"
            or preview.toNodeId == "cancel"
            or node and node.terminal == true
        then
            completeActive(session, preview)
            completePendingFor(storage, preview.flowId, "flow_transition")
        end
    end

    setPending(storage, preview)

    session.lastTransition = preview.transition
    if session.active or #session.suspended > 0 then
        session.revision = (tonumber(session.revision) or 0) + 1
        storeSession(storage, session)
        result.status = "advanced"
        result.active = copyValue(session.active)
        result.suspended = copyValue(session.suspended)
    else
        removeSession(storage, preview.key)
        result.status = "retired"
        result.active = nil
        result.suspended = {}
    end
    return result
end

Internal.CompleteActive = completeActive

return Kernel
