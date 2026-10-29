-- Transient chatter budget for social conversation opportunities.
-- No world polling and no persistence; callers supply bounded event-local keys.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Budget = PNC.Semantics.SocialBudget or {}
PNC.Semantics.SocialBudget = Budget

Budget.VERSION = 1
Budget.MAX_KEYS = 128
Budget.DEFAULT_ACTOR_COOLDOWN_MS = 5000
Budget.DEFAULT_PAIR_COOLDOWN_MS = 9000
Budget.DEFAULT_TOPIC_COOLDOWN_MS = 12000
Budget.DEFAULT_AREA_WINDOW_MS = 30000
Budget.DEFAULT_AREA_OPENINGS = 3
Budget.URGENT_PRIORITY = 80

local function clean(value, maximum)
    value = tostring(value or "")
    if value == "" or string.find(value, "%c") then return nil end
    return string.sub(value, 1, maximum or 128)
end

local function pairKey(left, right)
    left = clean(left, 96)
    right = clean(right, 96)
    if not left or not right then return nil end
    if left > right then left, right = right, left end
    return left .. "|" .. right
end

local function trimMap(map, order, maximum)
    while #order > maximum do
        local key = table.remove(order, 1)
        map[key] = nil
    end
end

function Budget.New(options)
    options = type(options) == "table" and options or {}
    local instance = {
        clock = type(options.clock) == "function"
            and options.clock or function() return 0 end,
        actorUntil = {},
        actorOrder = {},
        pairUntil = {},
        pairOrder = {},
        topicUntil = {},
        topicOrder = {},
        areas = {},
        areaOrder = {},
        metrics = {
            checks = 0,
            reserved = 0,
            rejected = 0,
            urgentBypass = 0,
        },
        lastDecision = nil,
    }
    local Methods = {}

    function Methods:Now()
        return tonumber(self.clock()) or 0
    end

    function Methods:Remember(map, order, key, untilAt)
        if not key then return end
        if map[key] == nil then order[#order + 1] = key end
        map[key] = untilAt
        trimMap(map, order, Budget.MAX_KEYS)
    end

    function Methods:AreaState(key, now, windowMs)
        if not key then return nil end
        local state = self.areas[key]
        if not state or now >= state.windowUntil then
            state = { count = 0, windowUntil = now + windowMs }
            if self.areas[key] == nil then
                self.areaOrder[#self.areaOrder + 1] = key
            end
            self.areas[key] = state
            trimMap(self.areas, self.areaOrder, Budget.MAX_KEYS)
        end
        return state
    end

    function Methods:Check(spec)
        spec = type(spec) == "table" and spec or {}
        self.metrics.checks = self.metrics.checks + 1
        local now = self:Now()
        local priority = tonumber(spec.priority) or 0
        local urgent = priority >= Budget.URGENT_PRIORITY
            or spec.bypassBudget == true
        local actorID = clean(spec.actorID, 96)
        local targetID = clean(spec.targetID, 96)
        local pair = pairKey(actorID, targetID)
        local topic = clean(spec.topic, 96)
        local area = clean(spec.areaKey, 96)

        if not urgent and actorID
            and now < (tonumber(self.actorUntil[actorID]) or 0)
        then
            return false, "social_actor_cooldown"
        end
        if not urgent and pair
            and now < (tonumber(self.pairUntil[pair]) or 0)
        then
            return false, "social_pair_cooldown"
        end
        if not urgent and topic
            and now < (tonumber(self.topicUntil[topic]) or 0)
        then
            return false, "social_topic_cooldown"
        end

        local windowMs = math.max(1000,
            tonumber(spec.areaWindowMs)
                or Budget.DEFAULT_AREA_WINDOW_MS)
        local maxOpenings = math.max(1, math.floor(
            tonumber(spec.areaMaxOpenings)
                or Budget.DEFAULT_AREA_OPENINGS))
        local areaState = self:AreaState(area, now, windowMs)
        if not urgent and areaState and areaState.count >= maxOpenings then
            return false, "social_area_budget"
        end

        return true, urgent and "urgent_budget_bypass" or "budget_available"
    end

    function Methods:Reserve(spec)
        spec = type(spec) == "table" and spec or {}
        local allowed, reason = self:Check(spec)
        if not allowed then
            self.metrics.rejected = self.metrics.rejected + 1
            self.lastDecision = { allowed = false, reason = reason }
            return false, reason
        end

        local now = self:Now()
        local priority = tonumber(spec.priority) or 0
        local urgent = priority >= Budget.URGENT_PRIORITY
            or spec.bypassBudget == true
        local actorID = clean(spec.actorID, 96)
        local targetID = clean(spec.targetID, 96)
        local pair = pairKey(actorID, targetID)
        local topic = clean(spec.topic, 96)
        local area = clean(spec.areaKey, 96)

        if urgent then
            self.metrics.urgentBypass = self.metrics.urgentBypass + 1
        else
            self:Remember(
                self.actorUntil, self.actorOrder, actorID,
                now + math.max(0, tonumber(spec.actorCooldownMs)
                    or Budget.DEFAULT_ACTOR_COOLDOWN_MS)
            )
            self:Remember(
                self.pairUntil, self.pairOrder, pair,
                now + math.max(0, tonumber(spec.pairCooldownMs)
                    or Budget.DEFAULT_PAIR_COOLDOWN_MS)
            )
            self:Remember(
                self.topicUntil, self.topicOrder, topic,
                now + math.max(0, tonumber(spec.topicCooldownMs)
                    or Budget.DEFAULT_TOPIC_COOLDOWN_MS)
            )
            local state = self:AreaState(
                area, now,
                math.max(1000, tonumber(spec.areaWindowMs)
                    or Budget.DEFAULT_AREA_WINDOW_MS)
            )
            if state then state.count = state.count + 1 end
        end

        self.metrics.reserved = self.metrics.reserved + 1
        self.lastDecision = {
            allowed = true,
            reason = reason,
            actorID = actorID,
            targetID = targetID,
            topic = topic,
            areaKey = area,
            priority = priority,
        }
        return true, reason
    end

    function Methods:Snapshot()
        local areaCount = 0
        for _ in pairs(self.areas) do areaCount = areaCount + 1 end
        return {
            schemaVersion = Budget.VERSION,
            actorCooldownCount = #self.actorOrder,
            pairCooldownCount = #self.pairOrder,
            topicCooldownCount = #self.topicOrder,
            areaCount = areaCount,
            metrics = {
                checks = self.metrics.checks,
                reserved = self.metrics.reserved,
                rejected = self.metrics.rejected,
                urgentBypass = self.metrics.urgentBypass,
            },
            lastDecision = self.lastDecision,
        }
    end

    return setmetatable(instance, { __index = Methods })
end

return Budget
