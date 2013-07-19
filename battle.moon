
import insert from table
{graphics: g} = love
{:min, :max} = math

import
  Frame, RedBar, BlueBar, VerticalList, MenuStack, BaseList
  from require "dialog"

import NumberParticle from require "particles"

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

  -- lets us pass in either a BattleEntity or a Entity
  speed_for_entity: (e) =>
    e.thing and e\thing!.speed or e.speed

  elapse: =>
    -- find out how much time to elapse
    local to_elapse
    for {:entity, :progress} in *@queue
      t = (@capacity - progress) / @speed_for_entity(entity)
      if to_elapse == nil or t < to_elapse
        to_elapse = t

    -- increment all the progress, find the greatest one
    -- doesn't just check for capacity to make sure we find something
    local max_tuple
    for tuple in *@queue
      tuple.progress += @speed_for_entity(tuple.entity) * to_elapse

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
    hp = @health_bars[i]
    mp = @mana_bars[i]

    g.push!
    g.translate 4 + (i - 1) * @char_width, 4

    p char.name, 0, 0
    hp\draw!
    mp\draw!

    COLOR\pusha 240
    g.printf tostring(_floor char.display_hp), hp.x, hp.y, hp.w - 4, "right"
    g.printf tostring(_floor char.display_hp), mp.x, mp.y, mp.w - 4, "right"
    COLOR\pop!

    g.pop!

  draw: =>
    super!
    g.push!
    g.translate @x, @y

    for i, char in ipairs @chars
      @draw_char_row i, char

    g.pop!

  update: (dt) =>
    for i, hp_bar in ipairs @health_bars
      char = @chars[i]
      hp_bar.p = char.display_hp / char.max_hp


class ActionsMenu extends VerticalList
  mixin Sequenced

  padding_top: Frame.padding
  padding_bottom: Frame.padding
  padding_left: Frame.padding

  row_spacing: 2

  alpha: 255
  fade_time: 0.2

  x: 5
  y: 140
  w: 87
  h: 35

  new: (@parent) =>
    @frame = Frame 0,0, @w, @h
    super {
      "Attack"
      "Defend"
      "Item"
      "Magic"
    }

    @max_height = @h
    @hide true

  draw_frame: =>
    @frame\draw!

  on_select: (item) => error "override me"

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

  on_active: (pushed) => @show! if pushed
  on_inactive: => @hide!

  update: (dt) =>
    super dt
    @frame.h = @h

  draw: (...) =>
    return if @hidden
    COLOR\pusha @alpha
    super ...
    COLOR\pop!


class BattleEnemy extends Box
  w: 10
  h: 20

  -- put x, y at feet
  new: (@enemy, x, y) =>
    @name = @enemy.name
    @x = x - @w / 2
    @y = y - @h

  draw: =>
    @outline COLOR.red

  thing: => @enemy

  take_hit: (actor, damage) =>

  update: (dt) =>

class BattleCharacter extends Box
  w: 10
  h: 20

  new: (@char, x, y) =>
    @name = @char.name

    @hp = @char.hp
    @display_hp = @hp
    @max_hp = @char.max_hp

    @x = x - @w / 2
    @y = y - @h

  take_hit: (actor, damage) =>
    @hp -= damage

  draw: =>
    @outline COLOR.green

  update: (dt) =>
    @display_hp = approach @display_hp, @hp, dt * 10 * math.abs @display_hp - @hp

  thing: => @char

-- a group of things on the field, like the group of players or the group of
-- enemies
class EntityGroup extends BaseList
  flip_x: false

  new: (...) =>
    super ...
    @items = {} -- overwritten
    @mapping = {}

  draw: (v, state) =>
    for e in *@items
      e\draw!

    @draw_cursor state

  update: (dt) =>
    for e in *@items
      e\update dt

  cell_offset: (i) =>
    item = @items[i]
    item.x - 10, item.y

  add: (items) =>
    cls = @etype
    pos = @distribute #items, @

    @mapping = {}
    @items = for item in *items
      obj = cls item, pos!
      @mapping[item] = obj
      obj

  find_item: (item) => @mapping[item]

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
  mixin Sequenced
  mixin HasParticles

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

    enemy_party = {
      { name: "Bad Dude", speed: 2 }
      { name: "Fart Slayer", speed: 1 }
    }

    @enemy_group\add enemy_party
    @char_group\add @game.party.characters

    @order = BattleOrder [ e for e in all_values @char_group.items, @enemy_group.items ]
    @char_frame = CharacterFrame @, @char_group.items

    @add "actions", ActionsMenu @
    @add "characters", @char_group
    @add "enemies", @enemy_group

    @order_list = OrderList @

    @frames = {
      @char_frame
      @order_list
    }

    @add_seq ->
      wait 0.2
      while true
        actor, action, target = await @\choose_action

        ox, oy = actor.x, actor.y

        tx, ty = if actor\left_of target
          target.x - actor.w - 5, target.y
        else
          target.x + target.w + 5, target.y

        tween actor, 0.5, x: tx, y: ty
        wait 0.1

        damage = math.random 8,14
        @particles\add NumberParticle target.x, target.y, damage
        target\take_hit actor, damage, @
        tween actor, 0.5, x: ox, y: oy

  choose_action: (callback) =>
    actor = @order\elapse!

    if actor.enemy
      target = pick_one unpack @char_group.items
      callback actor, false, target
      @order_list\recalc!
      return

    if actor.char
      actions = @push "actions"
      actions.on_select = (item) ->
        menu = @push "enemies"
        menu.on_select = (_, enemy) ->
          @pop 2
          @order_list\recalc!
          callback actor, item, enemy
      return

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

    @draw_inner!

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
