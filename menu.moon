
import insert from table
{graphics: g} = love
{:min, :max} = math

local *

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
    unless @current_menu
      switch key
        when "up", "down", "z", "return"
          sfx\play "blip2"
      return

    menu = @menus[@current_menu]

    switch key
      when "up"
        menu\go_prev!
      when "down"
        menu\go_next!
      when "z", "return"
        sfx\play "select2"
        menu\on_select!

class BaseList extends Box
  selected_item: 1

  draw_cell: (i, item) =>
    g.print tostring(item)\lower!, @cell_offset i

  draw_cursor: =>
    MenuGroup.icons\draw 0, @cell_offset @selected_item

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

  draw_frame: =>
    g.setColor 255,255,255,20
    g.rectangle "fill", 0,0, @w, @h
    g.setColor 255,255,255

class VerticalList extends BaseList
  row_height: 8
  row_spacing: 4
  scrollbar_width: 4
  cursor_offset: 10

  padding_left: 0
  padding_top: 0

  new: (@items, ...) =>
    super ...
    @update_dimension!

  update_dimension: =>
    @inner_height = (@row_height + @row_spacing) * #@items

  update: (dt) =>

  cell_offset: (i) =>
    @padding_left, (i - 1) * (@row_height + @row_spacing) + @padding_top

  draw_scrollbar: (w, h) =>
    return if @inner_height <= h

  draw: (v) =>
    x,y,w,h = @unpack!

    g.push!
    g.translate x,y

    @draw_frame!

    vx, vy = v\project x,y
    vw, vh = v\project w,h

    g.setScissor vx,vy,vw,vh

    -- draw items
    g.push!
    g.translate @cursor_offset, 0
    for i, item in ipairs @items
      @draw_cell i, item
    g.pop!

    @draw_cursor!
    @draw_scrollbar w, h

    g.pop!
    g.setScissor!


class HorizontalList extends BaseList
  column_width: 60
  cursor_offset: 10

  padding_left: 0
  padding_top: 0

  new: (@items, ...) =>
    super ...

  update: (dt) =>

  cell_offset: (i) =>
    (i - 1) * @column_width + @padding_left, @padding_top

  draw: =>
    {:x,:y,:w, :h} = @
    g.push!
    g.translate x,y

    @draw_frame!

    -- items
    g.push!
    g.translate @cursor_offset, 0
    for i, item in ipairs @items
      @draw_cell i, item
    g.pop!

    @draw_cursor!

    g.pop!


class ColumnList extends VerticalList
  num_columns: 2

  update_dimension: =>
    max_column = math.ceil #@items / @num_columns
    @inner_height = max_column * (@row_height + @row_spacing)
    @column_width = math.floor @w / @num_columns

  cell_offset: (i) =>
    column = (i - 1) % @num_columns -- 0 indexed
    row = math.floor (i - 1) / @num_columns

    x = column * @column_width
    y = row * (@row_height + @row_spacing)

    x + @padding_left, y + @padding_top


-- item: {name, type}
class ItemList extends VerticalList
  icon_padding: 10

  item_types: enum {
    "sword", "staff", "potion", "shield", "armor", "boot", "helmet", "ring",
    "glove"
  }

  draw_cell: (i, item) =>
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


class MainMenuActions extends VerticalList
  lazy ui_sprite: -> Spriter "img/ui.png"

  items: {
    { "Items", "items" }
    { "Equip", "equip" }
    { "Status", "status" }
    { "Abilities", "abilities" }
    { "Save", "save" }
  }

  row_height: 17
  row_spacing: 4

  padding_top: 8
  padding_left: 4

  on_select: =>
    item = @items[@selected_item][2]

    menu = switch item
      when "items"
        @menus[item] or= ItemsMenu @

    DISPATCH\push @menus[item]

  draw_cell: (i, row) =>
    x,y = @cell_offset i

    @ui_sprite\draw "0,0,63,17", x, y
    p row[1], x + 9, y + 5

  draw_frame: =>
    @parent\draw_container 0,0, @w, @h

  new: (@parent, ...) =>
    super nil, ...
    @menus = {}


class BaseMenu extends MenuGroup
  lazy {
    ui_sprite: -> Spriter "img/ui.png"
    tile_bg: ->
      with imgfy "img/menu_tile.png"
        \set_wrap "repeat", "repeat"
  }

  new: =>
    @viewport = Viewport scale: 2
    super!

  draw: =>
    @viewport\apply!
    @draw_background!

    @draw_inside!

    super @viewport

    @ui_sprite\draw "63,0,37,11", 0,0
    p "help", 5,1
    p "use or trash items", 40, 2

    @viewport\pop!

  on_key: (key, code) =>
    switch key
      when "x"
        DISPATCH\pop!
        return true

    super key, code

  draw_inside: => -- override me

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


class ItemsMenuTabs extends HorizontalList
  padding_left: 10
  padding_top: 5

  new: (@parent, ...) =>
    super {
      "Use"
      "Sort"
      "Rare"
    }, ...

  draw_frame: =>
    @parent\draw_container 0,0, @w, @h

  on_select: (item) =>


class ItemsMenu extends BaseMenu
  new: (@parent) =>
    super!
    @add ColumnList {
      "Anus"
      "Anus"
      "Anus"
      "Anus"
      "Anus"
      "Anus"
      "Anus"
      "Anus"
      "Anus"
      "Anus"
      "Anus"
      "Anus"
      "Anus"
      "Anus"
    }, 10, 45, 300, 127

    -- @add ItemsMenuTabs @, 10, 18, 300, 20

  draw_inside: =>
    -- @draw_container 10, 45, 300, 127

class MainMenu extends BaseMenu
  summary_x: 18, summary_y: 25
  summary_margin: 6

  new: (@party) =>
    super!
    @add MainMenuActions @, 219, 10, 91, 119

    -- @add VerticalList {
    --   "Hello"
    --   "World"
    --   "Catnip"
    -- }, 180, 10, 120, 140

  on_show: (dispatch) =>
    @game = dispatch\parent!

    x,y = @summary_x, @summary_y
    @summaries = for char in *@party.characters
      with CharacterSummary char, @
        .x = x
        .y = y
        y += CharacterSummary.h + @summary_margin


  draw_inside: =>
    for s in *@summaries
      s\draw!

  update: (dt) =>
    for s in *@summaries
      s\update dt

class CharacterSummary extends Box
  w: 193
  h: 44
  x: 0
  y: 0

  label_color: {197, 189, 128}

  name_pos: {27, 5}
  lv_pos: {27, 14}
  lv_val_pos: {47, 14}

  exp_pos: {27, 23}
  exp_val_pos: {51,23}

  hp_pos: {129, 5}
  hp_val_pos: {148, 5}
  mp_pos: {129, 23}
  mp_val_pos: {149, 23}

  hp_bar_pos: {126, 13, 59}
  mp_bar_pos: {126, 31, 59}
  exp_bar_pos: {24, 31, 83}

  image_pos: {6,1}

  new: (@char, @parent) =>
    @health_bar = RedBar unpack @hp_bar_pos
    @mana_bar = BlueBar unpack @mp_bar_pos
    @exp_bar = GreenBar unpack @exp_bar_pos

  update: (dt) =>

  draw: =>
    g.push!
    g.translate @x, @y
    @parent\draw_container 0,0, @w, @h

    p @char.name, unpack @name_pos
    @char.sprite\draw @char.image, unpack @image_pos

    g.setColor unpack @label_color
    p "Lv:", unpack @lv_pos
    p "Exp:", unpack @exp_pos

    p "HP:", unpack @hp_pos
    p "MP:", unpack @mp_pos

    g.setColor 255, 255, 255

    p tostring(@char.level), unpack @lv_val_pos
    p "#{@char.exp}/#{@char.exp_next}", unpack @exp_val_pos
    p "#{@char.hp}/#{@char.max_hp}", unpack @hp_val_pos
    p "#{@char.mp}/#{@char.max_mp}", unpack @mp_val_pos

    for bar in *{@health_bar, @mana_bar, @exp_bar}
      bar\draw!

    g.pop!

  update: (dt) =>

{ :MainMenu }

