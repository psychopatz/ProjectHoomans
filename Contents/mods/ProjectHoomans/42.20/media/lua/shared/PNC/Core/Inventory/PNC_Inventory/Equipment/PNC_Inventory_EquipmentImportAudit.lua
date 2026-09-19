-- Bounded diagnostics for inventory reconstruction from legacy equipment.
PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}
PNC.Inventory.Internal = PNC.Inventory.Internal or {}

local Inventory = PNC.Inventory
local Internal = Inventory.Internal
local Audit = Internal.EquipmentImportAudit or {}
Internal.EquipmentImportAudit = Audit

function Audit.InventoryAuditEnabled()
    local diagnostics = PNC.PerformanceScalingDiagnostics
    return diagnostics
        and diagnostics.InventoryAuditEnabled == true
        and type(diagnostics.LogInventoryAudit) == "function"
end

function Audit.Token(value, fallback, maxLength)
    local normalized = Internal.normalizeString(value) or fallback
    normalized = string.gsub(normalized, "%s+", "_")
    if #normalized > maxLength then
        normalized = string.sub(normalized, 1, maxLength)
    end
    return normalized
end

function Audit.LogEquipmentSync(
    record,
    reason,
    result,
    equipment,
    itemCountBefore,
    itemCountAfter,
    preservedCount,
    invalidPayloadCount,
    containerFallbackCount,
    revisionBefore,
    revisionAfter,
    cacheRebuilt,
    dirtyMarked,
    auditEnabled
)
    local diagnostics = PNC.PerformanceScalingDiagnostics
    if not auditEnabled or not diagnostics then return false end
    diagnostics.LogInventoryAudit("equipment_sync", {
        "npc=" .. Audit.Token(record and record.id, "unknown", 64),
        "reason=" .. Audit.Token(reason, "unspecified", 48),
        "result=" .. tostring(result or "unknown"),
        "primary_type=" .. Audit.Token(
            equipment and equipment.primaryFullType,
            "none",
            64
        ),
        "secondary_type=" .. Audit.Token(
            equipment and equipment.secondaryFullType,
            "none",
            64
        ),
        "worn_slots=" .. tostring(
            equipment and type(equipment.worn) == "table"
                and Internal.countMapEntries(equipment.worn) or 0
        ),
        "attached_slots=" .. tostring(
            equipment and type(equipment.attached) == "table"
                and Internal.countMapEntries(equipment.attached) or 0
        ),
        "items_before=" .. tostring(itemCountBefore or 0),
        "preserved_items=" .. tostring(preservedCount or 0),
        "items_after=" .. tostring(itemCountAfter or 0),
        "invalid_payloads=" .. tostring(invalidPayloadCount or 0),
        "container_fallbacks=" .. tostring(containerFallbackCount or 0),
        "revision_before=" .. tostring(revisionBefore or "none"),
        "revision_after=" .. tostring(revisionAfter or "none"),
        "cache_rebuild=" .. (cacheRebuilt and "complete" or "skipped"),
        "dirty_marked=" .. tostring(dirtyMarked == true),
    })
    return true
end

return Audit
