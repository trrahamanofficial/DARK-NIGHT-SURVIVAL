# Stage 8 — Story Campaign

Implemented first playable story-campaign pass:
- Four sequential chapters: The Silent Forest, Lost Signal, The Last Transmission, and Get Out Alive.
- In-world objective markers with proximity triggers at the abandoned radio, three evidence locations, signal tower, and extraction clearing.
- Story objective HUD shows the active chapter, current task, and progress.
- Story text panels communicate discoveries, recovered evidence, signal restoration and the ending.
- Progression is gated: the player must reach the radio, recover all three evidence pieces, reach the tower, then reach extraction.
- Story state, collected evidence IDs, chapter index and checkpoint position/health are included in the existing offline save payload.
- Death restart restores the player at the latest story checkpoint.
- Story campaign state is an offline autoload; no account or internet is required.

Current limitations / future work:
- Story beats are text panels, not full animated cinematic cutscenes or voice acting.
- The current chapter route is built inside the existing Dark Forest prototype; dedicated hospital/village/bunker maps are Stage 9.
- Mission balance, marker visibility, checkpoint reliability and full story completion need runtime QA on Android.
- The ending is a first-pass cliffhanger, not the complete final narrative of the whole game.
- Android/Web export workflows must complete successfully for this stage before it is called build-verified.
