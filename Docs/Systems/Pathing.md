# Pathing

## V1
- live NPCs use lightweight server-owned steering and square safety probes
- abstract NPCs use coarse world travel
- live NPCs can open doors and use windows when the path stalls near an obstacle
- fence hopping is intentionally disabled in the baseline until a non-sticky traversal flow replaces it
- all path ownership lives in `PNC_PathService`

## Next Expansion
- fence traversal
- proper repath and stuck recovery lanes
- path cache reuse for larger live crowds
