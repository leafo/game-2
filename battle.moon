
import insert from table
{graphics: g} = love
{:min, :max} = math

import Frame, RedBar, BlueBar, VerticalList, MenuStack from require "dialog"

local *

class CharacterFrame extends Frame
  margin: 5
  char_width: 70
  h: 35

  new: (@parent, @chars) =>
    import viewport from @parent
    w = (@char_width * #@chars) + 8

    super viewport\on_right(w, @margin), viewport\on_bottom(@h, @margin), w, @h

    @health_bars = for char in *@chars
      RedBar 0, 10, @char_width, 0.5

    @mana_bars = for char in *@chars
      BlueBar 0, 20, @char_width, 0.5

  draw_char_row: (i, char) =>
    g.push!
    g.translate 4 + (i - 1) * @char_width, 4

    p char.name, 0, 0
    @health_bars[i]\draw!
    @mana_bars[i]\draw!

    g.pop!

  draw: =>
    super!
    g.push!
    g.translate @x, @y


    for i, char in ipairs @chars
      @draw_char_row i, char


    g.pop!

  update: (dt) =>

class ActionsMenu extends VerticalList
  padding_top: Frame.padding
  padding_left: Frame.padding

  draw_frame: =>
    @frame\draw!

  new: (@parent, x,y,w,h) =>
    @frame = Frame 0,0, w,h
    super {
      "Attack"
      "Defend"
      -- "Magic"
    }, x,y,w,h


class Battle extends MenuStack
  viewport: Viewport scale: 2

  new: (@game) =>
    super!
    @map = TileMap.from_tiled "maps.battle"

    @char_frame = CharacterFrame @, @game.party.characters

    w = @viewport.w - @char_frame.w - 15
    h = CharacterFrame.h
    @add "actions", ActionsMenu @, 5, @viewport\on_bottom(h, CharacterFrame.margin), w, h

    @frames = { @char_frame }

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
    g.setFont fonts.thick_font
    @viewport\apply!
    @map\draw!

    super @viewport

    for frame in *@frames
      frame\draw!

    @viewport\pop!
    g.setFont fonts.main_font


{ :Battle }
