-- One bounded, target-owned scenario for the headless harness marker protocol.
-- It exercises the real Hoomans profiler-content scan with a disposable record.

PZHarnessNativeTest = function()
    PZHarness.assertTrue(
        type(PZHarnessMarkers) == "table"
            and type(PZHarnessMarkers.measure) == "function",
        "explicit subsystem marker profiling was not enabled"
    )
    if type(PZHarnessMarkers) ~= "table" then return end

    local registry = PNC and PNC.Registry or nil
    PZHarness.assertTrue(
        type(registry) == "table" and type(registry.Data) == "table",
        "Project Hoomans NPC registry is not available"
    )
    if type(registry) ~= "table" or type(registry.Data) ~= "table" then return end

    local content = require "PNC/Integrations/PNC_PsychopatzModDataContent"
    local probe_id = "pzh_profile_marker_probe"
    local previous = registry.Data[probe_id]
    registry.Data[probe_id] = {
        name = "Headless profiler marker probe",
        tacticalClass = "profile_probe",
        presenceState = "live",
        inventory = {
            items = { probe_item = true },
            worn = {},
            equipped = {},
            attached = {},
            containers = {},
        },
    }

    local scan_options = { scope = "selected", ids = { probe_id } }
    local scan_ok, scan = pcall(function()
        local result = nil
        for _ = 1, 12 do
            result = PZHarnessMarkers.measure(
                "PNC.ModDataProfilerContent.Scan",
                function()
                    local last_scan = nil
                    for _ = 1, 32 do
                        last_scan = content.Scan(scan_options)
                    end
                    return last_scan
                end
            )
        end
        return result
    end)
    registry.Data[probe_id] = previous
    PZHarness.assertTrue(scan_ok, "Hoomans bounded profiler-content scan failed")
    if not scan_ok then return end
    PZHarness.assertEqual(scan.capturedRecords, 1, "one probe record was captured")
    PZHarness.assertEqual(scan.records[1].id, probe_id, "the probe record was selected")
    PZHarness.assertEqual(scan.records[1].inventoryItems, 1, "probe inventory was counted")

    local parent = PZHarnessMarkers.begin("PZHarness.MarkerProtocol.Parent")
    local child = PZHarnessMarkers.begin("PZHarness.MarkerProtocol.Child")
    PZHarness.assertTrue(parent ~= nil and child ~= nil, "nested markers did not start")
    PZHarnessMarkers.finish(parent)
    PZHarnessMarkers.finish(child)

    local snapshot = PZHarnessMarkers.snapshot()
    local scan_region = nil
    for _, region in ipairs(snapshot.regions) do
        if region.name == "PNC.ModDataProfilerContent.Scan" then
            scan_region = region
        end
    end
    PZHarness.assertTrue(scan_region ~= nil, "the target scan produced a timed region")
    if scan_region then
        PZHarness.assertEqual(scan_region.count, 12, "scan batches were aggregated")
        PZHarness.assertTrue(
            scan_region.total_ms > 0,
            "bounded scan batches produced a measurable elapsed duration"
        )
        PZHarness.assertTrue(
            scan_region.p95_ms >= 0 and scan_region.max_ms >= scan_region.p95_ms,
            "percentile and maximum timings were reported"
        )
    end
    PZHarness.assertEqual(
        snapshot.diagnostics.mismatched_end_count,
        1,
        "mismatched nested scopes were diagnosed and unwound"
    )
    PZHarness.assertEqual(
        snapshot.diagnostics.orphan_end_count,
        1,
        "a repeated close was diagnosed without failing the scenario"
    )
end
