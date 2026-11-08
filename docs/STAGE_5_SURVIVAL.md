# Stage 5 — Survival Systems

Implemented:
- Collectible cloth, herbs, scrap, food and water resource pickups.
- Resource inventory with on-screen counts.
- Medkit crafting: 2 cloth + 2 herbs.
- Bandage recipe: 1 cloth + 1 herb; crafting immediately restores 20 health.
- Food restores 35 stamina; water restores 20 stamina.
- Existing medkit item heals 40 health.
- Resource counts and uncollected resource pickups are included in offline save data.

Current limits:
- This is the first functional survival loop, not a finished full survival simulation.
- Hunger/thirst meters, expanded recipes, item drag-and-drop UI, and runtime/device QA remain future work.
- Android/Web export workflows must pass after these changes; export success alone is not runtime verification.
