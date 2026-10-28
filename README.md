# Pinout app

A new Flutter project created with FlutLab - https://flutlab.io

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

## Getting Started

A few resources to get you started if this is your first Flutter project:

- https://flutter.dev/docs/get-started/codelab
- https://flutter.dev/docs/cookbook

For help getting started with Flutter, view our
https://flutter.dev/docs, which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Getting Started: FlutLab - Flutter Online IDE

- How to use FlutLab? Please, view our https://flutlab.io/docs
- Join the discussion and conversation on https://flutlab.io/residents
