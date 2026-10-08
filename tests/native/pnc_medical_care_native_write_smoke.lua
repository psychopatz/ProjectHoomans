-- Target-owned native medical-care restart fixture, phase one.
-- Exercise synthetic non-player care state without live actors or movement.

local PATIENT_ID = "npc_pzharness_medical_restart"
local MARKER = "medical-care-restart"

PZHarnessNativeTest = function()
    local repository = PNC and PNC.MedicalCareRepository or nil
    PZHarness.assertTrue(
        repository and repository.NextId and repository.Get
            and repository.Put and repository.Save and repository.Load,
        "native MedicalCareRepository API was not available"
    )
    PZHarness.assertTrue(
        repository and repository.Loaded == true
            and repository.State and repository.State.byId,
        "native MedicalCareRepository was not loaded before the test"
    )
    PZHarness.assertTrue(
        repository and repository.MODDATA_KEY,
        "native MedicalCareRepository ModData key was not available"
    )

    local taskID = repository.NextId()
    PZHarness.assertEqual(
        taskID,
        "medical:1",
        "native MedicalCareRepository did not generate the expected task ID"
    )
    local task = repository.Put({
        id = taskID,
        patientKind = "npc",
        patientId = PATIENT_ID,
        woundParts = { "arm", "arm", "leg" },
        currentWoundIndex = 2,
        severity = 73,
        priority = 9,
        source = "native_harness",
        sourceRef = MARKER,
        status = "TREATING",
        phase = "TREATING",
        actorId = "npc_pzharness_doctor",
        reservationId = "reservation-before-restart",
        revision = 4,
        createdAt = 42,
        updatedAt = 43,
        lastProgressAt = 43,
        policy = { allowNPC = true, requireItem = true },
    })
    PZHarness.assertTrue(
        type(task) == "table" and task.id == taskID,
        "native MedicalCareRepository did not retain the written task"
    )
    PZHarness.assertEqual(
        task.patientId,
        PATIENT_ID,
        "native medical task patient identity was not retained"
    )
    PZHarness.assertEqual(
        task.status,
        "TREATING",
        "native medical task status was not retained before save"
    )
    PZHarness.assertTrue(
        #task.woundParts == 2
            and task.woundParts[1] == "arm"
            and task.woundParts[2] == "leg",
        "native medical task wound normalization was not applied"
    )
    PZHarness.assertTrue(
        repository.Dirty == true,
        "native MedicalCareRepository did not retain its dirty state"
    )
    PZHarness.assertEqual(
        repository.State.nextId,
        2,
        "native MedicalCareRepository next ID state was not advanced"
    )

    PZHarness.assertTrue(
        PNC.PersistenceCoordinator
            and PNC.PersistenceCoordinator.Commit,
        "native persistence coordinator was not available"
    )
    local commitOK, committed, commitReason, commitDetails = pcall(
        PNC.PersistenceCoordinator.Commit,
        "native_harness_medical_care_restart"
    )
    PZHarness.assertTrue(
        commitOK and committed,
        "native medical-care commit failed: "
            .. tostring(commitReason or committed)
    )
    local medicalResult = commitDetails
        and commitDetails.results
        and commitDetails.results.medicalCare
    PZHarness.assertTrue(
        medicalResult and medicalResult.changed == true,
        "native persistence coordinator did not save MedicalCareRepository"
    )
    PZHarness.assertTrue(
        repository.Dirty == false,
        "native MedicalCareRepository remained dirty after commit"
    )

    local raw = ModData.get(repository.MODDATA_KEY)
    local rawTask = raw and raw.byId and raw.byId[taskID]
    PZHarness.assertTrue(
        type(rawTask) == "table"
            and rawTask.id == taskID
            and rawTask.patientId == PATIENT_ID
            and rawTask.status == "WAITING_FOR_DOCTOR"
            and rawTask.actorId == nil
            and rawTask.reservationId == nil
            and rawTask.blockedReason == "RECOVERED_AFTER_LOAD",
        "native medical ModData did not contain recovered task state"
    )

    PZHarness.assertTrue(
        Events and Events.OnSave and Events.OnSave.Add,
        "native medical-care OnSave event was not available"
    )
    local onSaveObserved = false
    if Events and Events.OnSave and Events.OnSave.Add then
        Events.OnSave.Add(function()
            onSaveObserved = true
            print("PZ_HARNESS_MEDICAL_CARE_WRITE_ON_SAVE:" .. taskID)
        end)
    end

    local saveAvailable = GameWindow and GameWindow.save ~= nil
    PZHarness.assertTrue(
        saveAvailable,
        "native medical-care GameWindow.save path was not available"
    )
    if saveAvailable then
        local saveOK, saveError = pcall(GameWindow.save, true)
        PZHarness.assertTrue(
            saveOK,
            "native medical-care GameWindow.save failed: " .. tostring(saveError)
        )
        PZHarness.assertTrue(
            onSaveObserved,
            "native medical-care GameWindow.save did not trigger OnSave"
        )
    end
end
