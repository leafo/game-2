
import insert from table
{graphics: g} = love
{:min, :max} = math

import Frame, RedBar, BlueBar, VerticalList, MenuStack from require "dialog"

local *

rotate = (array) ->
  first = array[1]
  for i=2,#array
    array[i - 1] = array[i]

  array[#array] = first
  array

class BattleOrder
  capacity: 100 -- progress to needed to make action

  new: (@entities) =>
    @queue = if @entities.__class == BattleOrder
      -- clone it
      for {:progress, :entity} in *@entities.queue
        {:progress, :entity}
    else
      for e in *@entities
        { progress: 0, entity: e }

  elapse: =>
    -- find out how much time to elapse
    local to_elapse
    for {:entity, :progress} in *@queue
      t = (@capacity - progress) / entity.speed
      if to_elapse == nil or t < to_elapse
        to_elapse = t

    -- increment all the progress, find the greatest one
    -- doesn't just check for capacity to make sure we find something
    local max_tuple
    for tuple in *@queue
      tuple.progress += tuple.entity.speed * to_elapse

      if max_tuple == nil or tuple.progress > max_tuple.progress
        max_tuple = tuple

    -- rotate the queue so things with same speed can come in different orders
    rotate @queue
    max_tuple.progress -= @capacity
    max_tuple.entity

class OrderList extends Box
  w: 280
  h: 20
  x: 35
  y: 5

  num_items: 5

  new: (@parent) =>
    @recalc!
    moon.p @order

  update: (dt) =>

  draw_entity: (e) =>
    g.setColor hash_to_color e.name
    g.rectangle "fill", 0,0, 20, 20
    g.setColor 255,255,255
    p e.name\sub(1, 2), 2,2

  draw: =>
    p "Next", 5, 11
    g.push!
    g.translate @x, @y
    for e in *@order
      @draw_entity e
      g.translate 25, 0

    g.pop!

  recalc: =>
    order = BattleOrder @parent.order
    @order = for i=1,@num_items
      order\elapse!

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
  mixin Sequenced

  padding_top: Frame.padding
  padding_left: Frame.padding

  alpha: 255

  draw_frame: =>
    @frame\draw!

  on_select: (item) =>
    @parent\elapse_turn item

  new: (@parent, x,y,w,h) =>
    @frame = Frame 0,0, w,h
    super {
      "Attack"
      "Defend"
      -- "Magic"
    }, x,y,w,h

    @max_height = @h

  slide_up: =>
    @add_seq Sequence ->
      @disabled = true
      tween @, 0.1, h: 0
      @hidden = true

  slide_down: =>
    @add_seq Sequence ->
      @disabled = false
      @hidden = false
      tween @, 0.1, h: @max_height

  update: (dt) =>
    @frame.h = @h

  draw: (...) =>
    return if @hidden
    super ...


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
      BattleEnemey ex, ey

    @order = BattleOrder @game.party.characters

    @char_frame = CharacterFrame @, @game.party.characters

    w = @viewport.w - @char_frame.w - 15
    h = CharacterFrame.h

    @add "actions", ActionsMenu @, 5, @viewport\on_bottom(h, CharacterFrame.margin), w, h

    @order_list = OrderList @

    @frames = {
      @char_frame
      @order_list
    }

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

        when 3
          cx, cy = box\center!
          w4 = box.w / 4

          y cx + w4, cy
          y cx - w4, box.y
          y cx - w4, box.y + box.h

        when 4
          cx, cy = box\center!
          w4 = box.w / 4
          h4 = box.h / 4


          y cx - w4, cy - h4
          y cx - w4, cy + h4

          y cx + w4, cy - h4
          y cx + w4, cy + h4


        else
          error "not yet"

  elapse_turn: (action) =>
    print "Running action", action, @order\elapse!
    @order_list\recalc!

  on_key: (key) =>
    if key == "b"
      DISPATCH\pop!
      return true

    if key == "t"
      print "toggle menu"
      @menus.actions\slide_up!

    if key == "y"
      print "toggle menu"
      @menus.actions\slide_down!

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

if ... == "test"
  moon = require "moon"

  e = (name, speed) -> :name, :speed

  order = BattleOrder {
    e "Leaf", 89 * 1.3
    e "Monster", 70
    e "Arkeus", 74
  }

  for i=1,10
    nxt = order\elapse!
    print "#{nxt.name}, #{nxt.speed}"


{ :Battle }
