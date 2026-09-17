-- Compact identity-seeded NPC gift preference profile.
-- Generated item preferences are derived at runtime; no per-item map is
-- stored in ModData.

PNC = PNC or {}
PNC.Gifts = PNC.Gifts or {}
PNC.Gifts.Foundation = PNC.Gifts.Foundation or {}

local Foundation = PNC.Gifts.Foundation
local Profile = Foundation.PreferenceProfile or {}
Foundation.PreferenceProfile = Profile

Profile.VERSION = 1
Profile.GENERATION_VERSION = 1
Profile.MULTIPLIERS = {
    favorite = 1.80,
    liked = 1.25,
    neutral = 1.00,
    disliked = 0.55,
    hated = -0.75,
}
Profile.DISPOSITION_ORDER = {
    "favorite", "liked", "neutral", "disliked", "hated",
}
Profile.STRENGTH = {
    favorite = 1.00,
    liked = 0.45,
    neutral = 0.00,
    disliked = -0.45,
    hated = -1.00,
}

function Profile.New(identitySeed, archetypeID, overrides)
    local Identity = PNC.Identity
    local archetype = tostring(archetypeID or "General")
    if #archetype > 64 then archetype = string.sub(archetype, 1, 64) end
    local seed
    if Identity and type(Identity.NormalizeSeed) == "function" then
        seed = Identity.NormalizeSeed(identitySeed, archetype)
    else
        seed = tonumber(identitySeed) or 1
    end
    return {
        schemaVersion = Profile.VERSION,
        generationVersion = Profile.GENERATION_VERSION,
        identitySeed = seed,
        archetypeID = archetype,
        overrides = Profile.NormalizeOverrides(overrides),
    }
end

function Profile.FromNPC(record, options)
    record = type(record) == "table" and record or {}
    options = type(options) == "table" and options or {}
    local social = type(record.social) == "table" and record.social or {}
    local overrides = options.overrides
        or record.giftPreferenceOverrides
        or social.giftPreferenceOverrides
    return Profile.New(
        record.identitySeed or record.seed,
        record.archetypeID or record.archetype or options.archetypeID,
        overrides
    )
end

require "PNC/Gifts/PNC_GiftPreferenceProfile_Overrides"
require "PNC/Gifts/PNC_GiftPreferenceProfile_Seed"
require "PNC/Gifts/PNC_GiftPreferenceProfile_Resolver"

return Profile
