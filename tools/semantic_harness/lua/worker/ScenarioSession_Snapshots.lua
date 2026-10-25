-- Snapshot and bounded mutation response entry points.

local function install(ScenarioSession)
    local Internal = ScenarioSession.Internal

    function ScenarioSession.snapshot(context)
        return Internal.SnapshotPayload(context)
    end

    -- Mutating worker commands need the authoritative working-world projection
    -- so the host can synchronize its detached fixture. They do not resend the
    -- full diagnostics transcript, module manifest, graph, or transport history.
    function ScenarioSession.mutationProjection(context)
        return Internal.MutationPayload(context)
    end
end

return install
