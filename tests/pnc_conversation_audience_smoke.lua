local T = require "tests/support/test"

T.addPackagePaths()

PNC = { Conversation = {} }

local Audience = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Conversation/PNC_ConversationAudience.lua"
)

local function resolve(entry, relationshipID)
    return Audience.Resolve(entry, relationshipID)
end

local colonist = {
    snapshot = {
        tacticalClass = "colonist",
    },
}

local firstMeet = resolve(colonist, "FirstMeet")
T.equal(firstMeet.audience, "neutral", "first meet audience")
T.equal(firstMeet.reason, "first_meet_relationship", "first meet reason")
T.equal(firstMeet.tacticalClass, "colonist", "tactical class is preserved")
T.falsy(firstMeet.playerHostile, "first meet is not hostile")
T.falsy(firstMeet.audiences.member, "first meet is not a member")

local acquaintance = resolve(colonist, "Acquaintance")
T.equal(acquaintance.audience, "neutral", "acquaintance audience")
T.equal(acquaintance.reason, "acquaintance_relationship",
    "acquaintance reason")

local member = resolve(colonist, "Member")
T.equal(member.audience, "member", "member audience")
T.equal(member.reason, "member_relationship", "member reason")
T.truthy(member.audiences.member, "member audience flag")
T.falsy(member.audiences.neutral, "member is not neutral")

local lover = resolve(colonist, "Lover")
T.equal(lover.audience, "special", "lover audience")
T.equal(lover.reason, "lover_relationship", "lover reason")
T.truthy(lover.audiences.special, "special audience flag")

local hostile = resolve({
    snapshot = {
        tacticalClass = "colonist",
        hostility = { attackPlayers = true },
    },
}, "Member")
T.equal(hostile.audience, "hostile", "player-hostile audience wins")
T.equal(hostile.reason, "player_hostile", "player-hostile reason")
T.truthy(hostile.playerHostile, "player hostility is explicit")
T.truthy(hostile.audiences.hostile, "hostile audience flag")
T.falsy(hostile.audiences.member, "hostile is not a member audience")

local tacticalHostileOnly = resolve({
    snapshot = {
        tacticalClass = "hostile",
        hostility = { attackPlayers = false },
    },
}, "FirstMeet")
T.equal(tacticalHostileOnly.audience, "neutral",
    "tactical hostility alone does not open hostile parley")
T.falsy(tacticalHostileOnly.playerHostile,
    "missing player hostility fails closed")

local profile = Audience.BuildProfile(
    colonist,
    nil,
    "Member",
    false
)
T.equal(profile.audience, "member", "profile audience")
T.equal(profile.baseEstablished, false, "profile base state")
T.equal(profile.tacticalClass, "colonist", "profile tactical class")

T.finish("pnc_conversation_audience_smoke")
