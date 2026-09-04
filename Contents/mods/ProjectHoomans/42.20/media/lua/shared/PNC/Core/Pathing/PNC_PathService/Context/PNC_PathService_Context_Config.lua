-- PathService context dependencies and shared tuning constants.

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}
PNC.PathService.Internal = PNC.PathService.Internal or {}

local Internal = PNC.PathService.Internal

Internal.Core = PNC.Core
Internal.Animation = PNC.Animation
Internal.LiveBodyControl = PNC.LiveBodyControl
Internal.FakeLocomotion = PNC.FakeLocomotion
Internal.LocomotionProfiles = PNC.LocomotionProfiles
Internal.MotionHints = PNC.MotionHints
Internal.TraversalQuery = PNC.TraversalQuery

Internal.GOAL_REFRESH_DELAY_MS = 120
Internal.PROGRESS_TIMEOUT_MS = 2200
Internal.INTERACTION_STALL_MS = 260
Internal.SPECIAL_ACTION_COOLDOWN_MS = 1500
Internal.TRAVERSAL_REPEAT_COOLDOWN_MS = 2400
Internal.TRAVERSAL_PROGRESS_CLEAR_DISTANCE = 1.35
Internal.RUN_START_DISTANCE = 4.50
Internal.RUN_STOP_DISTANCE = 2.90
Internal.FACE_REAPPLY_INTERVAL_MS = 90
Internal.LOCOMOTION_FACE_REAPPLY_INTERVAL_MS = 40
Internal.FACE_SIMILAR_DOT = 0.985
Internal.LOCOMOTION_FACE_SIMILAR_DOT = 0.99985
Internal.FACE_MIN_DISTANCE_SQ = 0.0036
Internal.COMBAT_FACING_DEFAULT_MS = 180
Internal.AMBIENT_FACING_INITIAL_DELAY_MS = 4000
Internal.AMBIENT_FACING_LEASE_MS = 850
Internal.AMBIENT_FACING_MIN_INTERVAL_MS = 5000
Internal.AMBIENT_FACING_JITTER_MS = 2500
Internal.AMBIENT_FACING_RETRY_MS = 1500
Internal.AMBIENT_FACING_DISTANCE = 3.0
Internal.NON_LOCOMOTION_RECOVERY_MS = 240
Internal.LOCOMOTION_VISUAL_LEASE_MS = 420
Internal.POSITION_RECOVERY_LOG_INTERVAL_MS = 15000
