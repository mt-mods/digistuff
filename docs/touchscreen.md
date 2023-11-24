# Digilines Touchscreen

The touchscreen is designed to be a customizable interface for input and display, it allows creating a custom formspec using a series of digiline commands, usually from a Luacontroller.

- [Commands](#commands)
- [Combining commands](#combining-commands)
- [Supported formspec elements](#supported-formspec-elements)
- [Unsupported formspec elements](#unsupported-formspec-elements)
- [Formspec element reference](#formspec-element-reference)

## Commands

**`set`** - Changes settings.

```lua
digiline_send("touchscreen", {
	command = "set",
	locked = false,
	no_prepend = false,
	real_coordinates = false,
	fixed_size = false,
	width = 10,
	height = 8,
	focus = "<name>",
})
```

**`add`** - Adds an element, appending it after other elements.

```lua
digiline_send("touchscreen", {
	command = "add",
	element = "<element>",
})
```

**`insert`** - Adds an element at a specific index. The index can be any positive number.

```lua
digiline_send("touchscreen", {
	command = "insert",
	index = 1,
	element = "<element>",
})
```

**`replace`** - Replaces an existing element.

```lua
digiline_send("touchscreen", {
	command = "replace",
	index = 1,
	element = "<element>",
})
```

**`modify`** - Replaces specified values of an existing element.

```lua
digiline_send("touchscreen", {
	command = "modify",
	index = 1,
})
```

**`remove`** - Removes an element, shifting elements to fill the space.

```lua
digiline_send("touchscreen", {
	command = "remove",
	index = 1,
})
```

**`delete`** - Removes an element without changing element indexes.

```lua
digiline_send("touchscreen", {
	command = "delete",
	index = 1,
})
```

**`clear`** - Removes all elements.

```lua
digiline_send("touchscreen", {
	command = "clear",
})
```

## Combining commands

To save sending multiple digiline messages, commands can be combined into one message by sending them inside a table, like so:

```lua
digiline_send("touchscreen", {
	{command = "clear"},
	{command = "set", width = 3, height = 2},
	{command = "add", element = "label", X = 0.1, Y = 0.2, label = "Hello world!"},
	{command = "add", element = "button_exit", Y = 1.3, label = "Hello LUA!"},
})

```

## Supported formspec elements

The touchscreen uses formspec version 6 (Minetest 5.6.0+).

**Standard elements:**

- `tooltip`
- `image`
- `animated_image`
- `model`
- `item_image`
- `bgcolor`
- `background`
- `background9`
- `pwdfield`
- `field`
- `field_close_on_enter`
- `textarea`
- `label`
- `hypertext`
- `vertlabel`
- `button`
- `image_button`
- `item_image_button`
- `button_exit`
- `image_button_exit`
- `textlist`
- `tabheader`
- `box`
- `dropdown`
- `checkbox`
- `style`
- `style_type`

**Elements as settings:**

- `size`
- `no_prepend`
- `real_coordinates`
- `set_focus`

**Special elements:**

- `tooltip_area` - Separate element for the alternate syntax of `tooltip`.
- `table` - Combination of `table`, `tableoptions` and `tablecolumns`.
- `item_grid` - Helper for displaying a grid of item buttons or images.

## Unsupported formspec elements

These elements, for design or other reasons, are not supported by the touchscreen:

- `formspec_version`
- `position`
- `anchor`
- `padding`
- `container`
- `container_end`
- `scroll_container`
- `scroll_container_end`
- `scrollbar`
- `scrollbaroptions`
- `list`
- `listring`
- `listcolors`

## Formspec element reference

Example code for each of the supported formspec elements. For more details see the [Minetest Lua API](https://github.com/minetest/minetest/blob/master/doc/lua_api.md#elements).

All values except `command` and `element` are optional, with default values being used when a value is nil or invalid.

**`tooltip`**

```lua
digiline_send("touchscreen", {
	command = "add",
	element = "tooltip",
	element_name = "button",
	tooltip_text = "tooltip",
	bgcolor = "#303030",
	fontcolor = "#ffffff",
})
```

**`tooltip_area`**

```lua
digiline_send("touchscreen", {
	command = "add",
	element = "tooltip_area",
	X = 0,
	Y = 0,
	W = 100,
	H = 100,
	tooltip_text = "tooltip area",
	bgcolor = "#303030",
	fontcolor = "#ffffff",
})
```

**`image`**

```lua
digiline_send("touchscreen", {
	command = "add",
	element = "image",
	X = 0,
	Y = 0,
	W = 1,
	H = 1,
	texture_name = "default_dirt.png",
	middle = "",
})
```

**`animated_image`**

```lua
digiline_send("touchscreen", {
	command = "add",
	element = "animated_image",
	X = 0,
	Y = 0,
	W = 1,
	H = 1,
	name = "animated_image",
	texture_name = "default_lava_flowing_animated.png",
	frame_count = 16,
	frame_duration = 200,
	frame_start = 1,
	middle = "",
})
```

**`model`**

```lua
digiline_send("touchscreen", {
	command = "add",
	element = "model",
	X = 0,
	Y = 0,
	W = 2,
	H = 2,
	name = "model",
	mesh = "character.b3d",
	textures = {character.png},
	rotation_x = 0,
	rotation_y = 0,
	continuous = false,
	mouse_control = true,
})
```

**`item_image`**

```lua
digiline_send("touchscreen", {
	command = "add",
	element = "item_image",
	X = 0,
	Y = 0,
	W = 1,
	H = 1,
	item_name = "default:dirt_with_grass",
})
```

**`bgcolor`**

```lua
digiline_send("touchscreen", {
	command = "add",
	element = "bgcolor",
	bgcolor = "#ffffff",
	fullscreen = false,
	fbgcolor = "",
})
```

**`background`**

```lua
digiline_send("touchscreen", {
	command = "add",
	element = "background",
	X = 0,
	Y = 0,
	W = 0,
	H = 0,
	texture_name = "digistuff_ts_bg.png",
	auto_clip = true,
})
```

**`background9`**

```lua
digiline_send("touchscreen", {
	command = "add",
	element = "background9",
	X = 0,
	Y = 0,
	W = 0,
	H = 0,
	texture_name = "digistuff_ts_bg.png",
	auto_clip = true,
	middle = 3,
})
```

**`pwdfield`**

```lua
digiline_send("touchscreen", {
	command = "add",
	element = "pwdfield",
	X = 0,
	Y = 0,
	W = 3,
	H = 0.8,
	name = "pwdfield",
	label = "",
})
```

**`field`**

```lua
digiline_send("touchscreen", {
	command = "add",
	element = "field",
	X = 0,
	Y = 0,
	W = 3,
	H = 0.8,
	name = "field",
	label = "field",
	default = "",
})
```

**`field_close_on_enter`**

```lua
digiline_send("touchscreen", {
	command = "add",
	element = "field_close_on_enter",
	name = "field",
	close_on_enter = true,
})
```

**`textarea`**

```lua
digiline_send("touchscreen", {
	command = "add",
	element = "textarea",
	X = 0,
	Y = 0,
	W = 4,
	H = 3,
	name = "textarea",
	label = "",
	default = "",
})
```

**`label`**

```lua
digiline_send("touchscreen", {
	command = "add",
	element = "label",
	X = 0,
	Y = 0,
	label = "label",
})
```

**`hypertext`**

```lua
digiline_send("touchscreen", {
	command = "add",
	element = "hypertext",
	X = 0,
	Y = 0,
	W = 4,
	H = 3,
	name = "hypertext",
	text = "<i>hypertext</i>",
})
```

**`vertlabel`**

```lua
digiline_send("touchscreen", {
	command = "add",
	element = "vertlabel",
	X = 0,
	Y = 0,
	label = "vertlabel",
})
```

**`button`**

```lua
digiline_send("touchscreen", {
	command = "add",
	element = "button",
	X = 0,
	Y = 0,
	W = 3,
	H = 0.8,
	name = "button",
	label = "button",
})
```

**`image_button`**

```lua
digiline_send("touchscreen", {
	command = "add",
	element = "image_button",
	X = 0,
	Y = 0,
	W = 1,
	H = 1,
	texture_name = "default_stone_block.png",
	name = "image_button",
	label = "button",
	noclip = true,
	drawborder = true,
	pressed_texture_name = "",
})
```

**`item_image_button`**

```lua
digiline_send("touchscreen", {
	command = "add",
	element = "item_image_button",
	X = 0,
	Y = 0,
	W = 1,
	H = 1,
	item_name = "default:stone_block",
	name = "item_image_button",
	label = "",
})
```

**`button_exit`**

```lua
digiline_send("touchscreen", {
	command = "add",
	element = "button_exit",
	X = 0,
	Y = 0,
	W = 3,
	H = 0.8,
	name = "button_exit",
	label = "button",
})
```

**`image_button_exit`**

```lua
digiline_send("touchscreen", {
	command = "add",
	element = "image_button_exit",
	X = 0,
	Y = 0,
	W = 1,
	H = 1,
	texture_name = "default_mese_block.png",
	name = "image_button_exit",
	label = "button",
})
```

**`textlist`**

```lua
digiline_send("touchscreen", {
	command = "add",
	element = "textlist",
	X = 0,
	Y = 0,
	W = 4,
	H = 3,
	name = "textlist",
	listelements = {"a", "b", "c"},
	selected_id = 0,
	transparent = false,
})
```

**`tabheader`**

```lua
digiline_send("touchscreen", {
	command = "add",
	element = "tabheader",
	X = 0,
	Y = 0,
	name = "tabheader",
	captions = {"a", "b", "c"},
	current_tab = 0,
	transparent = false,
	draw_border = false,
})
```

**`box`**

```lua
digiline_send("touchscreen", {
	command = "add",
	element = "box",
	X = 0,
	Y = 0,
	W = 1,
	H = 1,
	color = "#ffffff",
})
```

**`dropdown`**

```lua
digiline_send("touchscreen", {
	command = "add",
	element = "dropdown",
	X = 0,
	Y = 0,
	W = 3,
	H = 0.8,
	name = "dropdown",
	choices = {"a", "b", "c"},
	selected_id = 0,
	index_event = false,
})
```

**`checkbox`**

```lua
digiline_send("touchscreen", {
	command = "add",
	element = "checkbox",
	X = 0,
	Y = 0,
	name = "checkbox",
	label = "checkbox",
	selected = false,
})
```

**`style`**

```lua
digiline_send("touchscreen", {
	command = "add",
	element = "style",
	selectors = {
		"button_name",
	},
	properties = {
		border = false,
	},
})
```

**`style_type`**

```lua
digiline_send("touchscreen", {
	command = "add",
	element = "style_type",
	selectors = {
		"button",
	},
	properties = {
		border = false,
	},
})
```

**`table`**

```lua
digiline_send("touchscreen", {
	command = "add",
	element = "table",
	X = 0,
	Y = 0,
	W = 4,
	H = 3,
	name = "table",
	cells = {"a", "b", "c"},
	selected_id = 0,
	color = "#ffffff",
	background = "#000000",
	border = true,
	highlight = "#466432",
	highlight_text = "#ffffff",
	opendepth = 0,
	columns = {
		{type = "text", align = "center"},
	},
})
```

**`item_grid`**

- `W` and `H` are the size of the grid in number of items.
- `name` is a prefix for the buttons, which are numbered with their index. (e.g. `grid_1`, `grid_2`, ...)
- `size` is the size of the buttons. Used for width and height.
- `spacing` is the space between buttons. Used for vertical and horizontal spacing.
- `interactable` determines whether buttons or images are used.
- `offset` is for paginating the list of items.

```lua
digiline_send("touchscreen", {
	command = "add",
	element = "item_grid",
	X = 0,
	Y = 0,
	W = 1,
	H = 1,
	name = "grid",
	spacing = 0,
	size = 1,
	interactable = true,
	items = {
		"default:dirt 99",
	},
	offset = 1,
})
```
