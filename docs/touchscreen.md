# Digilines Touchscreen

The touchscreen is designed to be a customizable interface for input and display, it allows creating a custom formspec using a series of digiline commands, usually from a Luacontroller.

- [Commands](#commands)
- [Supported formspec elements](#supported-formspec-elements)
- [Unsupported formspec elements](#unsupported-formspec-elements)

## Commands

**`add`** - Adds an element, appending it after other elements.

```lua
digiline_send("touchscreen", {
	command = "add",
	element = "<element>",
})
```

**`insert`** - Adds an element at a specific index.

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

**`remove`** - Removes an element.

```lua
digiline_send("touchscreen", {
	command = "remove",
	index = 1,
})
```

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

## Supported formspec elements

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

- `tooltip_area`
  Separate element for the alternate syntax of `tooltip`.
- `table`
  Combination of `table`, `tableoptions` and `tablecolumns`.
- `item_grid`
  Helper for displaying a grid of item buttons or images.

## Unsupported formspec elements

These elements, for design or other reasons, are not supported by the touchscreen:

- `formspec_version`
- `position`
- `anchor`
- `container`
- `container_end`
- `scroll_container`
- `scroll_container_end`
- `scrollbar`
- `scrollbaroptions`
- `list`
- `listring`
- `listcolors`
