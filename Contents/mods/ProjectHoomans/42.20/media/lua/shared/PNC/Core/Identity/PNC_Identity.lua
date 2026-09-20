PNC = PNC or {}
PNC.Identity = PNC.Identity or {}

local Identity = PNC.Identity

Identity.SEED_MAX = 2147483646

function Identity.RollSeed()
    return ZombRand(Identity.SEED_MAX) + 1
end

function Identity.NormalizeSeed(seed, fallback)
    local numeric = math.floor(tonumber(seed) or 0)
    if numeric > 0 then
        numeric = numeric % Identity.SEED_MAX
        if numeric <= 0 then
            numeric = 1
        end
        return numeric
    end
    return Identity.HashText(tostring(fallback or "pnc_seed"))
end

function Identity.HashText(text, seed)
    local value = Identity.NormalizeSeed(seed or 5381, 5381)
    local source = tostring(text or "")
    local i
    for i = 1, #source do
        value = ((value * 33) + string.byte(source, i)) % Identity.SEED_MAX
    end
    if value <= 0 then
        value = 1
    end
    return value
end

function Identity.MixSeed(seed, salt)
    return Identity.HashText(tostring(salt or "seed"), Identity.NormalizeSeed(seed, salt))
end

function Identity.Index(seed, salt, count)
    local size = math.max(0, math.floor(tonumber(count) or 0))
    if size <= 0 then
        return 1
    end
    return (Identity.MixSeed(seed, salt) % size) + 1
end

function Identity.Range(seed, salt, minValue, maxValue)
    local low = math.floor(tonumber(minValue) or 0)
    local high = math.floor(tonumber(maxValue) or low)
    if high < low then
        high = low
    end
    return low + (Identity.MixSeed(seed, salt) % ((high - low) + 1))
end

function Identity.Float(seed, salt)
    return Identity.MixSeed(seed, salt) / Identity.SEED_MAX
end

local BIRTH_MONTH_STRIDE = 32
local BIRTH_YEAR_STRIDE = 12 * BIRTH_MONTH_STRIDE
local DAYS_IN_MONTH = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

local function isLeapYear(year)
    return year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)
end

function Identity.EncodeBirthDate(year, month, day)
    year = math.floor(tonumber(year) or -1)
    month = math.floor(tonumber(month) or -1)
    day = math.floor(tonumber(day) or -1)
    if year < 1 or month < 0 or month > 11 or day < 0 then
        return nil
    end
    local daysInMonth = DAYS_IN_MONTH[month + 1]
    if month == 1 and isLeapYear(year) then
        daysInMonth = 29
    end
    if day >= daysInMonth then
        return nil
    end
    return year * BIRTH_YEAR_STRIDE
        + month * BIRTH_MONTH_STRIDE
        + day
end

function Identity.UnpackBirthDate(value)
    local packed = math.floor(tonumber(value) or 0)
    if packed <= 0 then
        return nil
    end
    local year = math.floor(packed / BIRTH_YEAR_STRIDE)
    local remainder = packed - year * BIRTH_YEAR_STRIDE
    local month = math.floor(remainder / BIRTH_MONTH_STRIDE)
    local day = remainder - month * BIRTH_MONTH_STRIDE
    if Identity.EncodeBirthDate(year, month, day) ~= packed then
        return nil
    end
    return year, month, day
end

function Identity.NormalizeBirthDate(value)
    local year, month, day = Identity.UnpackBirthDate(value)
    if not year then
        return nil
    end
    return Identity.EncodeBirthDate(year, month, day)
end

function Identity.CurrentWorldDate()
    if type(getGameTime) ~= "function" then
        return nil
    end
    local gameTime = getGameTime()
    if not gameTime then
        return nil
    end
    local year = tonumber(gameTime:getYear())
    local month = tonumber(gameTime:getMonth())
    local day = tonumber(gameTime:getDay())
    if not Identity.EncodeBirthDate(year, month, day) then
        return nil
    end
    return math.floor(year), math.floor(month), math.floor(day)
end

function Identity.AgeAtDate(birthDate, year, month, day)
    local birthYear, birthMonth, birthDay =
        Identity.UnpackBirthDate(birthDate)
    year = tonumber(year)
    month = tonumber(month)
    day = tonumber(day)
    if not birthYear or not year or not month or not day then
        return nil
    end
    local age = math.floor(year) - birthYear
    if month < birthMonth or (month == birthMonth and day < birthDay) then
        age = age - 1
    end
    return age
end

function Identity.ResolveBirthDate(seed, existingBirthDate, year, month, day)
    local currentYear = tonumber(year)
    local currentMonth = tonumber(month)
    local currentDay = tonumber(day)
    if not currentYear or not currentMonth or not currentDay then
        currentYear, currentMonth, currentDay = Identity.CurrentWorldDate()
    end
    local birthDate = Identity.NormalizeBirthDate(existingBirthDate)
    if birthDate then
        if not currentYear then
            return birthDate
        end
        local age = Identity.AgeAtDate(
            birthDate,
            currentYear,
            currentMonth,
            currentDay
        )
        if age and age >= 18 then
            return birthDate
        end
    end
    if not currentYear then
        return nil
    end

    local targetAge = Identity.Range(seed, "pnc:birth:age", 18, 80)
    local birthMonth = Identity.Range(seed, "pnc:birth:month", 0, 11)
    local birthDay = Identity.Range(seed, "pnc:birth:day", 0, 27)
    local birthYear = math.floor(currentYear) - targetAge
    if birthMonth > currentMonth
        or (birthMonth == currentMonth and birthDay > currentDay)
    then
        birthYear = birthYear - 1
    end
    return Identity.EncodeBirthDate(birthYear, birthMonth, birthDay)
end

function Identity.EnsureBirthDate(record, markDirty)
    if type(record) ~= "table" then
        return nil
    end
    if type(record.identity) ~= "table" then
        record.identity = {}
    end
    local previous = Identity.NormalizeBirthDate(record.identity.birth)
    local birthDate = Identity.ResolveBirthDate(
        record.identity.seed or record.identitySeed,
        previous
    )
    if birthDate and birthDate ~= record.identity.birth then
        record.identity.birth = birthDate
        if markDirty == true and PNC.Registry
            and type(PNC.Registry.MarkDirty) == "function"
        then
            PNC.Registry.MarkDirty(record, "identity")
        end
    end
    return birthDate
end

function Identity.GetBirthProfile(record)
    local currentYear, currentMonth, currentDay =
        Identity.CurrentWorldDate()
    local birthDate = Identity.EnsureBirthDate(record, true)
    local birthYear, birthMonth, birthDay =
        Identity.UnpackBirthDate(birthDate)
    if not birthYear then
        return nil
    end
    return {
        year = birthYear,
        month = birthMonth + 1,
        day = birthDay + 1,
        age = currentYear and Identity.AgeAtDate(
            birthDate,
            currentYear,
            currentMonth,
            currentDay
        ) or nil,
    }
end
