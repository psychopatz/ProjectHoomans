local T = require "tests/support/test"
T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = copy(item) end
    return result
end

PNC = {
    Core = {
        DeepCopy = copy,
        Clamp = function(value, minimum, maximum)
            return math.max(minimum, math.min(maximum, value))
        end,
    },
    Const = { DEFAULT_HP_MAX = 100, GENERATOR_VERSION = 4 },
    Identity = {
        NormalizeSeed = function(value) return tonumber(value) or 1 end,
        NormalizeBirthDate = copy,
    },
}

local Health = require "PNC/Core/Health/PNC_HealthRepository"
local raw = {
    current = 75, max = 100, state = "incapacitated", incapacitatedReason = "bullet",
    body = {
        partBase = 80, parts = { Head = 60 }, lastBleedAt = 999,
        wounds = { Head = { severity = 3, bleedingRate = 2 } },
        infection = { active = true, progress = 1.5 },
        wholeBodyAilments = { pain = { severity = 0.25 } },
    },
}
local encoded = Health.Serialize(raw, 100)
local decoded = Health.Normalize(encoded, 100)
T.equal(encoded.body.partBase, 80, "compact body retains a non-default baseline")
T.equal(decoded.body.parts.Head.current, 60, "body override survives compact encoding")
T.equal(decoded.body.parts.Neck.current, 80, "baseline reconstructs standard parts")
T.equal(decoded.body.bleedingRate, 2, "open wounds reconstruct bleeding")
T.equal(decoded.body.lastBleedAt, 0, "wall-clock bleeding state resets after restart")
T.equal(decoded.body.infection.progress, 1, "infection retains its established bound")
T.equal(decoded.body.wholeBodyAilments.pain.severity, 0.25, "ailment quantization roundtrip")
T.equal(decoded.incapacitatedReason, "bullet", "incapacitation reason survives")
T.equal(raw.body.infection.progress, 1.5, "schema projection leaves source state untouched")
T.falsy(Health.SerializeStamina({ current = 100, max = 100 }),
    "full stamina stays omitted from compact saves")
local record = {}
Health.RestoreStamina({ current = 40, max = 100 }, record)
T.equal(record.stamina.current, 40, "Health owns stamina restoration")

local Identity = require "PNC/Core/Identity/PNC_IdentityRepository"
local profile = {
    seed = 7, displayName = "Codec", archetypeID = "codec",
    backstory = { selections = { hometown = "town:one" }, selectionClass = "neutral" },
    survivor = { voice = "one", voicePrefix = "two", voiceType = 1, voicePitch = 0.5 },
}
local normalized = Identity.Normalize(profile, { id = "codec", name = "Codec" })
T.equal(normalized.seed, 7, "identity repository preserves canonical seed")
T.equal(normalized.survivor.voiceProfile.complete, true, "voice profile provenance is complete")
T.equal(normalized.backstory.selections.hometown, "town:one", "stable biography ID survives")
T.falsy(normalized == profile, "identity schema output owns its copy")
T.falsy(profile.survivor.voiceProfile, "identity serialization leaves source profile untouched")
T.equal(Identity.ValidateRecord({ identity = { survivor = {
    voiceProfile = { schemaVersion = 2 },
} } }), "voice_profile_unsupported", "voice schema still fails closed")
T.falsy(PNC.Persistence, "owning codecs do not load persistence orchestration")
T.falsy(PNC.Conversation, "identity codec does not load dialogue or realization")

T.finish("pnc_domain_codec_ownership_smoke")
