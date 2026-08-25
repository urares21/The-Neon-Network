# The Neon Network — Setup Guide

Quick reference for getting everything to work in Godot 4.6.

---

## 1. After pulling new files — force a reimport

Whenever I add new files (GLBs, WAVs, scenes), Godot needs to *import* them
once to generate cached resources in `.godot/imported/`.

**Do this every time after I add or modify external assets:**

1. Open Godot. If the project is already open, click **Project → Reload Current Project**.
2. In the **FileSystem** panel (bottom-left), right-click the `audio/` folder → **Reimport**.
3. Right-click the `models/` folder → **Reimport**.
4. Wait ~10–20 seconds. The bottom status bar shows progress.

After this, `audio/shoot.wav` and friends will play, and `models/Pistol.glb` /
`models/Sentinel.glb` will render correctly.

> **Why this is needed:** I generate the `.wav` files (and place the `.glb` files)
> on disk, but I can't run Godot to import them. Godot imports on its own on
> next focus, but sometimes it caches a previous "doesn't exist" state — the
> Reimport menu item forces a fresh pass.

---

## 2. If the gun model looks wrong (too big, sideways, hidden)

The Pistol GLB has unusual proportions (bounding box ~0.8 × 2.7 × 4.1 m).
I've placed it with `scale = 0.15` and `position = (0.35, -0.3, -0.55)` relative
to the camera. If it doesn't look right:

1. Open `scenes/Player.tscn` in Godot.
2. In the scene tree click **PistolModel** (under Head/Camera3D).
3. In the **Inspector** → expand **Transform**:
   - **Scale**: try values between `0.05` and `0.5` (apply uniform on X, Y, Z).
   - **Position**: tweak X (right offset), Y (down offset), Z (forward — should be negative).
   - **Rotation**: if pistol points the wrong direction, try `Rotation Y` = `90°` or `180°`.
4. Save with **Ctrl+S**.

Test with **F5** (Play) or **F6** (Play current scene).

---

## 3. If the enemy model looks wrong

The Sentinel GLB has tiny native dimensions (~28 × 17 × 74 mm) and is modeled
lying flat on its back. I rotate it `-90°` around X and scale it `25×`. If it
looks wrong:

1. Open `scenes/Enemy.tscn` in Godot.
2. Click **SentinelModel** (under MeshRoot).
3. In Inspector → **Transform**:
   - If it's lying on the floor: rotate around X axis until standing.
   - If too small / too big: change Scale (try `15`, `25`, `40`, `60`).
   - Adjust Y position so feet touch the floor.
4. Save with **Ctrl+S**.

---

## 4. If you don't hear shoot sound

After the Reimport step in #1 it should work. If still silent:

1. Open `scenes/Player.tscn`.
2. Click **ShootSound** node.
3. In Inspector, drag `audio/shoot.wav` from FileSystem into the **Stream** slot.
4. Check **Volume Db** is `0` (not `-80`).
5. Save with Ctrl+S.

Same idea for ambient music: the `GameManager` autoload loads `audio/ambient.wav`
at runtime — just make sure that file is imported.

---

## 5. Controls reminder

- **WASD** — move
- **Mouse** — look
- **Left click** — shoot
- **R** — reload
- **Shift** — sprint
- **Space** — jump
- **ESC** — pause menu

---

## 6. Level chain

`Main → Intro → L1 (Boot Sector) → L2 (Cache Layer) → L3 (Mainframe Core) →
L4 (Firewall Citadel) → L5 (Cache Stack) → L6 (Trace Loop) → L7 (Encrypted Sector) →
L8 (System Singularity) → VICTORY`

Or jump straight to any level from the **Main menu** level-select grid (2×4).

---

## 7. Known compromises

- **Levels 6–8 are mostly square arenas** because each `.tscn` runs ~150 lines of
  geometry. Level 5 has been redesigned with diagonal blast walls + a ramp as a
  reference for the "more variance" look. If you want me to apply the same
  treatment to Levels 6–8, just say.
- **The Pistol & Sentinel GLB transforms are best guesses.** I parsed their
  bounding boxes from the GLB JSON, but without seeing them rendered I can't
  guarantee scale/rotation. See sections #2 and #3 for adjustments.
