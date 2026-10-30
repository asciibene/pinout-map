# Pinout app
## Adding boards

Add one `.json` file per board inside `assets/boards/`. The app loads all JSON
assets in that directory and builds the board cards and pin details from them.
Each file must have this structure:

```json
{
  "id": "board-id",
  "name": "Board name",
  "category": "Board category",
  "microcontroller": "Microcontroller name",
  "image": "assets/images/boards/board.jpg",
  "pins": [
    {
      "number": 1,
      "name": "GPIO0",
      "type": "GPIO",
      "description": "Pin description"
    }
  ]
}
```

`number` is a board-specific pin index; on Raspberry Pi and Pico boards it is
the physical header position. `name` retains the board's printed pin label.
`type` is one of `POWER`, `GND`, `ADC`, `UART`, `SPI`, `GPIO`, or `CTRL`.
Use `CTRL` for reset, enable, and boot-configuration pins; descriptions should
include active levels and relevant restrictions when known. Pin descriptions
can also include multiplexed functions. Set `image` to an empty string when no
matching board image is available.

## Personal pin notes

Tap a pin in a board's detail view to add, edit, or delete a personal note.
On native platforms, notes are stored locally in the app's support directory
at `pinout_notes/<board-id>.json`, with one JSON file per board. Notes stay on
the device and are not included in the board asset files.
Each file stores notes keyed by the board-specific pin number:

```json
{
  "boardId": "board-id",
  "notes": {
    "1": "Connect this pin to the sensor's SDA line"
  }
}
```

In the web app, notes are stored in browser local storage as one JSON entry per
board because browsers do not provide apps with a private filesystem.

## Pin capability indicators

The board detail view displays compact icons for digital I/O, ADC, I²C, SPI,
UART, PWM, touch sensing, and external interrupts when those functions are
identified in a pin's type or description. Tap or focus an icon to read its
label. Indicators reflect only the information present in the board data; an
unlisted capability is not necessarily unsupported.
