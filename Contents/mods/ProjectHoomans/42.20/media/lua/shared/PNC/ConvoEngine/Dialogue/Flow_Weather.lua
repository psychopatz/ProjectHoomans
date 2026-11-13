-- Response-only weather context pilot.
--
-- The gate is evaluated by Conversation Blocks. The semantic flow only
-- chooses a bounded response branch and never owns weather truth or effects.
return {
    id = "weather_context",
    version = 1,
    owner = "ProjectHoomans",
    triggers = {
        { intent = "QUESTION", subject = "WEATHER" },
    },
    initial = "weather_gate",
    nodes = {
        weather_gate = {
            gate = {
                type = "pnc:weather",
                field = "raining",
                operator = "==",
                value = true,
                passReasonKey = "weather_rain_true",
                failReasonKey = "weather_rain_false",
                unknownReasonKey = "weather_rain_unknown",
            },
            onPass = "raining",
            onFail = "clear",
            onUnknown = "unknown",
        },
        raining = {
            terminal = true,
            responsePool = "semantic.flow.weather.raining",
        },
        clear = {
            terminal = true,
            responsePool = "semantic.flow.weather.clear",
        },
        unknown = {
            terminal = true,
            responsePool = "semantic.flow.weather.unknown",
        },
    },
}
