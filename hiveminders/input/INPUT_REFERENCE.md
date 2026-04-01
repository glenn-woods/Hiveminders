# Input Bindings CSV Reference

## CSV Format

```
context,action,action_type,gamepad,keyboard_mouse
```

- context: name of the input context (e.g. base, isometric, third_person)
- action: unique action name within the context
- action_type: BOOL, AXIS, or VECTOR2
- gamepad: event tokens separated by ` | `
- keyboard_mouse: event tokens separated by ` | `

## Keyboard Tokens

Format: `key:<KeyName>`

Examples: `key:W`, `key:A`, `key:Space`, `key:Escape`, `key:Tab`, `key:Shift`, `key:E`

Uses Godot key names — single letters are uppercase (A-Z), special keys use their name.

## Mouse Tokens

Format: `mouse_button:<Index>`

| Index | Button |
|-------|--------|
| 1     | Left click |
| 2     | Right click |
| 3     | Middle click |
| 4     | Scroll up |
| 5     | Scroll down |

## Gamepad Button Tokens (Xbox layout)

Format: `joy_button:<Index>`

| Index | Xbox Button |
|-------|-------------|
| 0     | A |
| 1     | B |
| 2     | X |
| 3     | Y |
| 4     | LB (left bumper) |
| 5     | RB (right bumper) |
| 6     | Back / Select |
| 7     | Start |
| 8     | Left stick click (L3) |
| 9     | Right stick click (R3) |
| 10    | D-pad up |
| 11    | D-pad down |
| 12    | D-pad left |
| 13    | D-pad right |

## Gamepad Axis Tokens

Format: `joy_axis:<Axis>:<Value>`

| Axis | Direction          | Token |
|------|--------------------|-------|
| 0    | Left stick left    | `joy_axis:0:-1.0` |
| 0    | Left stick right   | `joy_axis:0:1.0` |
| 1    | Left stick up      | `joy_axis:1:-1.0` |
| 1    | Left stick down    | `joy_axis:1:1.0` |
| 2    | Right stick left   | `joy_axis:2:-1.0` |
| 2    | Right stick right  | `joy_axis:2:1.0` |
| 3    | Right stick up     | `joy_axis:3:-1.0` |
| 3    | Right stick down   | `joy_axis:3:1.0` |
| 4    | LT (left trigger)  | `joy_axis:4:1.0` |
| 5    | RT (right trigger) | `joy_axis:5:1.0` |

## Example Row

```
base,jump,BOOL,joy_button:0,key:Space
```

This binds "jump" in the "base" context to A button on gamepad and Space on keyboard.
