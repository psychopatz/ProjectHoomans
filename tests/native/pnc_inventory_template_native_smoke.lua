-- Target-owned native behavior fixture.
-- Run through pz-headless's development bridge against the real server and
-- production Project Hoomans/PsychopatzCore/MarketSense Lua closure.

PZHarnessNativeTest = function()
    local record = {
        id = "native:template:smoke",
        name = "Native Template NPC",
        identitySeed = 4242,
        archetypeID = "Scavenger",
        tacticalClass = "hostile",
        equipmentPoolID = "Default",
        equipmentSpawnMode = "none",
        runtime = {},
        equipment = { worn = {}, attached = {} },
    }

    local inventory = PNC.Inventory.CreateFromTemplate(record, {
        reconcileWaterContainer = false,
    })
    PZHarness.assertEqual(
        inventory,
        record.inventory,
        "template generation installs the generated inventory on the record"
    )
    PZHarness.assertEqual(
        inventory.persistenceMode,
        "SEED_ONLY",
        "generated inventory uses the seed-only persistence mode"
    )
    PZHarness.assertEqual(
        inventory.revision,
        0,
        "initial generated inventory starts at revision zero"
    )
    PZHarness.assertEqual(
        inventory.template.archetypeID,
        "Scavenger",
        "generated template preserves the target archetype"
    )

    local payload = PNC.Inventory.BuildFullPayload(record)
    PZHarness.assertEqual(
        payload.identityMetadata.npcId,
        record.id,
        "full payload preserves the stable NPC identity"
    )
    PZHarness.assertEqual(
        payload.identityMetadata.displayName,
        record.name,
        "full payload preserves the NPC display name"
    )
    PZHarness.assertEqual(
        payload.summary.revision,
        inventory.revision,
        "full payload summary uses the generated inventory revision"
    )
    PZHarness.assertTrue(
        type(payload.items) == "table"
            and (payload.summary.itemCount or 0) > 0,
        "full payload contains generated target inventory items"
    )
end
