# Stage 7 — Enemy Systems

Implemented in the current prototype:
- Enemy AI state machine: patrol, investigate, chase, attack and retreat.
- Line-of-sight detection using a physics ray test; running can also attract an enemy within its hearing radius.
- Short target-memory window after line of sight is lost.
- Attack wind-up, attack cooldown, configurable attack distance and damage.
- Enemy health, damage handling, health signal and death cleanup, ready for a later player weapon/combat system.
- Three configured enemy archetypes in the forest: Wanderer (balanced), Stalker (faster, lower health, wounded retreat) and Brute (slow, high health, heavy damage).
- Distinct Stalker silhouette and collision dimensions.
- Enemy positions are persisted in offline saves; legacy saves with the previous single-monster position remain supported.

Not yet complete / needs later stages:
- Player weapon and hit detection are not implemented yet; enemy `take_damage` is an integration point for the later combat system.
- Navigation mesh/pathfinding, obstacle avoidance, animation, audio cues, boss AI and final balance remain future work.
- Android/Web export builds and real-device gameplay QA must be checked after this change.
