PNC = PNC or {}
PNC.SupplyRequest = PNC.SupplyRequest or {}

local Request = PNC.SupplyRequest
local VALID_KIND = { FOOD = true, HYDRATION = true, MEDICAL = true }
local VALID_FULFILLMENT = { INSTANT = true, PHYSICAL = true }
local VALID_PURPOSE = { NEED = true, PROVISION = true }

function Request.Create(spec)
    spec = type(spec) == "table" and spec or {}
    local kind = string.upper(tostring(spec.resourceKind or ""))
    local requesterID = tostring(spec.requesterId or "")
    local fulfillment = string.upper(tostring(spec.fulfillment or "INSTANT"))
    local purpose = string.upper(tostring(spec.purpose or "NEED"))
    if requesterID == "" then return nil, "requester_required" end
    if not VALID_KIND[kind] then return nil, "resource_kind_invalid" end
    if not VALID_FULFILLMENT[fulfillment] then
        return nil, "fulfillment_invalid"
    end
    if not VALID_PURPOSE[purpose] then return nil, "purpose_invalid" end
    return {
        requesterId = requesterID,
        purpose = purpose,
        resourceKind = kind,
        required = type(spec.required) == "table" and spec.required or {},
        treatment = spec.treatment and string.upper(tostring(spec.treatment)) or nil,
        priority = math.max(0, math.min(100, tonumber(spec.priority) or 50)),
        sourcePolicy = tostring(spec.sourcePolicy or "CURRENT_BASE"),
        fulfillment = fulfillment,
        target = tonumber(spec.target),
        debug = spec.debug == true,
    }
end

return Request
