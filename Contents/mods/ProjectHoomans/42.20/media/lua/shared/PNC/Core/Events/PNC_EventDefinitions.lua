PNC = PNC or {}

PNC.EventTypes = PNC.EventTypes or {
    STORAGE_ITEM_DEPOSITED = "projecthoomans.storage.itemDeposited",
    STORAGE_ITEM_WITHDRAWN = "projecthoomans.storage.itemWithdrawn",
    NPC_FOOD_CONSUMED = "projecthoomans.npc.needs.foodConsumed",
    NPC_DRINK_CONSUMED = "projecthoomans.npc.needs.drinkConsumed",
    NPC_NEED_SEVERITY_CHANGED = "projecthoomans.npc.needs.severityChanged",
    NPC_NEED_CRITICAL_DAMAGE = "projecthoomans.npc.needs.criticalDamage",
    NPC_WEIGHT_CATEGORY_CHANGED = "projecthoomans.npc.nutrition.weightCategoryChanged",
    NPC_INVENTORY_CHANGED = "projecthoomans.npc.inventory.changed",
    NPC_SKILL_LEVEL_UP = "projecthoomans.npc.skill.levelUp",
    NPC_WOUNDED = "projecthoomans.npc.health.wounded",
    BASE_CREATED = "projecthoomans.base.created",
    BASE_ZONE_CHANGED = "projecthoomans.base.zoneChanged",
    BARRICADE_BUILT = "projecthoomans.base.barricadeBuilt",
    HQ_UPGRADED = "projecthoomans.base.hqUpgraded",
    FACILITY_CREATED = "projecthoomans.facility.created",
    FACILITY_UPGRADED = "projecthoomans.facility.upgraded",
    FACILITY_COMPONENT_CHANGED = "projecthoomans.facility.componentChanged",
    FACILITY_SETTINGS_CHANGED = "projecthoomans.facility.settingsChanged",
    FACILITY_STATE_CHANGED = "projecthoomans.facility.stateChanged",
    FACILITY_DESTROYED = "projecthoomans.facility.destroyed",
    STOCKPILE_NODE_CHANGED = "projecthoomans.stockpile.nodeChanged",
    RECIPE_KNOWLEDGE_UNLOCKED = "projecthoomans.research.recipeUnlocked",
    TECHNOLOGY_UNLOCKED = "projecthoomans.research.technologyUnlocked",
    WORK_ORDER_QUEUED = "projecthoomans.work.queued",
    WORK_ORDER_COMPLETED = "projecthoomans.work.completed",
    WORK_ORDER_CANCELLED = "projecthoomans.work.cancelled",
}

return PNC.EventTypes
