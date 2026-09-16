-- Semantic inventory providers.
-- Selection is read-only; the give provider delegates the final mutation to
-- ServerInventory after reselecting and revalidating the item.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.Semantics.ActionPlanItemProvider =
    PNC.Semantics.ActionPlanItemProvider or {}

local Provider = PNC.Semantics.ActionPlanItemProvider
Provider.Service = PNC.Semantics.ActionPlanService
Provider.ItemSelector = PNC.Semantics.ItemSelector
Provider.Inventory = PNC.Inventory
Provider.ServerInventory = PNC.ServerInventory
Provider.Selection = Provider.Selection or {}
Provider.Give = Provider.Give or {}
Provider.Consume = Provider.Consume or {}
Provider.Refill = Provider.Refill or {}

require "PNC/Semantics/ActionPlanProviders/PNC_SemanticActionPlanItemProvider_Selection"
require "PNC/Semantics/ActionPlanProviders/PNC_SemanticActionPlanItemProvider_Give"
require "PNC/Semantics/ActionPlanProviders/PNC_SemanticActionPlanItemProvider_Consumption"

if Provider.Service and type(Provider.Service.RegisterProvider) == "function" then
    Provider.Service.RegisterProvider("SELECT_ITEM", Provider.Selection)
    Provider.Service.RegisterProvider("GIVE_ITEM", Provider.Give)
    Provider.Service.RegisterProvider("CONSUME_ITEM", Provider.Consume)
    Provider.Service.RegisterProvider("REFILL_ITEM", Provider.Refill)
end

return Provider
