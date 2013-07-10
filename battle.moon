
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


class BattleEnemey extends Box
  name: "Butt"
  w: 10
  h: 20

  -- put x, y at feet
  new: (x, y) =>
    @x = x - @w / 2
    @y = y - @h

  draw: =>
    g.setColor 255,0,0
    g.rectangle "line", @unpack!
    g.setColor 255,255,255

  update: (dt) =>

class Battle extends MenuStack
  viewport: Viewport scale: 2

  new: (@game) =>
    super!
    @map = TileMap.from_tiled "maps.battle", {
      object: (obj) ->
        if obj.name = "enemy_drop"
          @enemy_drop = Box obj.x, obj.y, obj.width, obj.height
    }

    @enemies = for ex, ey in @distribute_enemies 2
      print "Placing #{ex}, #{ey}"
      BattleEnemey ex, ey

    @char_frame = CharacterFrame @, @game.party.characters

    w = @viewport.w - @char_frame.w - 15
    h = CharacterFrame.h
    @add "actions", ActionsMenu @, 5, @viewport\on_bottom(h, CharacterFrame.margin), w, h

    @frames = { @char_frame }

  distribute_enemies: (num, box=@enemy_drop) =>
    y = coroutine.yield
    coroutine.wrap ->
      switch num
        when 1
          y box\center!
        when 2
          cx, cy = box\center!
          y cx, cy - box.w / 4
          y cx, cy + box.w / 4

  on_key: (key) =>
    if key == "b"
      DISPATCH\pop!
      return true

    super key

  update: (dt) =>
    super dt
    for frame in *@frames
      frame\update dt

    for enemy in *@enemies
      enemy\update dt

  draw: =>
    g.setFont fonts.thick_font
    @viewport\apply!
    @map\draw!

    super @viewport

    for frame in *@frames
      frame\draw!

    for enemy in *@enemies
      enemy\draw!

    @viewport\pop!
    g.setFont fonts.main_font


{ :Battle }
