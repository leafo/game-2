
import insert from table
{graphics: g} = love
{:min, :max} = math

import
  Frame, RedBar, BlueBar, VerticalList, MenuStack, BaseList
  from require "dialog"

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
    COLOR\push hash_to_color e.name
    g.rectangle "fill", 0,0, 20, 20
    COLOR\pop!
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
  fade_time: 0.2

  draw_frame: =>
    @frame\draw!

  on_select: (item) =>
    @parent\elapse_turn item

  x: 5
  y: 140
  w: 87
  h: 35

  new: (@parent) =>
    @frame = Frame 0,0, @w, @h
    super {
      "Attack"
      "Defend"
      -- "Magic"
    }

    @max_height = @h
    -- @hide true

  hide: (immediate=false) =>
    if immediate
      @h = 0
      @alpha = 0
      @hidden = true
      @disabled = true
      return

    @add_seq Sequence ->
      @disabled = true
      tween @, @fade_time, h: 0, alpha: 0
      @hidden = true

  show: =>
    @add_seq Sequence ->
      @disabled = false
      @hidden = false
      tween @, @fade_time, h: @max_height, alpha: 255

  update: (dt) =>
    @frame.h = @h

  on_key: (...) =>
    return if @hidden
    super ...

  draw: (...) =>
    return if @hidden
    COLOR\pusha @alpha
    super ...
    COLOR\pop!


class BattleEnemy extends Box
  name: "Butt"
  w: 10
  h: 20

  -- put x, y at feet
  new: (_, x, y) =>
    @x = x - @w / 2
    @y = y - @h

  draw: =>
    @outline COLOR.red

  update: (dt) =>

class BattleCharacter extends Box
  w: 10
  h: 20

  new: (@char, x, y) =>
    @name = @char.name
    @x = x - @w / 2
    @y = y - @h

  draw: =>
    @outline COLOR.green

  update: (dt) =>


-- a group of things on the field, like the group of players or the group of
-- enemies
class EntityGroup extends BaseList
  flip_x: false

  new: (...) =>
    super ...
    @items = {} -- is overwritten

  draw: =>
    for e in *@items
      e\draw!

  update: (dt) =>
    for e in *@items
      e\update dt

  add: (items) =>
    cls = @etype
    pos = @distribute #items, @

    @items = for item in *items
      cls item, pos!

  distribute: (num, box, flip_x=@flip_x) =>
    y = coroutine.yield
    if flip_x
      cx = box\center!
      y = (x,y) ->
        coroutine.yield cx + (cx - x), y

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
          error "don't know how to distribute #{num} entities"

class EnemyGroup extends EntityGroup
  etype: BattleEnemy

class CharacterGroup extends EntityGroup
  flip_x: true
  etype: BattleCharacter

class Battle extends MenuStack
  viewport: Viewport scale: 2

  new: (@game) =>
    super!
    @map = TileMap.from_tiled "maps.battle", {
      object: (obj) ->
        switch obj.name
          when "enemy_drop"
            @enemy_group = EnemyGroup obj.x, obj.y, obj.width, obj.height
          when "character_drop"
            @char_group = CharacterGroup obj.x, obj.y, obj.width, obj.height
    }

    assert @enemy_group, "Failed to create enemy group"
    assert @char_group, "Failed to create character group"

    @enemy_group\add { {}, {} }
    @char_group\add @game.party.characters

    @order = BattleOrder @game.party.characters
    @char_frame = CharacterFrame @, @game.party.characters

    @add "actions", ActionsMenu @
    @add "characters", @char_group
    @add "enemies", @enemy_group

    @order_list = OrderList @

    @frames = {
      @char_frame
      @order_list
    }


  elapse_turn: (action) =>
    print "Running action", action

    -- print "Running action", action, @order\elapse!
    -- @order_list\recalc!

  on_key: (key) =>
    if key == "b"
      DISPATCH\pop!
      return true

    super key

  update: (dt) =>
    super dt

    for f in *@frames
      f\update dt

  draw: =>
    g.setFont fonts.thick_font
    @viewport\apply!
    @map\draw!

    super @viewport

    for f in *@frames
      f\draw!

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
