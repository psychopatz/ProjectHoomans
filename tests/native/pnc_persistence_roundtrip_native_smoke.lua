-- Target-owned native persistence acceptance fixture.
-- Exercise the production record serializer/deserializer on the real server;
-- this intentionally stops before ModData, save/restart, or network transfer.

PZHarnessNativeTest = function()
    local record = {
        id = "native:persistence:roundtrip",
        name = "Native Persistence NPC",
        identitySeed = 4242,
        archetypeID = "Scavenger",
        tacticalClass = "hostile",
        x = 14,
        y = 22,
        z = 0,
        health = {
            current = 73,
            max = 100,
            state = "normal",
        },
        identity = {
            seed = 4242,
            archetypeID = "Scavenger",
            displayName = "Native Persistence NPC",
        },
        equipmentPoolID = "Default",
        equipmentSpawnMode = "none",
        equipment = { worn = {}, attached = {} },
        runtime = {
            transientMarker = "must-not-persist",
        },
    }

    local inventoryRevision = 3
    record.persistedInventory = {
        2,
        "SEED_ONLY",
        inventoryRevision,
        {
            archetypeID = record.archetypeID,
            seed = record.identitySeed,
            generatorVersion = PNC.Const.GENERATOR_VERSION,
            equipmentPoolID = record.equipmentPoolID,
            weaponMode = "melee",
        },
    }
    record.recordRevision = 7
    local sourceRevision = record.recordRevision
    local persisted = PNC.Persistence.SerializeRecord(record)

    PZHarness.assertTrue(
        type(persisted) == "table",
        "production persistence serializer returned no payload"
    )
    PZHarness.assertEqual(
        persisted.schemaVersion,
        PNC.Const.PERSISTENCE_VERSION,
        "record persistence schema version was not emitted"
    )
    PZHarness.assertEqual(
        7,
        sourceRevision,
        "fixture source record revision was not established"
    )
    PZHarness.assertEqual(
        persisted.recordRevision,
        sourceRevision,
        "record revision was not serialized"
    )
    PZHarness.assertEqual(
        persisted.id,
        record.id,
        "serialized record identity changed"
    )
    PZHarness.assertEqual(
        persisted.inventory[1],
        2,
        "serialized inventory schema changed"
    )
    PZHarness.assertTrue(
        persisted.inventory[2] == "SEED_ONLY"
            or persisted.inventory[2] == "BASELINE_DELTA",
        "serialized inventory mode was not a compact production mode"
    )
    PZHarness.assertEqual(
        persisted.inventory[3],
        inventoryRevision,
        "serialized inventory revision changed"
    )
    PZHarness.assertEqual(
        persisted.inventory[4].archetypeID,
        record.archetypeID,
        "serialized inventory baseline lost archetype identity"
    )
    PZHarness.assertEqual(
        persisted.inventory[4].seed,
        record.identitySeed,
        "serialized inventory baseline lost identity seed"
    )
    PZHarness.assertEqual(
        persisted.runtime,
        nil,
        "runtime-only state leaked into the persisted record"
    )

    local restored = PNC.Persistence.DeserializeRecord(persisted, record.id)
    PZHarness.assertTrue(
        type(restored) == "table",
        "production persistence deserializer returned no record"
    )
    PZHarness.assertEqual(
        restored.id,
        record.id,
        "deserialized record identity changed"
    )
    PZHarness.assertEqual(
        restored.name,
        record.name,
        "deserialized display identity changed"
    )
    PZHarness.assertEqual(
        restored.identitySeed,
        record.identitySeed,
        "deserialized identity seed changed"
    )
    PZHarness.assertEqual(
        restored.identity.archetypeID,
        record.archetypeID,
        "deserialized archetype identity changed"
    )
    PZHarness.assertEqual(
        restored.recordRevision,
        sourceRevision,
        "deserialized record revision changed"
    )
    PZHarness.assertEqual(
        restored.persistenceSourceVersion,
        PNC.Const.PERSISTENCE_VERSION,
        "deserialized source schema version changed"
    )
    PZHarness.assertEqual(
        restored.persistedInventory[1],
        persisted.inventory[1],
        "deserialized persisted inventory schema changed"
    )
    PZHarness.assertEqual(
        restored.persistedInventory[3],
        inventoryRevision,
        "deserialized persisted inventory revision changed"
    )
    PZHarness.assertEqual(
        restored.persistedInventory[4].seed,
        record.identitySeed,
        "deserialized persisted inventory identity changed"
    )
    PZHarness.assertEqual(
        restored.x,
        record.x,
        "deserialized position primitive changed"
    )
    PZHarness.assertEqual(
        restored.health.current,
        record.health.current,
        "deserialized health primitive changed"
    )
    PZHarness.assertEqual(
        restored.inventory,
        nil,
        "deserialization materialized transient physical inventory"
    )
    PZHarness.assertTrue(
        type(restored.runtime) == "table"
            and restored.runtime.transientMarker == nil,
        "deserialization retained a runtime-only marker"
    )
end
