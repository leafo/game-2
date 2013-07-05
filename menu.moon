
import insert from table
{graphics: g} = love
{:min, :max} = math

-- holds a list of things that can be scrolled through
class MenuGroup
  lazy icons: -> Spriter "img/icons.png", 8

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

class GreenBar
  lazy ui_sprite: -> Spriter "img/ui.png"

  ox: 0, oy: 17

  h: 7

  new: (@x, @y, @w, @p=0.5) =>
    {:ox, :oy, :h} = @

    @quad_left_full = "#{ox},#{oy},3,7"
    @quad_left_empty = "#{ox},#{oy + h},3,7"

    @quad_right_full = "#{ox + 6},#{oy},3,7"
    @quad_right_empty = "#{ox + 6},#{oy + h},3,7"

    @quad_full = "#{ox + 3},#{oy},1,7"
    @quad_empty = "#{ox + 3},#{oy + h},1,7 "

  draw: =>
    left = if @p == 0
      @quad_left_empty
    else
      @quad_left_full

    right = if @p == 1.0
      @quad_right_full
    else
      @quad_right_empty

    inner_width = @w - 6

    @ui_sprite\draw left, @x, @y

    fill_width = math.floor inner_width * @p

    -- filled
    if @p > 0
      @ui_sprite\draw @quad_full, @x + 3, @y, 0, fill_width, 1

    -- empty
    if @p < 1
      empty_width = inner_width - fill_width
      @ui_sprite\draw @quad_empty, @x + 3 + fill_width, @y, 0, empty_width, 1


    @ui_sprite\draw right, @x + @w - 3, @y

class RedBar extends GreenBar
  ox: 9, oy: 17

class BlueBar extends GreenBar
  ox: 18, oy: 17

class MainMenu extends MenuGroup
  lazy tile_bg: ->
    with imgfy "img/menu_tile.png"
      \set_wrap "repeat", "repeat"

  new: =>
    super!
    @viewport = Viewport scale: 2

    @health_bar = RedBar 5,5, 80, 0
    @mana_bar = BlueBar 5,15, 80, 0.5
    @exp_bar = GreenBar 5,25, 80, 1.0

    @add ItemList {
      { "Good Sword", "sword" }
      { "Death Bringer", "sword" }
      { "Wallshield", "shield" }
      { "Small Potion", "potion" }
      { "Charged Rod", "staff" }
      { "Sturdy Tarp", "helmet" }
      { "Battle Greaves", "boot" }
      { "Crimson Rock", "ring" }
      { "Thick Hands", "glove" }
    }, Box(180, 10, 120, 140)

    -- @add VerticalList {
    --   "Hello"
    --   "World"
    --   "Catnip"
    -- }, Box(180, 10, 120, 140)

  on_show: (dispatch) =>
    @game = dispatch\parent!

  on_key: (key, code) =>
    switch key
      when "x"
        DISPATCH\pop!
        return true

    super key, code

  draw_container: (x,y,w,h) =>
    -- back
    g.setColor 0,0,0, .09 * 255
    g.rectangle "fill", x,y,w,h

    -- top line
    g.setColor 0,0,0, .25 * 255
    g.rectangle "fill", x,y,w,1

    -- bottom line
    g.setColor 233,236,204, .25 * 255
    g.rectangle "fill", x,y + h - 1,w,1

    g.setColor 255,255,255

  draw_background: =>
    @_tile_quad or= g.newQuad 0, 0, @viewport.w, @viewport.h, @tile_bg\width!, @tile_bg\height!
    @tile_bg\drawq @_tile_quad, 0, 0

  draw: =>
    @viewport\apply!
    @draw_background!
    @draw_container 10,10, 100, 100
    g.push!
    g.translate 10,10

    @health_bar\draw!
    @mana_bar\draw!
    @exp_bar\draw!

    g.pop!

    super @viewport

    @viewport\pop!

  update: (dt) =>
    -- for bar in *{@health_bar, @mana_bar, @exp_bar}
    --   bar.p += dt*2
    --   bar.p = 0 if bar.p > 1

    super dt

{ :MainMenu }

