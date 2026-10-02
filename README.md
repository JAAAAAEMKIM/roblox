# Q-RUN

Q-RUN is a Roblox endless quiz runner: the questions are easy, but reaching the correct side before the answer wall arrives gets increasingly frantic.

## Prototype features

- Server-authoritative, independent player lanes and answer validation.
- Endless mixed questions, including generated arithmetic.
- Physical two-answer walls that visibly approach as the timer.
- Scaling answer time, streak multipliers, score, and movement speed.
- Procedural rocks, sticky mud, and low-friction ice.
- One free second wind, revive-ticket support, and a five-continue cap.
- Persistent best score, best streak, and ticket balance through DataStoreService.
- Responsive PC/mobile HUD constructed without external assets.

## Open in Roblox Studio

Use **Rojo 7**. Do not install one of the similarly named community plugins.

1. Install [Rokit](https://github.com/rojo-rbx/rokit), then run `rokit install` in this directory. The checked-in `rokit.toml` installs the known-compatible **Rojo 7.5.1** CLI.
2. In Roblox Studio, install the official **Rojo 7** plugin by following the link in the [official Rojo installation guide](https://rojo.space/docs/v7/getting-started/installation/). Its creator is the **Rojo** organization.
3. Run `rojo serve` in this directory.
4. Open a new Baseplate in Studio, click the Rojo toolbar button, connect to `localhost:34872`, and choose **Sync In**.
5. Press **Play**. For DataStore testing, publish a private test experience and enable Studio API access.

The official Rojo 7 Studio plugin is updated through Roblox and does not need to display exactly `7.5.1`; the CLI is pinned because it is the component that reads and serves this project.

The experience creates all greybox geometry at runtime. No toolbox models or asset IDs are required.

## Controls

Use Roblox's normal movement controls (keyboard, thumbstick, or touch controls). Move left or right toward the answer. The approaching wall is the timer; the correct panel is passable and the wrong panel is solid.

## Production follow-ups

Developer Product IDs and `MarketplaceService.ProcessReceipt` are intentionally not faked in this prototype. Configure real product IDs before enabling paid ticket bundles. Audio, analytics event emission, and global ordered leaderboards also require experience-specific assets or dashboard configuration.
