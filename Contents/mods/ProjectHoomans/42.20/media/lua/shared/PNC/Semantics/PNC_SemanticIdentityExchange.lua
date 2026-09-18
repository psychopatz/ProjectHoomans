-- Shared identity-exchange contract. Parsing remains client/local; validation
-- and relationship consequences stay on the authoritative server boundary.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.Const = PNC.Const or {}

local Identity = PNC.Semantics.IdentityExchange or {}
PNC.Semantics.IdentityExchange = Identity

Identity.VERSION = 1
Identity.EVENT_CLAIM = "identity_claim"
Identity.EVENT_EVASION = "identity_evasion"
Identity.TRUST_UNTRUSTWORTHY = "untrustworthy"

PNC.Const.CMD_SEMANTIC_IDENTITY_REQUEST =
    PNC.Const.CMD_SEMANTIC_IDENTITY_REQUEST or "SemanticIdentityRequest"
PNC.Const.CMD_SEMANTIC_IDENTITY_RESULT =
    PNC.Const.CMD_SEMANTIC_IDENTITY_RESULT or "SemanticIdentityResult"

function Identity.NormalizeName(value)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    value = string.gsub(value, "%s+", " ")
    value = string.lower(value)
    return value
end

function Identity.NamesEqual(left, right)
    local normalizedLeft = Identity.NormalizeName(left)
    local normalizedRight = Identity.NormalizeName(right)
    return normalizedLeft ~= "" and normalizedLeft == normalizedRight
end

return Identity
