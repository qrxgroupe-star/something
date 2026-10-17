# Chodov · Little Drift

A small, standalone 3D drift playground built with Godot 4.6.3. Drive a cute black Scandinavian sedan inspired by the Volvo S60 T8 around a stylized Westfield Chodov in Prague.

The circular outer road measures **5,000 metres along its centreline**. An inner boulevard, four connecting roads, and an open parking plaza provide extra sliding space. The layout is an artistic simplification, not an accurate reconstruction of Prague's streets. The vehicle is a fictional, unofficial interpretation; there are no imported manufacturer assets.

## Play on Windows

Unzip `ChodovLittleDrift-Windows-x64.zip` and open `ChodovLittleDrift.exe`. The executable contains the game data; Godot and Python are not required. Target: Windows 10/11 x64, OpenGL 3.3 capable graphics.

| Key | Action |
| --- | --- |
| Enter | Start / resume |
| W or Up | Accelerate |
| S or Down | Brake, then reverse |
| A/D or Left/Right | Steer, up to ±90 degrees |
| Space | Release almost all lateral grip |
| R | Reset to the shopping plaza |
| C | Cycle chase, high chase, and overhead camera |
| M | Toggle synthesized engine / tire sound |
| Escape | Pause / resume |
| Q in the menu | Quit |

Build a little speed, steer hard, then ease off the throttle and countersteer. The body rotates much faster than the velocity changes direction, so you can travel sideways. Hold Space to retain even more sideways momentum. This is arcade handling, not a realistic vehicle simulation.

Drifts above 22 km/h and 14° earn points. Longer slides build a multiplier up to 5×. Straighten up for 1.5 seconds to bank the chain; hitting a building loses the current chain. Roads and grass are deliberately equally slippery. Trees are scenery; shopping buildings and the world boundary have collision response.

## Develop

Open `project.godot` in Godot 4.6.3 and press F6/F5, or run:

```sh
godot --path . --editor --import --quit
godot --path .
```

No external assets, packages, credentials, or servers are needed. All geometry, UI, and audio are generated locally.

```sh
# Behaviour tests: 5 km length, steering, drift momentum, score, braking,
# reverse, collisions, boundary, reset, and pause.
godot --headless --path . --script res://tests/run_tests.gd
```

## Export

Install the **matching 4.6.3 export templates** through Godot's Manage Export Templates dialog. The included preset exports a single Windows x64 EXE with an embedded resource pack:

```sh
mkdir -p export
godot --headless --path . --export-release "Windows Desktop" export/ChodovLittleDrift.exe
```

The build is unsigned. Tests and development scripts are excluded from the exported game. See `LICENSES.txt` for engine attribution.

## Validation

19 automated behaviour checks passed, and title/gameplay rendering was inspected using Godot's OpenGL compatibility renderer on Linux. Windows export generation is validated separately. Native Windows execution has not been tested in this Linux environment.
