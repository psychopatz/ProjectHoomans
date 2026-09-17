-- Identity-seeded rolls for gift preferences and economic sensitivity.

PNC = PNC or {}
PNC.Gifts = PNC.Gifts or {}
PNC.Gifts.Foundation = PNC.Gifts.Foundation or {}
local Foundation = PNC.Gifts.Foundation
local Profile = Foundation.PreferenceProfile

local function identityModule()
    if PNC.Identity and type(PNC.Identity.NormalizeSeed) == "function"
        and type(PNC.Identity.Float) == "function" then
        return PNC.Identity
    end
    pcall(require, "PNC/Core/Identity/PNC_Identity")
    return PNC.Identity
end

local function identityFloat(profile, salt)
    local Identity = identityModule()
    if Identity and type(Identity.Float) == "function" then
        return Identity.Float(profile.identitySeed, salt)
    end
    return 0.5
end

function Profile.IdentityFloat(profile, salt)
    return identityFloat(profile, salt)
end

function Profile.GeneratedDisposition(profile, key)
    local favoriteChance = 0.07
        + identityFloat(profile, "gift_preference:v1:favorite_rate") * 0.05
    local hatedChance = 0.04
        + identityFloat(profile, "gift_preference:v1:hated_rate") * 0.04
    local likedChance = 0.14
        + identityFloat(profile, "gift_preference:v1:liked_rate") * 0.10
    local dislikedChance = 0.10
        + identityFloat(profile, "gift_preference:v1:disliked_rate") * 0.10
    local roll = identityFloat(profile,
        "gift_preference:v" .. tostring(Profile.GENERATION_VERSION)
        .. ":key:" .. tostring(key))
    if roll < hatedChance then return "hated" end
    if roll < hatedChance + dislikedChance then return "disliked" end
    if roll > 1 - favoriteChance then return "favorite" end
    if roll > 1 - favoriteChance - likedChance then return "liked" end
    return "neutral"
end

function Profile.GetValueSensitivity(profile)
    if type(profile) ~= "table" then return 1 end
    return 0.75 + identityFloat(profile,
        "gift_preference:v" .. tostring(Profile.GENERATION_VERSION)
        .. ":value_sensitivity") * 0.50
end

return Profile
