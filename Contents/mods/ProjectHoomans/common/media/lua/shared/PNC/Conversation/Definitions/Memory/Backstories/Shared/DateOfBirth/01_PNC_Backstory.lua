local Identity = PNC.Identity

PNC.Conversation.Memory.RegisterBackstory({
    id = "backstory.shared.date_of_birth",
    class = "shared",
    kind = "date_of_birth",
    resolve = function(record)
        if not Identity or type(Identity.GetBirthProfile) ~= "function" then
            return nil
        end
        local birth = Identity.GetBirthProfile(record)
        if not birth then
            return nil
        end
        return {
            value = "date_of_birth",
            year = birth.year,
            month = birth.month,
            day = birth.day,
            age = birth.age,
        }
    end,
})
return true
