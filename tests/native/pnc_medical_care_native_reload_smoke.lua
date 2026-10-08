-- Target-owned native medical-care restart fixture, phase two.
-- Read synthetic non-player care state after a fresh JVM loads ModData.

local PATIENT_ID = "npc_pzharness_medical_restart"
local TASK_ID = "medical:1"
local MARKER = "medical-care-restart"

PZHarnessNativeTest = function()
    local repository = PNC and PNC.MedicalCareRepository or nil
    PZHarness.assertTrue(
        repository and repository.Get and repository.Loaded == true
            and repository.State and repository.State.byId,
        "native MedicalCareRepository was not loaded after the JVM restart"
    )
    PZHarness.assertTrue(
        repository.MODDATA_KEY,
        "native MedicalCareRepository ModData key was not available after restart"
    )

    local task = repository.Get(TASK_ID)
    PZHarness.assertTrue(
        type(task) == "table",
        "native MedicalCareRepository did not reload the written task"
    )
    PZHarness.assertEqual(
        task and task.id,
        TASK_ID,
        "native medical task identity did not survive the JVM restart"
    )
    PZHarness.assertEqual(
        task and task.patientId,
        PATIENT_ID,
        "native medical task patient identity did not survive restart"
    )
    PZHarness.assertEqual(
        task and task.status,
        "WAITING_FOR_DOCTOR",
        "native medical task transient status was not recovered"
    )
    PZHarness.assertEqual(
        task and task.phase,
        "WAITING_FOR_DOCTOR",
        "native medical task phase was not recovered"
    )
    PZHarness.assertEqual(
        task and task.actorId,
        nil,
        "native medical task actor lease was not cleared"
    )
    PZHarness.assertEqual(
        task and task.reservationId,
        nil,
        "native medical task reservation was not cleared"
    )
    PZHarness.assertEqual(
        task and task.blockedReason,
        "RECOVERED_AFTER_LOAD",
        "native medical task recovery reason was not retained"
    )
    PZHarness.assertEqual(
        task and task.sourceRef,
        MARKER,
        "native medical task source marker did not survive restart"
    )
    PZHarness.assertTrue(
        task and #task.woundParts == 2
            and task.woundParts[1] == "arm"
            and task.woundParts[2] == "leg",
        "native medical task wound state did not survive restart"
    )
    PZHarness.assertEqual(
        repository.State.nextId,
        2,
        "native MedicalCareRepository next ID state did not survive restart"
    )

    local raw = ModData.get(repository.MODDATA_KEY)
    local rawTask = raw and raw.byId and raw.byId[TASK_ID]
    PZHarness.assertTrue(
        type(rawTask) == "table"
            and rawTask.id == TASK_ID
            and rawTask.patientId == PATIENT_ID
            and rawTask.status == "WAITING_FOR_DOCTOR",
        "native medical ModData was not reloaded"
    )
end
