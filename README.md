
Lovecat: Game Parameter Editing
===============================

Lovecat is a tool to help improving your game development productivity. Using
Lovecat, you can edit your game parameters in a browser, and see the changes
in the running game in real time.

This tool is originally created for LÖVE game projects, but is also applicable
whenever Lua and LuaSocket are available.

Demo
----

* Make sure you have LÖVE (>= 0.9.2) installed
* Download the latest release package of Lovecat
* Run the example LÖVE project in the release package
* Open your browser at http://127.0.0.1:7000
* Play with the browser-based UI, and watch for changes in the game window
* (Optional) Try the same website from a tablet device

Tutorial
--------

### Setup

To setup Lovecat in your LÖVE project, a minimal example is like:

```
function love.load()
    lovecat = require 'lovecat'
    lovecat.reload()
end

function love.update(dt)
    lovecat.update(dt)
    -- other updates
end

function love.draw()
    local ax, ay = unpack(lovecat.point.Example.a)
    local bx, by = unpack(lovecat.point.Example.b)
    local function f(x) return 300+x*300 end
    love.graphics.line(f(ax), f(-ay), f(bx), f(-by))
end
```

### Game Parameters

With Lovecat, you edit your game by editing game parameters. Game parameters
can represent the amount of gravity, a polygon shape of a game object, a tile
map, etc. Generally, a game parameter can be anything that is a constant to
the game program, and usually requires careful tunning.

A Lovecat parameter is referenced by a scoped name. For example, each of the
following expressions references one game parameter.

```
lovecat.number.gravity
lovecat.color.sky
lovecat.point.SceneA.BigCat.left_eye
lovecat.point.SceneA.BigDog['right_eye']
lovecat.point.SceneA['BigDog'].left_eye
lovecat.point.SceneA.BigDog.right_eye
lovecat.point.BigDog.LeftEyeShape[0]
lovecat.point.BigDog.LeftEyeShape[1]
lovecat.point.BigDog.LeftEyeShape[2]
...
lovecat.point.BigDog.LeftEyeShape[10]
```

Parameters are used without prior declaration. When a parameter is first
referenced, it will be assigned a default value.

### Parameter Types

Lovecat offers the following primitive parameter types.

| Type    | Meaning                                  | Example value               |
|:-------:|------------------------------------------|-----------------------------|
| number  | a floating number in [0, 1]              | `0.71234`                   |
| point   | a 2D point in a square                   | `{-0.923, 0.433}`           |
| color   | a color                                  | `{183.134, 75.034, 1.030}`  |
| grid    | an infinite grid of ASCII characters     | `{{-1,3,'a'}, {4,-12,'b'}}` |

Notes:

* point values are in the form `{x, y}`, where both `x` and `y` are in [-1,1];

* color values are in HSV color space, and (H,S,V) components are in [0,360),
  [0,100], [0,100] repectively. Outstanding bug: color space and gamma
  correction are not treatedly seriously at this time. (I am considering to
  switch to sRGB, as it is better defined);

* grid values are a list of `{x, y, character}`, where `character` is a
  non-space printable ASCII character.

### Parameter Namespaces

Lovecat parameters are organized in hierarchical namespaces. There is one root
namespace for each parameter type:

```
lovecat.number
lovecat.point
lovecat.color
lovecat.grid
```

Namespace names are recognized with a starting capital letter. Namespaces
can be freely manipulated:

```
print(lovecat.point.SceneA)
print(lovecat.point.SceneA == lovecat.point.SceneA)
print(lovecat.point['SceneA'] == lovecat.point.SceneA)
print(lovecat.point.SceneA ~= lovecat.point.SceneB)

local scene = lovecat.point.SceneA
print(unpack(scene.BigCat.left_eye))
print(unpack(scene.BigDog.right_eye))
```

### Parameter Blending

When you need some parameter type that is not directly supported by Lovecat,
you can try blending existing ones. For example, when you need a number
parameter in the range `[1000, 2000]`, you can do this:

```
local x = lovecat.number.gravity_size
local x_blended = x * 1000 + 1000
```

By providing only primitive parameters, the library size is kept small, while
Lovecat parameters can be used for a large variety of purposes.

### Working with Hot-Reloading

In conjunction with Lovecat, it is recommended you watch and hot-reload your
game program and assets. See the demo for a program hot-reloading example,
which uses a modified [cupid](https://bitbucket.org/basicer/cupid/).

When hot-reloading your program, care must be taken:

* Lovecat library must never be reloaded;
* instead, call `lovecat.reload()` if you want to reset Lovecat's internal states (e.g. registered watchers);
* a change of Lovecat data file should not trigger a program hot-reload.

### Data File

Lovecat parameters are saved to a data file with a delay. **Backup your data
file often** (you can use a VCS), as it may contain valuable information of
your game. The data file itself is a valid Lua program, and is intended as a
drop-in replacement for the Lovecat library. So you can ship your game with
only the data file.

```
package.path = '?.txt;' .. package.path

-- lovecat = require 'lovecat'
lovecat = require 'lovecat-data'
```

### Watch for Parameter Changes

Most of the time you'll want to refetch Lovecat parameter values in each
frame, so when Lovecat updates a parameter, it takes effect automatically. But
sometimes, getting notified of parameter changes can be helpful.

* `lovecat.watch_add(ns, func)`

    Whenever a parameter in `ns` changes, `func(namespace, parameter_name)` is
    called.

* `lovecat.watch_remove(ns, [func])`

    Remove the `func` watcher at `ns`. If `func` is omitted, every watcher
    registered at `ns` is removed.

### Other Tips

#### UI Hotkeys

| Type    | Key or Operation            | Effect                            |
|:-------:|-----------------------------|-----------------------------------|
| point   | `t`                         | Toggle showing/hiding data labels |
| color   | `t`                         | Toggle showing/hiding data labels |
| color   | `1` `2` `3`                 | Switch to `HS` `HV` or `SV`       |
| grid    | `right mouse drag`          | Panning                           |
| grid    | `Ctrl-left mouse drag`      | Panning                           |
| grid    | `Ctrl-U` `Ctrl-H`           | Undo                              |
| grid    | `Ctrl-R` `Ctrl-L`           | Redo                              |
| grid    | `Ctrl-O`                    | Return to the origin              |

#### Tablets

Tablets are supported, although with a smaller feature set.

#### Configuration

There are some configuration parameters at the beginning of `lovecat.lua`.

Background
----------

Lovecat is inspired by Bret Victor's Inventing on Principle, and
[lovebird](https://github.com/rxi/lovebird).

License
-------

MIT
