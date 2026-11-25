local Registry = PNC.ProvisionRuleRegistry

Registry.Register({
    id = "armor_upgrade",
    category = "loadout",
    order = 50,
    mode = "UPGRADE_BEST",
    selector = "ARMOR",
    resourceKind = "ARMOR",
    measure = "SCORE",
    priority = 18,
    defaults = { enabled = false, minUpgradeDelta = 10 },
    ui = {
        labelKey = "UI_PNC_Provision_ArmorUpgrade",
        descriptionKey = "UI_PNC_Provision_ArmorUpgrade_Description",
        measureKey = "UI_PNC_Provision_UpgradeDelta",
        fields = {
            { id = "minUpgradeDelta", type = "number", min = 1,
                max = 100, step = 1,
                labelKey = "UI_PNC_Provision_MinUpgradeDelta" },
        },
    },
})

return Registry
