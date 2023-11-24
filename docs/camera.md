# Digilines Camera

The camera looks at a node in front of it, detecting players within a radius of that node, and sending a resulting list of names via digilines.

## Basic usage

Set a channel, radius and distance. The radius must be between 1 and 10, and the distance must be between 0 and 20.

The camera will search for a node "distance" nodes in front of it and up to 10 nodes down. Every second while a player is within the radius of that node, a table listing the players in range will be sent via digilines on the chosen channel.

This functionality can be toggled by clicking the "Disable" or "Enable" button.

## Commands

Similar to the `mesecons` node detector, a digiline command can be sent to retrieve the list of players on demand.

```lua
digiline_send("detector", {command = "get"})

-- A string also works
digiline_send("detector", "get")
```

The radius and distance can also be set by digilines.

```lua
digiline_send("detector", {radius = 1, distance = 0})
```
