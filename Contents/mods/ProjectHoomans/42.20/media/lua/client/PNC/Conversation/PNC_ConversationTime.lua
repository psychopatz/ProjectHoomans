-- Build 42.20 game-time adapter for conversation content.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Time = PNC.Conversation.Time or {}
PNC.Conversation.Time = Time

Time.bands = {
    { id = "twilight", from = 21.0, to = 24.0 },
    { id = "twilight", from = 0.0, to = 5.0 },
    { id = "dawn", from = 5.0, to = 6.5 },
    { id = "sunrise", from = 6.5, to = 12.0 },
    { id = "sunset", from = 12.0, to = 18.0 },
    { id = "dusk", from = 18.0, to = 21.0 },
}

function Time.GetHour()
    local gameTime = getGameTime and getGameTime() or nil
    if gameTime and gameTime.getTimeOfDay then
        return tonumber(gameTime:getTimeOfDay()) or 12
    end
    local hour = gameTime and gameTime.getHour
        and tonumber(gameTime:getHour()) or 12
    local minute = gameTime and gameTime.getMinutes
        and tonumber(gameTime:getMinutes()) or 0
    return hour + minute / 60
end

function Time.Resolve(hour)
    hour = tonumber(hour) or Time.GetHour()
    hour = hour % 24
    local index
    for index = 1, #Time.bands do
        local band = Time.bands[index]
        if hour >= band.from and hour < band.to then return band.id end
    end
    return "twilight"
end

return Time
