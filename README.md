# Hearthvale · The Eight Seasons

Restore a farm, get to know Willowbrook, and explore a pixel-art valley that changes across eight seasons. Hearthvale is an offline farming and village-life game built in Godot.

[Download for Windows x64](https://github.com/sean-camara/hearthvale/releases/latest) · [Gameplay](#gameplay) · [Screenshot gallery](#screenshot-gallery) · [Run from source](#run-from-source)

![Hearthvale farm with spring seedbeds, farmhouse, and hotbar](docs/screenshots/farm.jpg)

## Play

Download `Hearthvale-Windows-x64.zip` from the [latest release](https://github.com/sean-camara/hearthvale/releases/latest). Extract the whole archive and launch `Hearthvale.exe`. Keep `Hearthvale.pck` beside it. The game runs offline and saves automatically. Windows saves are stored in `%APPDATA%\Hearthvale Eight Seasons`.

Start with the seed parcel in the cottage. Prepare a bed, sow a Breakfast radish, water it, and sleep to advance the day. Ship the harvest for payment the next morning or bring a radish to Iona across the bridge.

| Input | Action |
| --- | --- |
| WASD or arrows · Shift | Walk · Run |
| E · Space · Left click | Interact · Work or reel in · Use the tool on a nearby target |
| 1–4 | Hoe, seeds, watering can, harvest basket |
| I · J · M · C | Satchel · Journal · Map · Workshop |
| Esc | Close a panel or pause |

Open **Pause → Comfort and controls** to rebind keys, enlarge text, or reduce impact camera motion.

## Gameplay

- **Farm through eight seasons.** Grow seasonal crops over a 168-day year, cook and preserve your harvest, and fill the village order book. The field sprinkler waters every prepared bed.
- **Change the valley by helping out.** Bring a crop, a fish, or building materials to Willowbrook’s weekly market. Restore the old orchard, rebuild the shortcut to Alderwood, or help Linn plant a patch in Elderwood.
- **Follow the water or go underground.** Practice casting with Oren, learn each fish’s tells, and record your best catches. Explore nine mine levels and two side chambers, where you can cut slate or fish in a lantern-lit pool.
- **Make a living your way.** Trade with village shops, brew fishing tonic and mining salve in Maelin’s apothecary, and open South Pasture to raise goats and sheep.
- **Explore at your own pace.** Pin a destination, follow signs and trails to real exits, or return in another season for discoveries like Mistfen’s Raincall boardwalk and Frostpine’s Snowrest crossing.

## Screenshot gallery

All images are captured in-game. The first three rows show the latest **Signs and Satchels** update. Further down are captures from earlier landscape, interior, and gameplay polish passes. Click an image for the full view.

| Journal overview | Satchel and item stacks |
| --- | --- |
| [![Latest journal with grouped project, field note, and people shortcuts](docs/screenshots/journal.jpg)](docs/screenshots/journal.jpg) | [![Latest satchel inventory grid with item stacks and filters](docs/screenshots/satchel.jpg)](docs/screenshots/satchel.jpg) |
| [![Latest arcade catalog with stock and prices](docs/screenshots/market.jpg)](docs/screenshots/market.jpg) | [![Compact interaction panel at the south orchard](docs/screenshots/orchard-panel.jpg)](docs/screenshots/orchard-panel.jpg) |
| **Farm Supply catalog** | **Compact orchard interaction** |
| [![Latest Elderwood field lodge and signage](docs/screenshots/elderwood.jpg)](docs/screenshots/elderwood.jpg) | [![Latest Goldenreach produce wagons and branching trails](docs/screenshots/goldenreach.jpg)](docs/screenshots/goldenreach.jpg) |
| **Elderwood lodge and signage** | **Goldenreach produce wagons** |


### Around the valley

| Willowbrook Village | Farmhouse interior |
| --- | --- |
| [![Willowbrook Village during the day](docs/screenshots/willowbrook.jpg)](docs/screenshots/willowbrook.jpg) | [![Farmhouse interior with a hearth, stove, and bed](docs/screenshots/cottage.jpg)](docs/screenshots/cottage.jpg) |
| [![Alderwood trail and stone bridge beside the pond](docs/screenshots/alderwood.jpg)](docs/screenshots/alderwood.jpg) | [![Mistfen boardwalk, lily pool, and stilt-house apothecary](docs/screenshots/mistfen.jpg)](docs/screenshots/mistfen.jpg) |
| **Alderwood bridge** | **Mistfen boardwalk** |
| [![Maelin’s alchemy room with shelves, a still, and a stained-glass window](docs/screenshots/alchemy.jpg)](docs/screenshots/alchemy.jpg) | [![South Pasture barns and paddocks with sheep and goats](docs/screenshots/pasture.jpg)](docs/screenshots/pasture.jpg) |
| **Maelin’s apothecary** | **South Pasture** |


### Farm work and exploration

| Watering a prepared bed | Restored orchard |
| --- | --- |
| [![Farmer watering a prepared bed](docs/screenshots/watering.jpg)](docs/screenshots/watering.jpg) | [![Restored orchard with grafted pear trees on the farm](docs/screenshots/orchard.jpg)](docs/screenshots/orchard.jpg) |
| [![Farmer landing a fish at Willow Creek](docs/screenshots/fishing.jpg)](docs/screenshots/fishing.jpg) | [![Portrait dialogue with Soren at Sunshore](docs/screenshots/conversation.jpg)](docs/screenshots/conversation.jpg) |
| **Landing a fish** | **Speaking with Soren** |
| [![Winter on the farm](docs/screenshots/snowrest.jpg)](docs/screenshots/snowrest.jpg) | [![Glowcap Caverns in Alderwood Mine](docs/screenshots/caverns.jpg)](docs/screenshots/caverns.jpg) |
| **Starfrost on the farm** | **Glowcap Caverns** |


[![Flooded mine side chamber with a fishing spot](docs/screenshots/flooded-spur.jpg)](docs/screenshots/flooded-spur.jpg)

*The flooded mine spur has its own fishing pool.*

## Run from source

1. Clone this repository and open `project.godot` in **Godot 4.7.2**.
2. Let the editor import the assets, then press **F5**. The project uses the Compatibility renderer.
3. To build a Windows ZIP yourself, install the matching Godot export templates, create a `dist` folder, and export the **Windows Desktop** preset. Distribute the executable and its PCK together.

From the project directory, you can also run these commands with the Godot console executable on your PATH.

```sh
godot --headless --editor --import
godot --headless --script tests/check.gd
godot --headless --script tests/menu_redesign.gd
godot --headless --script tests/homestead_life.gd
```

| Project files | Role |
| --- | --- |
| `main.tscn` and `project.godot` | Entry scene and engine settings |
| `scripts/` | Farm state and saves, world navigation, NPC schedules, menus, and game systems |
| `data/` | Crop definitions, shop and workshop data, and trail coordinates |
| `assets/` | Runtime pixel art, fonts, and audio |
| `tests/` | Model and scene regression checks |

The game uses original artwork, including generated art and hand-assembled pixel-art scenes. Font license notices are in `assets/fonts/`. The Windows distribution includes the Godot engine license and third-party notices. No reuse license has been specified for the game’s source or original artwork.

