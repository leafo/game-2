
require "lovekit.all"
export reloader = require "lovekit.reloader"

import insert from table
{graphics: g} = love
{:min, :max} = math

enum = (tbl) ->
  for k,v in pairs tbl
    tbl[v] = k
  tbl



class Player extends Entity
  lazy_value @, "sprite", -> Spriter "img/scratch.png"

  w: 10
  h: 10

  speed: 80

  new: (x=10, y=10)=>
    @box = Box x,y, @w, @h

    with @sprite
      @anim = StateAnim "walk_up", {
        stand_left: \seq { "256,64,16,32" }
        stand_right: \seq { "256,64,16,32" }, 0, true

        stand_up: \seq { "240,64,16,32" }
        stand_down: \seq { "256,64,16,32" }

        walk_left: \seq {
          "272,64,16,32"
          "256,64,16,32"

          "288,64,16,32"
          "256,64,16,32"
        }, 0.2

        walk_right: \seq {
          "272,64,16,32"
          "256,64,16,32"

          "288,64,16,32"
          "256,64,16,32"
        }, 0.2, true


        walk_down: \seq {
          "256,32,16,32"
          "256,64,16,32"

          "256,0,16,32"
          "256,64,16,32"
        }, 0.2

        walk_up: \seq {
          "240,32,16,32"
          "240,64,16,32"

          "240,0,16,32"
          "240,64,16,32"
        }, 0.2

      }

  draw: =>
    @anim\draw @box.x, @box.y

  update: (dt) =>
    @velocity = movement_vector @speed * dt
    @anim\set_state @direction_name!

    @box\move unpack @velocity

    @anim\update dt


class TestPlayer extends Player
  lazy_value @, "sprite", -> Spriter "img/ffiv.png"

  new: (@x=10, @y=10)=>
    with @sprite
      @anim = StateAnim "walk_left", {
        walk_left: \seq {
          "74,37,18,26"
          "74,70,18,26"

          "74,37,18,26"
          "74,103,18,26"

          -- "74,136,18,26"
        }, 0.2
      }

  draw: =>
    @anim\draw @x, @y

  update: (dt) =>
    @anim\update dt

-- holds a list of things that can be scrolled through
class MenuGroup
  lazy_value @, "icons", ->
    Spriter "img/icons.png", 8

  new: =>
    @menus = {}

  add: (menu) =>
    insert @menus, menu
    @current_menu = 1 unless @current_menu

  update: (...)=>
    m\update ... for m in *@menus

  draw: (...) =>
    m\draw ... for m in *@menus

  on_key: (key) =>
    return unless @current_menu
    menu = @menus[@current_menu]

    switch key
      when "up"
        menu\go_prev!
      when "down"
        menu\go_next!
      when "return"
        sfx\play "select2"

class VerticalList
  row_height: 8
  row_spacing: 4
  scrollbar_width: 4
  cursor_offset: 10

  new: (@items, @box) =>
    @update_dimension!
    @offset_x = 0
    @selected_item = 1

  update_dimension: =>
    @inner_height = (@row_height + @row_spacing) * #@items
    @offset_x = 0

  update: (dt) =>

  move: (dp) =>
    old_pos = @selected_item
    @selected_item = max 1, min @selected_item + dp, #@items

    if old_pos == @selected_item
      sfx\play "blip2"
      false
    else
      sfx\play "blip1"
      true

  go_next: => @move 1
  go_prev: => @move -1

  row_offset: (i) =>
    (i - 1) * (@row_height + @row_spacing)

  draw_scrollbar: (w, h) =>
    return if @inner_height <= h

  draw_row: (i, item) =>
    y = @row_offset i
    g.print tostring(item)\lower!, 0, y

  draw: (v) =>
    x,y,w,h = @box\unpack!

    g.setColor 255,255,255,20
    g.push!
    g.translate x,y
    g.rectangle "fill", 0,0,w,h
    g.setColor 255,255,255

    vx, vy = v\project x,y
    vw, vh = v\project w,h

    g.setScissor vx,vy,vw,vh

    -- draw items
    g.push!
    g.translate 10, 0
    for i, item in ipairs @items
      @draw_row i, item
    g.pop!

    -- draw cursor
    MenuGroup.icons\draw 0, 0, (@selected_item - 1) * (@row_height + @row_spacing) - 1

    @draw_scrollbar w, h

    g.pop!
    g.setScissor!


-- item: {name, type}
class ItemList extends VerticalList
  icon_padding: 10

  item_types: enum {
    "sword", "staff", "potion", "shield", "armor", "boot", "helmet", "ring",
    "glove"
  }

  draw_row: (i, item) =>
    {name, item_type} = item

    y = (i - 1) * (@row_height + @row_spacing)

    -- g.setColor 255,0,0,64
    -- g.rectangle "fill", 0, y, 100, @row_height
    -- g.setColor 255,255,255,255

    MenuGroup.icons\draw @item_types[item_type], 0, y
    g.print name\lower!, @icon_padding, y + 1

class Game
  new: =>
    @viewport = Viewport scale: 2

    @menus = MenuGroup!

    @menus\add ItemList {
      { "Good Sword", "sword" }
      { "Death Bringer", "sword" }
      { "Wallshield", "shield" }
      { "Small Potion", "potion" }
      { "Charged Rod", "staff" }
      { "Sturdy Tarp", "helmet" }
      { "Battle Greaves", "boot" }
      { "Crimson Rock", "ring" }
      { "Thick Hands", "glove" }
    }, Box(40, 10, 120, 140)


    @menus\add VerticalList {
      "Hello"
      "World"
      "Catnip"
    }, Box(180, 10, 120, 140)

    @player = Player!
    @test = TestPlayer 10, 100

  on_key: (...) =>
    @menus\on_key ...

  update: (dt) =>
    reloader\update! if reloader

    @menus\update dt
    @player\update dt
    @test\update dt

  draw: =>
    @viewport\apply!
    -- g.print "how is it going!?", 10, 10
    @menus\draw @viewport

    @player\draw!
    @test\draw!

    @viewport\pop!

load_font = (img, chars)->
  font_image = imgfy img
  g.newImageFont font_image.tex, chars

love.load = ->
  g.setBackgroundColor 30,30,30

  main_font = load_font "img/font.png",
    [[ abcdefghijklmnopqrstuvwxyz-1234567890!.,:;'"?$&]]

  g.setFont main_font

  export sfx = lovekit.audio.Audio "sound"
  sfx\preload {
    "blip1"
    "blip2"
    "select"
    "select2"
  }

  dispatch = Dispatcher Game!
  dispatch\bind love

