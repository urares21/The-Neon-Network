# Configurare Input Map (Project Settings → Input Map)

Adaugă următoarele acțiuni în Project Settings → Input Map:

| Acțiune        | Tastă / Buton              |
|----------------|----------------------------|
| `move_forward` | W                          |
| `move_back`    | S                          |
| `move_left`    | A                          |
| `move_right`   | D                          |
| `jump`         | Space                      |
| `sprint`       | Shift Left                 |
| `shoot`        | Mouse Button Left          |
| `interact`     | E                          |
| `ui_cancel`    | Escape (există default)    |

## Layers de coliziune recomandate
- Layer 1: World (geometrie statică nivel)
- Layer 2: Player
- Layer 3: Enemy
- Layer 4: Bullet
- Layer 5: Pickup (Area3D – chei, date, portal)

## Grupuri (Groups) folosite în cod
- `player` — atașează pe Player root
- `enemies` — atașat automat în EnemyAI._ready()
- `game_manager` — atașat automat în GameManager._ready()

## Autoloads (Project Settings → Autoload)
- `GameManager` → `res://code/game_manager.gd`
