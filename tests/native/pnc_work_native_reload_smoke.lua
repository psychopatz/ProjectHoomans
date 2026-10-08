-- Target-owned native work-repository restart fixture, phase two.
-- Read the global work-order repository after a fresh JVM loads ModData.

local ORDER_ID = "work:1"
local ORDER_OPERATION = "CRAFT"
local ORDER_STATUS = "QUEUED"
local MARKER = "work-restart"

PZHarnessNativeTest = function()
    local repository = PNC and PNC.WorkRepository or nil
    PZHarness.assertTrue(
        repository and repository.Get and repository.Loaded == true
            and repository.State and repository.State.byId,
        "native WorkRepository was not loaded after the JVM restart"
    )
    PZHarness.assertTrue(
        repository.MODDATA_KEY,
        "native WorkRepository ModData key was not available after restart"
    )

    local order = repository.Get(ORDER_ID)
    PZHarness.assertTrue(
        type(order) == "table",
        "native WorkRepository did not reload the written order"
    )
    PZHarness.assertEqual(
        order and order.id,
        ORDER_ID,
        "native work order identity did not survive the JVM restart"
    )
    PZHarness.assertEqual(
        order and order.operation,
        ORDER_OPERATION,
        "native work order operation did not survive the JVM restart"
    )
    PZHarness.assertEqual(
        order and order.status,
        ORDER_STATUS,
        "native work order status did not survive the JVM restart"
    )
    PZHarness.assertEqual(
        order and order.nativeMarker,
        MARKER,
        "native work order marker did not survive the JVM restart"
    )
    PZHarness.assertEqual(
        order and order.revision,
        3,
        "native work order revision did not survive the JVM restart"
    )
    PZHarness.assertEqual(
        order and order.progress,
        12,
        "native work order progress did not survive the JVM restart"
    )
    PZHarness.assertEqual(
        order and order.requiredWork,
        80,
        "native work order required work did not survive the JVM restart"
    )
    PZHarness.assertEqual(
        repository.State.nextId,
        2,
        "native WorkRepository next ID state did not survive the restart"
    )

    local raw = ModData.get(repository.MODDATA_KEY)
    local rawOrder = raw and raw.byId and raw.byId[ORDER_ID]
    PZHarness.assertTrue(
        type(rawOrder) == "table"
            and rawOrder.id == ORDER_ID
            and rawOrder.nativeMarker == MARKER,
        "native work ModData was not reloaded"
    )
end
