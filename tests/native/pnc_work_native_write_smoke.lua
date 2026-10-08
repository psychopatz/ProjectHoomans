-- Target-owned native work-repository restart fixture, phase one.
-- Exercise the global work-order repository through the commit coordinator.

local ORDER_OPERATION = "CRAFT"
local ORDER_STATUS = "QUEUED"
local MARKER = "work-restart"

PZHarnessNativeTest = function()
    local repository = PNC and PNC.WorkRepository or nil
    PZHarness.assertTrue(
        repository and repository.NextId and repository.Get
            and repository.Put and repository.Save and repository.Load,
        "native WorkRepository API was not available"
    )
    PZHarness.assertTrue(
        repository and repository.Loaded == true
            and repository.State and repository.State.byId,
        "native WorkRepository was not loaded before the test"
    )
    PZHarness.assertTrue(
        repository and repository.MODDATA_KEY,
        "native WorkRepository ModData key was not available"
    )

    local orderID = repository.NextId()
    PZHarness.assertEqual(
        orderID,
        "work:1",
        "native WorkRepository did not generate the expected order ID"
    )
    local order = {
        id = orderID,
        operation = ORDER_OPERATION,
        status = ORDER_STATUS,
        revision = 3,
        progress = 12,
        requiredWork = 80,
        nativeMarker = MARKER,
        payload = {
            recipe = "native_harness_work_order",
            input = { funded = false, committed = false },
        },
    }
    local stored = repository.Put(order)
    PZHarness.assertTrue(
        stored == order and repository.Get(orderID) == order,
        "native WorkRepository did not retain the written order"
    )
    PZHarness.assertTrue(
        repository.Dirty == true,
        "native WorkRepository did not retain its dirty state"
    )
    PZHarness.assertEqual(
        repository.State.nextId,
        2,
        "native WorkRepository next ID state was not advanced"
    )

    PZHarness.assertTrue(
        PNC.PersistenceCoordinator
            and PNC.PersistenceCoordinator.Commit,
        "native persistence coordinator was not available"
    )
    local commitOK, committed, commitReason, commitDetails = pcall(
        PNC.PersistenceCoordinator.Commit,
        "native_harness_work_restart"
    )
    PZHarness.assertTrue(
        commitOK and committed,
        "native work commit failed: "
            .. tostring(commitReason or committed)
    )
    local workResult = commitDetails
        and commitDetails.results
        and commitDetails.results.work
    PZHarness.assertTrue(
        workResult and workResult.changed == true,
        "native persistence coordinator did not save WorkRepository"
    )
    PZHarness.assertTrue(
        repository.Dirty == false,
        "native WorkRepository remained dirty after commit"
    )

    local raw = ModData.get(repository.MODDATA_KEY)
    local rawOrder = raw and raw.byId and raw.byId[orderID]
    PZHarness.assertTrue(
        type(rawOrder) == "table"
            and rawOrder.id == orderID
            and rawOrder.operation == ORDER_OPERATION
            and rawOrder.nativeMarker == MARKER,
        "native work ModData did not contain the committed order"
    )

    PZHarness.assertTrue(
        Events and Events.OnSave and Events.OnSave.Add,
        "native work OnSave event was not available"
    )
    local onSaveObserved = false
    if Events and Events.OnSave and Events.OnSave.Add then
        Events.OnSave.Add(function()
            onSaveObserved = true
            print("PZ_HARNESS_WORK_WRITE_ON_SAVE:" .. orderID)
        end)
    end

    local saveAvailable = GameWindow and GameWindow.save ~= nil
    PZHarness.assertTrue(
        saveAvailable,
        "native work GameWindow.save path was not available"
    )
    if saveAvailable then
        local saveOK, saveError = pcall(GameWindow.save, true)
        PZHarness.assertTrue(
            saveOK,
            "native work GameWindow.save failed: " .. tostring(saveError)
        )
        PZHarness.assertTrue(
            onSaveObserved,
            "native work GameWindow.save did not trigger OnSave"
        )
    end
end
