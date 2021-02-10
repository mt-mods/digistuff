# Digilines Stuff [digistuff]

## License:

Code - LGPL v3 or later (contains some code from mesecons and digilines)
Textures WITHOUT "adwaita" in the file name - CC BY-SA 3.0 Generic (contains modified versions of textures from mesecons and digilines)
Textures WITH "adwaita" in the file name - These are icons by the GNOME Project, licensed under GNU LGPL v3 or CC BY-SA 3.0.

### Depends:

Required: digilines (base only) and mesecons (base only)
Optional: mesecons_noteblock (for digilines noteblock), mesecons_mvps (for digilines piston and movestone), mesecons_luacontroller (for I/O expander)
Only needed for craft recipes: default, basic_materials

### How to use digilines buttons:

Connect to a digiline (or digimese), right-click, and set a channel and message.
When the button is pressed (right-click), it will send that message on that channel, over digilines.
If the "Protected" checkbox is checked, only players allowed to interact in the area can push the button.
If the "Manual Light Control" checkbox is checked, the light will not illuminate automatically when the button is pushed - use the "light_on" and "light_off" commands to control it.
Note that the settings cannot be changed after setting - you must dig and re-place the button to do so.

### How to use the wall knob:

Connect to a digiline, right-click, and set the channel and the minimum and maximum values.
Left-click to decrease the current setting or right-click to increase it. If the "protected" checkbox was checked, then only players allowed to interact in the area can do this.
Each time the setting is changed, the new setting is sent on the selected channel.
Note that the settings cannot be changed after setting - you must dig and re-place the knob to do so.

### How to use digimese:

It conducts digilines signals (like digilines) in all directions (like mese). That's about it, really.

### How to use vertical/insulated digilines:

These work exactly like the mesecons equivalents, that is:
Vertical digilines will automatically connect to other vertical digilines directly above or below them, and form "plates" on each end of the stack. Signals can only be conducted into or out of the stack at these "plates".
Insulated digilines conduct like regular digilines, but only into/out of the ends of the "wire" or at locations where an intermediate connection has been placed.

### How to use the digilines player detector:

Set a channel and radius (radius must be a number >0 and <10 - anything invalid will be ignored and "6" used instead).
Every second while a player is within the radius, a table listing the players in range will be sent via digilines on the chosen channel.

### How to use the digilines control panel:

Once a channel is set, any messages sent on that channel will be shown on the "LCD". The buttons, when pressed, send the messages "up", "down", "left", "right", "back", and "enter" on the same channel. If the panel is placed in a protected area (all standard protection mods are supported), only the owner of the area (and players with the protection_bypass privilege) can set the channel. There is also a "lock" function in the bottom-right of the "LCD" area. Click the padlock icon to lock/unlock it. If locked, only the owner of the area is allowed to use the buttons. If unlocked, anyone can use the buttons, although channel setting and (for reasons that shuld be obvious) locking/unlocking is still limited to the area owner and players with protection_bypass.

### How to use the NIC:

Send a digilines signal with the URL you want to download. The HTTPRequestResult table will be sent back on the same channel.

### How to use the camera:

Set the channel, distance, and radius. The camera will search for a node "distance" meters away and up to 10m down.
Every second while a player is within "radius" meters of that point, a table listing the players in range will be sent via digilines on the chosen channel.

### How to use the dimmable lights:

After setting the channel, send a number from 0 to 14 to set the light level.

### How to use the timer:

Send a number representing a time in seconds, from 0.5 to 3600. When the time expires, the timer will send "done" back on the same channel. If the loop feature is enabled (use the commands "loop_on" and "loop_off" to set this) the timer will automatically be set for the same time again each time it expires.

### How to use the junction box:

These are just plain digilines conductors (like digimese) but can skip over one node to another junction box or certain other nodes.
As in, [digiline][junction box][dirt][junction box][digiline] will work to transmit signals "through" the dirt.

### How to use the I/O expander:

After setting a channel, send a table (same format as a Luacontroller's "port" table) to set the output states.
A table in this same format will be sent back whenever an input changes or you manually poll it by sending a "GET" message.

### How to use the card reader:

After setting a channel, swiping a card (punch the reader with the card to swipe) will send a message in the following format:
    {event = "read",data = "The data that was on the card"}
To write a card, send a command in the following format:
    {command = "write",data = "The data to put on the card",description = "A description of what the card is for"}
After sending the write command, swipe the card to be written and the reader will send back the following message:
    {event = "write"}
Both blank and previously written cards can be written to. If the card was not blank, it will be overwritten.

### How to use the game controller:

After setting a channel, right-click the controller to start/stop using it.
While using a controller, it will send a table with the control inputs, pitch, yaw, look vector, and name of the player using the controller each time one of these values changes, up to 5 times per second.
When a player leaves a controller, the string "player_left" is sent.
In addition to right-clicking the controller in use to stop using it, the following will also cause a player to stop using the controller:

* The controller is moved or removed
* The player leaves the game
* The player is teleported away from the controller
* The controller receives the string "release" on its digilines channel

### How to use the RAM and EEPROM chips:

First, set a channel.
Messages should consist of a table, with "command" set to either "read" or "write". "address" should be set to the number (0-31) of the 512-character block to read or write, and if writing then "data" should contain the data to write.
Example (to write - reading is similar, but with no data):
    {command = "write",address = 7,data = "9a91a9e451b94dc262972557ab0d406f"}

The RAM and EEPROM chips behave identically, except that the RAM chip loses its contents when dug whereas the EEPROM does not.

### How to use the 2D graphics processor:

Please see gpu.txt for information on this part.

### How to use the digilines pistons:

The following commands are accepted as strings: "extend" (extend the piston), "retract" (retract the piston), and "retract_sticky" (retract the piston, pulling one node like a sticky piston)
You can also send a command as a table. If so, the fields that can be used in the table are as follows:

* action: "extend" or "retract"
* max: The maximum number of nodes to push/pull, cannot be set higher than 16. Set to 0 (or omit) when retracting to perform a non-sticky retraction.
* allsticky: Pull a whole stack of nodes (like movestone), not just one.
* sound: The sound to make. "mesecons" for the mesecons piston sounds, "digilines" for the digilines piston sounds (default), or "none" for no sounds at all.

### How to use the digilines movestone:

Commands for this node are in the form of a table, with the field "command" set to the desired action, and other fields providing parameters.
The commands are as follows:

* "getstate": Returns a table containing the following elements: "targetpos" (table representing the target position), "pos" (table representing the current position), and "moveaxis" (the current axis being moved along, nil if not moving)
* "absmove": Moves to the absolute position specified by "x" "y" and "z". No axis can move more than 50m as a result of one command. If movements along more than one axis are needed, they are processed in alphabetical order (X,Y,Z).
* "relmove": Same as absmove, but relative to the current position (for example, y=1 moves up 1m, not *to* Y=1)
  The available parameters for absmove and relmove are:
* x: Target X position (for absmove) or target change in X position (for relmove)
* y: Same, but for Y
* z: Same, but for Z
* sticky: Whether to pull nodes along behind the movestone
* allsticky: Whether to pull a full stack of nodes like normal movestone (true) or just one like a sticky piston (false)
* maxstack: The maximum number of nodes to push/pull, with the movestone itself counting as 1. Cannot be set higher than 50.
* sound: "mesecons" to have the mesecons movestone sound play or "none" for no sound at all
  If any of x/y/z are omitted, then they default to the current position (for absmove) or 0 (for relmove).
  If any of maxstack/sticky/allsticky/sound are omitted, they default to the values last used.
