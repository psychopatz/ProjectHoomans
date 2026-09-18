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

-- A player may introduce themselves with the name they actually use in
-- conversation (usually the forename), while the authoritative record may
-- contain a composed forename/surname. Keep the comparison exact: accept the
-- complete canonical name or one complete canonical component, but never a
-- prefix/fuzzy match.
function Identity.ClaimMatchesName(claimed, canonical)
    local normalizedClaim = Identity.NormalizeName(claimed)
    local normalizedCanonical = Identity.NormalizeName(canonical)
    if normalizedClaim == "" or normalizedCanonical == "" then return false end
    if normalizedClaim == normalizedCanonical then return true end
    if string.find(normalizedClaim, "%s") then return false end
    local forename, surname = string.match(
        normalizedCanonical, "^([^%s]+)%s+(.+)$"
    )
    return normalizedClaim == forename or normalizedClaim == surname
end

return Identity
