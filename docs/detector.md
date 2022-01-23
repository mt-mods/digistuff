# Digilines Player Detector

The player detector detects players within a radius, sending a resulting list of names via digilines.

## Basic usage

Set a channel and radius. The radius must be between 1 and 10.

Every second while a player is within the radius, a table listing the players in range will be sent via digilines on the chosen channel.

This functionality can be toggled by clicking the "Disable" or "Enable" button.

## Commands

Similar to the `mesecons` node detector, a digiline command can be sent to retrieve the list of players on demand.

```lua
digiline_send("detector", {command = "get"})

-- A string also works
digiline_send("detector", "get")
```

The radius can also be set by digilines.

```lua
digiline_send("detector", {radius = 6})
```
