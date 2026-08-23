PNC = PNC or {}
PNC.Equipment = PNC.Equipment or {}
PNC.Equipment.Internal = PNC.Equipment.Internal or {}

local Equipment = PNC.Equipment
local Internal = Equipment.Internal
local Core = PNC.Core
local Visuals = PNC.Visuals
local Inventory = PNC.Inventory

-- Remote multiplayer bodies are presentation replicas. Their real worn items
-- remain server-owned. ItemVisuals are repaired only when the synchronized
-- worn set is genuinely absent, mirroring Bandits' appearance latch.
function Internal.getItemVisualType(visual)
    local value
    if not visual then return nil end
    if visual.getItemType then
        value = visual:getItemType()
    end
    if (value == nil or value == "")
        and visual.getClothingItemName
    then
        value = visual:getClothingItemName()
    end
    return value ~= nil and tostring(value) or nil
end

function Internal.replicaPresentationSignature(equipment)
    local entries = Equipment.GetOrderedWornEntries(equipment)
    local wornVisuals = equipment.wornVisuals or {}
    local parts = {}
    local i
    for i = 1, #entries do
        parts[#parts + 1] = table.concat({
            tostring(entries[i].bodyLocation),
            Internal.visualStateSignature(
                wornVisuals[entries[i].bodyLocation]
                    or { fullType = entries[i].fullType }
            ),
        }, "=")
    end
    return table.concat(parts, "|")
end

function Equipment.ReplicaVisualsMatch(zombie, record)
    local equipment
    local entries
    local expected = {}
    local visuals
    local i
    local fullType
    if not zombie or not record then return false end
    equipment = Equipment.EnsureRecordEquipment(record)
    entries = Equipment.GetOrderedWornEntries(equipment)
    visuals = zombie.getItemVisuals
        and zombie:getItemVisuals() or nil
    if not visuals or not visuals.size or not visuals.get then
        return false
    end
    if visuals:size() ~= #entries then return false end
    for i = 1, #entries do
        fullType = tostring(entries[i].fullType)
        expected[fullType] = (expected[fullType] or 0) + 1
    end
    for i = 0, visuals:size() - 1 do
        fullType = Internal.getItemVisualType(visuals:get(i))
        if fullType and expected[fullType]
            and expected[fullType] > 0
        then
            expected[fullType] = expected[fullType] - 1
        end
    end
    for _, count in pairs(expected) do
        if count > 0 then return false end
    end
    return true
end

function Equipment.ApplyReplicaVisuals(zombie, record)
    local equipment
    local entries
    local wornVisuals
    local visuals
    local applied = 0
    local failed = 0
    local i
    local handsOk
    local handsReason
    local modData
    local desiredSignature
    local signatureCurrent
    if not zombie or not record then
        return false, "missing_body_or_record"
    end
    handsOk, handsReason =
        Equipment.ApplyReplicaHands(zombie, record)
    equipment = Equipment.EnsureRecordEquipment(record)
    desiredSignature = Internal.replicaPresentationSignature(equipment)
    modData = zombie.getModData and zombie:getModData() or nil
    signatureCurrent = not modData
        or modData.PNCReplicaVisualSignature == desiredSignature
    if signatureCurrent
        and Equipment.ReplicaVisualsMatch(zombie, record)
    then
        return handsOk,
            handsOk and "replica_current" or handsReason
    end
    entries = Equipment.GetOrderedWornEntries(equipment)
    wornVisuals = equipment.wornVisuals or {}
    visuals = zombie.getItemVisuals
        and zombie:getItemVisuals() or nil
    if not visuals or not visuals.clear then
        return false, "missing_item_visuals"
    end
    visuals:clear()
    for i = 1, #entries do
        if Visuals.AddClothingVisual(
            zombie,
            entries[i].fullType,
            wornVisuals[entries[i].bodyLocation]
        ) then
            applied = applied + 1
        else
            failed = failed + 1
        end
    end
    Visuals.RefreshModel(zombie)
    if failed == 0 and modData then
        modData.PNCReplicaVisualSignature = desiredSignature
    end
    return failed == 0 and handsOk,
        "replica_repaired:applied=" .. tostring(applied)
            .. ",failed=" .. tostring(failed)
end

Equipment.EnsureReplicaVisuals =
    Equipment.ApplyReplicaVisuals

function Equipment.ApplyReplicaHands(zombie, record)
    local equipment
    local descriptor
    local attackMode
    local handStateCurrent
    local attachedEntries
    local signatureParts
    local signature
    local modData
    local ok
    local attachedReason
    local handsReason
    local i
    if not zombie or not record then
        return false, "missing_body_or_record"
    end
    equipment = Equipment.EnsureRecordEquipment(record)
    attackMode = Internal.isAttackMode(record)
    descriptor = Internal.buildWeaponDescriptor(
        equipment.primaryFullType,
        false
    )
    Internal.setEquipmentVariables(
        zombie,
        descriptor.primaryType,
        descriptor.fullType,
        equipment.secondaryFullType
    )

    -- The server remains the authority for inventory and equipped slots. It
    -- publishes only the animation variables here; materializing InventoryItem
    -- instances on the server would compete with normal item packets.
    if isServer and isServer() == true then
        return true, "replica_variables_server"
    end

    if not equipment.primaryVisual
        and equipment.primaryFullType
        and Equipment.BuildPrimaryVisualSummary
    then
        Equipment.BuildPrimaryVisualSummary(record)
        equipment = Equipment.EnsureRecordEquipment(record)
    end

    -- Remote IsoZombie bodies do not receive a usable primary-hand item from
    -- our virtual inventory snapshots. Like Bandits, create that item locally
    -- for presentation. Latch the synchronized state so the update loop does
    -- not clear/recreate hand and attachment models every frame.
    signatureParts = {
        tostring(equipment.primaryFullType or ""),
        Internal.visualStateSignature(equipment.primaryVisual),
        tostring(equipment.secondaryFullType or ""),
        attackMode and "attack" or "idle",
    }
    attachedEntries = Equipment.GetOrderedAttachedEntries(equipment)
    for i = 1, #attachedEntries do
        signatureParts[#signatureParts + 1] = table.concat({
            tostring(attachedEntries[i].location or ""),
            tostring(attachedEntries[i].fullType or ""),
            tostring(attachedEntries[i].slotType or ""),
        }, "=")
    end
    signature = table.concat(signatureParts, "|")
    modData = zombie.getModData and zombie:getModData() or nil
    handStateCurrent = Internal.isPrimaryHandStateCurrent(
        zombie,
        descriptor,
        attackMode
    )
    if modData
        and modData.PNCReplicaHandsSignature == signature
        and handStateCurrent == true
    then
        return true, "replica_hands_current"
    end

    descriptor = Internal.buildWeaponDescriptor(
        equipment.primaryFullType,
        true
    )
    ok, attachedReason, handsReason = Internal.applyCombatPresentation(
        zombie,
        record,
        equipment,
        descriptor,
        attackMode
    )
    Visuals.RefreshModel(zombie)
    if ok and modData then
        modData.PNCReplicaHandsSignature = signature
    end
    return ok,
        tostring(attachedReason) .. "|" .. tostring(handsReason)
end
