-- Global, event-driven owner for bounded autonomous semantic scenes.
-- No polling hook lives here. Callers explicitly open/close/sweep/update.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Scene = require "PNC/Semantics/PNC_SemanticInteractionScene"
local Scheduler = require "PNC/Semantics/PNC_SemanticInteractionScheduler"
local ValueBounds = require "PNC/Semantics/PNC_SemanticValueBounds"

local Runtime = PNC.Semantics.InteractionSceneRuntime or {}
PNC.Semantics.InteractionSceneRuntime = Runtime

Runtime.VERSION = 1
Runtime.DEFAULT_TTL_MS = 15000
Runtime.MIN_TTL_MS = 1000
Runtime.MAX_TTL_MS = 120000

local defaultRuntime = nil

local function copy(value)
    return ValueBounds.Copy(value)
end

local function cleanID(value)
    value = tostring(value or "")
    if value == "" or #value > 128 then return nil end
    if string.find(value, "[^%w_%.:%-]") then return nil end
    return value
end

local function clockNow()
    if PNC.Core and type(PNC.Core.Now) == "function" then
        local ok, value = pcall(PNC.Core.Now)
        if ok and tonumber(value) then return tonumber(value) end
    end
    if type(getTimeInMillis) == "function" then
        return tonumber(getTimeInMillis()) or 0
    end
    return 0
end

local function boundedTTL(value)
    value = tonumber(value) or Runtime.DEFAULT_TTL_MS
    return math.max(
        Runtime.MIN_TTL_MS,
        math.min(Runtime.MAX_TTL_MS, value)
    )
end

local function removeOrder(order, id)
    for index = #order, 1, -1 do
        if order[index] == id then
            table.remove(order, index)
            return
        end
    end
end

function Runtime.New(options)
    options = type(options) == "table" and options or {}
    local scheduler = Scheduler.New({
        maxActiveScenes = options.maxActiveScenes,
        maxParticipants = options.maxParticipants,
        maxTurns = options.maxTurns,
    })
    local instance = {
        schemaVersion = Runtime.VERSION,
        scheduler = scheduler,
        scenes = {},
        metadata = {},
        order = {},
        sequence = 0,
        clock = type(options.clock) == "function"
            and options.clock or clockNow,
        metrics = {
            admissionAttempts = 0,
            admissionAccepted = 0,
            admissionRejected = 0,
            ttlExpired = 0,
            actorUnavailableClosed = 0,
            explicitClosed = 0,
            maxActiveScenes = 0,
        },
    }

    local Methods = {}

    function Methods:Now()
        local ok, value = pcall(self.clock)
        return ok and tonumber(value) or 0
    end

    function Methods:NextID()
        self.sequence = self.sequence + 1
        return "scene:runtime:" .. tostring(self.sequence)
    end

    function Methods:PruneClosed()
        for index = #self.order, 1, -1 do
            local id = self.order[index]
            if not self.scheduler.scenes[id] then
                local scene = self.scenes[id]
                if scene then scene.status = "closed" end
                self.scenes[id] = nil
                self.metadata[id] = nil
                table.remove(self.order, index)
            end
        end
    end

    function Methods:Open(spec)
        spec = type(spec) == "table" and spec or {}
        self:PruneClosed()
        self.metrics.admissionAttempts =
            self.metrics.admissionAttempts + 1

        local id = cleanID(spec.id) or self:NextID()
        if self.scenes[id] or self.scheduler.scenes[id] then
            self.metrics.admissionRejected =
                self.metrics.admissionRejected + 1
            return nil, "scene_duplicate:" .. id
        end

        local now = tonumber(spec.now) or self:Now()
        local ttlMs = boundedTTL(spec.ttlMs)
        -- Preserve actor object identity for adapter lookups. Scene.New
        -- already copies bounded projections/world data where appropriate.
        local sceneSpec = {
            id = id,
            scheduler = self.scheduler,
            participants = spec.participants,
            playerParticipant = spec.playerParticipant == true,
            perceived = spec.perceived == true,
            distance = spec.distance,
            maxTurns = spec.maxTurns,
            topic = spec.topic,
            world = spec.world,
            worldProviderID = spec.worldProviderID,
            worldEvents = spec.worldEvents,
        }

        local scene, reason = Scene.New(sceneSpec)
        if not scene then
            self.metrics.admissionRejected =
                self.metrics.admissionRejected + 1
            return nil, reason
        end

        self.scenes[id] = scene
        self.metadata[id] = {
            id = id,
            providerID = cleanID(spec.providerID)
                or "interaction.scene.runtime",
            openedAt = now,
            expiresAt = now + ttlMs,
            ttlMs = ttlMs,
        }
        self.order[#self.order + 1] = id
        self.metrics.admissionAccepted =
            self.metrics.admissionAccepted + 1
        self.metrics.maxActiveScenes = math.max(
            self.metrics.maxActiveScenes,
            #self.order
        )
        return scene, id
    end

    function Methods:Get(id)
        id = cleanID(id)
        if not id then return nil, "scene_id_invalid" end
        if not self.scheduler.scenes[id] then
            local stale = self.scenes[id]
            if stale then stale.status = "closed" end
            self.scenes[id] = nil
            self.metadata[id] = nil
            removeOrder(self.order, id)
            return nil, "scene_unknown"
        end
        return self.scenes[id]
    end

    function Methods:Close(id, reason)
        local scene, getReason = self:Get(id)
        if not scene then return nil, getReason end
        local closed, closeReason = scene:Close(
            reason or "runtime_close"
        )
        if not closed then return nil, closeReason end
        scene.status = "closed"
        self.scenes[id] = nil
        self.metadata[id] = nil
        removeOrder(self.order, id)
        self.metrics.explicitClosed =
            self.metrics.explicitClosed + 1
        return closed
    end

    function Methods:UpdateVisibility(id, spec)
        local scene, reason = self:Get(id)
        if not scene then return nil, reason end
        return scene:UpdateVisibility(spec)
    end

    function Methods:Sweep(at)
        at = tonumber(at) or self:Now()
        local expired = {}
        for index = 1, #self.order do
            local id = self.order[index]
            local metadata = self.metadata[id]
            if metadata and at >= (metadata.expiresAt or math.huge) then
                expired[#expired + 1] = id
            end
        end
        for index = 1, #expired do
            local id = expired[index]
            local scene = self.scenes[id]
            if scene then
                scene:Close("ttl_expired")
                scene.status = "closed"
            end
            self.scenes[id] = nil
            self.metadata[id] = nil
            removeOrder(self.order, id)
            self.metrics.ttlExpired =
                self.metrics.ttlExpired + 1
        end
        self:PruneClosed()
        return #expired
    end

    function Methods:ActorUnavailable(actorID, reason)
        actorID = cleanID(actorID)
        if not actorID then return 0, "actor_id_invalid" end
        local affected = {}
        for index = 1, #self.order do
            local id = self.order[index]
            local scene = self.scenes[id]
            if scene and scene.participants
                and scene.participants[actorID]
            then
                affected[#affected + 1] = id
            end
        end
        for index = 1, #affected do
            local id = affected[index]
            local scene = self.scenes[id]
            if scene then
                scene:Close(reason or "actor_unavailable")
                scene.status = "closed"
            end
            self.scenes[id] = nil
            self.metadata[id] = nil
            removeOrder(self.order, id)
            self.metrics.actorUnavailableClosed =
                self.metrics.actorUnavailableClosed + 1
        end
        return #affected
    end

    function Methods:Snapshot()
        self:PruneClosed()
        local scenes = {}
        for index = 1, #self.order do
            local id = self.order[index]
            local scene = self.scenes[id]
            if scene then
                local snapshot = scene:Snapshot()
                snapshot.runtime = copy(self.metadata[id])
                scenes[#scenes + 1] = snapshot
            end
        end
        local schedulerSnapshot = self.scheduler:Snapshot()
        return {
            schemaVersion = Runtime.VERSION,
            activeSceneCount = #scenes,
            scenes = scenes,
            metrics = copy(self.metrics),
            scheduler = schedulerSnapshot,
            limits = copy(schedulerSnapshot.limits),
        }
    end

    return setmetatable(instance, { __index = Methods })
end

function Runtime.Default()
    if not defaultRuntime then
        defaultRuntime = Runtime.New()
    end
    return defaultRuntime
end

function Runtime.Open(spec)
    return Runtime.Default():Open(spec)
end

function Runtime.Get(id)
    return Runtime.Default():Get(id)
end

function Runtime.Close(id, reason)
    return Runtime.Default():Close(id, reason)
end

function Runtime.UpdateVisibility(id, spec)
    return Runtime.Default():UpdateVisibility(id, spec)
end

function Runtime.Sweep(at)
    return Runtime.Default():Sweep(at)
end

function Runtime.ActorUnavailable(actorID, reason)
    return Runtime.Default():ActorUnavailable(actorID, reason)
end

function Runtime.Snapshot()
    return Runtime.Default():Snapshot()
end

function Runtime.ResetForTests(options)
    defaultRuntime = Runtime.New(options)
    return defaultRuntime
end

return Runtime
