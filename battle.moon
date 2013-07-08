
import insert from table
{graphics: g} = love
{:min, :max} = math

import Frame, RedBar, BlueBar, VerticalList, MenuStack from require "dialog"

local *

class CharacterFrame extends Frame
  new: (@char) =>
    super 0,0, 100, 50

  draw: =>
    super!
    g.push!
    g.translate @x, @y

    g.setFont fonts.thick_font

    p @char.name, 4, 4

    g.setFont fonts.main_font

    g.pop!

  update: (dt) =>

class ActionsMenu extends VerticalList
  new: (...) =>
    super {
      "Attack"
      "Defend"
      "Magic"
    }, ...

class Battle extends MenuStack
  viewport: Viewport scale: 2

  frame_pos: {200, 10}

  new: (@game) =>
    super!
    @map = TileMap.from_tiled "maps.battle"

    @add "actions", ActionsMenu 10, 10, 100, 100

    @frames = for char in *@game.party.characters
      CharacterFrame char

  on_key: (key) =>
    if key == "b"
      DISPATCH\pop!
      return true

    super key

  update: (dt) =>
    super dt
    for frame in *@frames
      frame\update dt

  draw: =>
    @viewport\apply!
    @map\draw!

    super @viewport

    g.push!
    g.translate unpack @frame_pos
    for frame in *@frames
      frame\draw!

    g.pop!

    @viewport\pop!


{ :Battle }
