if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local SocialProfiles = PNC.SocialProfiles
local ProfileMath = PNC.SocialProfileMath

function SocialProfiles.IsGenderCompatible(...)
    return ProfileMath.IsGenderCompatible(...)
end

function SocialProfiles.AreMutuallyOrientationCompatible(...)
    return ProfileMath.AreMutuallyOrientationCompatible(...)
end

function SocialProfiles.ModifySocialEvent(...)
    return ProfileMath.ModifySocialEvent(...)
end

return SocialProfiles
