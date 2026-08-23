PNC = PNC or {}
PNC.Equipment = PNC.Equipment or {}
PNC.Equipment.Internal = PNC.Equipment.Internal or {}

local Equipment = PNC.Equipment
local Internal = Equipment.Internal
local Core = PNC.Core
local Visuals = PNC.Visuals
local Inventory = PNC.Inventory

function Equipment.Apply(zombie, record)
    local equipment
    local descriptor
    local ok = true
    local laneOk
    local handsReason
    local reasons = {}

    if not zombie or not record then
        return false, "missing_body_or_record"
    end
    if Internal.isClientOnlyGame() then
        return Equipment.ApplyReplicaVisuals(zombie, record)
    end

    equipment = Equipment.EnsureRecordEquipment(record)
    if isServer and isServer() == true then
        laneOk, reasons[#reasons + 1] =
            Internal.applyWornItems(zombie, equipment, record)
        if not laneOk then ok = false end
        laneOk, reasons[#reasons + 1] =
            Equipment.ApplyReplicaHands(zombie, record)
        if not laneOk then ok = false end
        Visuals.RefreshModel(zombie)
        return ok, table.concat(reasons, "|")
    end
    descriptor = Internal.buildWeaponDescriptor(equipment.primaryFullType, true)

    laneOk, reasons[#reasons + 1] = Internal.applyWornItems(zombie, equipment, record)
    if not laneOk then
        ok = false
    end

    laneOk, reasons[#reasons + 1], handsReason = Internal.applyCombatPresentation(
        zombie,
        record,
        equipment,
        descriptor,
        Internal.isAttackMode(record)
    )
    reasons[#reasons + 1] = handsReason
    if not laneOk then
        ok = false
    end

    Visuals.RefreshModel(zombie)
    return ok, table.concat(reasons, "|")
end

function Equipment.ApplyHands(zombie, record)
    local equipment
    local descriptor
    local ok
    local reason

    if not zombie or not record then
        return false, "missing_body_or_record"
    end
    if Internal.isNetworkedGame() then
        return Equipment.ApplyReplicaHands(zombie, record)
    end

    equipment = Equipment.EnsureRecordEquipment(record)
    descriptor = Internal.buildWeaponDescriptor(equipment.primaryFullType, true)
    ok, _, reason = Internal.applyCombatPresentation(
        zombie,
        record,
        equipment,
        descriptor,
        Internal.isAttackMode(record)
    )
    Visuals.RefreshModel(zombie)
    return ok, reason
end
