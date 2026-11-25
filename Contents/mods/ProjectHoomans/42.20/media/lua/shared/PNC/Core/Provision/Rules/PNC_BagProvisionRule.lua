local Registry = PNC.ProvisionRuleRegistry

Registry.Register({
    id = "bag_upgrade",
    category = "loadout",
    order = 60,
    mode = "UPGRADE_BEST",
    selector = "BAG",
    resourceKind = "BAG",
    measure = "SCORE",
    priority = 15,
    defaults = { enabled = true, minUpgradeDelta = 2 },
    ui = {
        labelKey = "UI_PNC_Provision_BagUpgrade",
        descriptionKey = "UI_PNC_Provision_BagUpgrade_Description",
        measureKey = "UI_PNC_Provision_UpgradeDelta",
        fields = {
            { id = "minUpgradeDelta", type = "number", min = 1,
                max = 50, step = 1,
                labelKey = "UI_PNC_Provision_MinUpgradeDelta" },
        },
    },
})

return Registry
