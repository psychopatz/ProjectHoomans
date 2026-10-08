-- Target-owned native acceptance fixture.
-- Run through pz-headless's development bridge; these assertions only verify
-- the real server composition boundary and do not replace gameplay behavior.

PZHarnessNativeTest = function()
    PZHarness.assertTrue(
        type(PNC) == "table",
        "Project Hoomans did not install the PNC root namespace"
    )
    PZHarness.assertTrue(
        type(PNC.Server) == "table"
            and type(PNC.Server.Internal) == "table"
            and type(PNC.Server.Internal.OnServerStarted) == "function",
        "Project Hoomans server lifecycle boundary was not installed"
    )
    PZHarness.assertTrue(
        type(PNC.ServerInventory) == "table"
            and type(PNC.ServerInventory.SemanticTransferNPCToPlayer) == "function",
        "Project Hoomans server inventory boundary was not installed"
    )
end
