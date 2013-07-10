
import insert from table
{graphics: g} = love
{:min, :max} = math

ui = require "lovekit.ui"

local *

class Frame extends ui.Frame
  padding: 4

  lazy sprite: =>
    with Spriter "img/ui.png", 4, 4, 4
      .ox = 63
      .oy = 11

  new: (...) =>
    super nil, ...

-- like dispatch but for menus (or menu groups)
-- sends input to the menu on the top
-- draws all menus with states
class MenuStack
  new: =>
    @menus = {}
    @stack = {}

  add: (name, menu) =>
    @menus[name] = menu
    unless next @stack
      @push name

  push: (name) =>
    if top = @top!
      top[@] = "pushed"

    insert @stack, name
    menu = assert @menus[name], "failed to push menu named: #{name}"
    menu[@] = "active"

  pop: =>
    if top = @top!
      top[@] = nil

    with table.remove @stack
      @top![@] = "active"

  top: =>
    name = @stack[#@stack]
    return unless name
    @menus[name]

  on_key: (key) =>
    top = @top!

    if key == "x"
      if #@stack > 1
        @pop!
        return true

    if top = @top!
      top\on_key key

  draw: (v) =>
    for _, menu in pairs @menus
      menu\draw v, menu[@] or "inactive"

  update: (dt) =>
    for _, menu in pairs @menus
      menu\update dt

-- holds a list of menus that can be scrolled through
-- TODO: should be a psedu menu of multiple menus with some spatial organization
class MenuGroup
  lazy icons: -> Spriter "img/icons.png", 8

  new: =>
    @menus = {}

  add: (menu) =>
    insert @menus, menu
    @current_menu = 1 unless @current_menu

  update: (...) =>
    m\update ... for m in *@menus

  draw: (...) =>
    m\draw ... for m in *@menus

  on_key: (key) =>
    unless @current_menu
      switch key
        when "up", "down", "z", "return"
          sfx\play "blip2"
      return

    @menus[@current_menu]\on_key key

class BaseList extends Box
  selected_item: 1

  draw_cell: (i, item) =>
    g.print tostring(item)\lower!, @cell_offset i

  draw_cursor: (state="active") =>
    return if state == "inactive"
    g.setColor 255,255,255,128 if state == "pushed"
    MenuGroup.icons\draw 0, @cell_offset @selected_item
    g.setColor 255,255,255 if state == "pushed"

  move_updown: (dp) => @move dp
  move_leftright: (dp) => false

  on_key: (key) =>
    moved = switch key
      when "up"
        @move_updown -1
      when "down"
        @move_updown 1
      when "left"
        @move_leftright -1
      when "right"
        @move_leftright 1
      when "z", "return"
        if @on_select!
          sfx\play "select2"
        nil

    if moved != nil
      if moved
        sfx\play "blip1"
      else
        sfx\play "blip2"

    moved

  move: (dp) =>
    new_pos = @selected_item + dp
    if new_pos < 1 or new_pos > #@items
      return false

    @selected_item = new_pos
    true

  update: (dt) =>

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

  cell_offset: (i) =>
    @padding_left, (i - 1) * (@row_height + @row_spacing) + @padding_top

  draw_scrollbar: (w, h) =>
    return if @inner_height <= h

  draw: (v, state) =>
    x,y,w,h = @unpack!

    g.push!
    g.translate x,y

    @draw_frame!

    if v
      vx, vy = v\project x,y
      vw, vh = v\project w,h

      g.setScissor vx,vy,vw,vh

    -- draw items
    g.push!
    g.translate @cursor_offset, 0
    for i, item in ipairs @items
      @draw_cell i, item
    g.pop!

    @draw_cursor state
    @draw_scrollbar w, h

    g.pop!
    if v
      g.setScissor!


class HorizontalList extends BaseList
  column_width: 60
  cursor_offset: 10

  padding_left: 0
  padding_top: 0

  new: (@items, ...) =>
    super ...

  cell_offset: (i) =>
    (i - 1) * @column_width + @padding_left, @padding_top

  move_updown: (dp) => false
  move_leftright: (dp) => @move dp

  draw: (v, state) =>
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

    @draw_cursor state

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

  move_updown: (dp) => @move dp * @num_columns

  move_leftright: (dp) =>
    column = (@selected_item - 1) % @num_columns + 1

    if dp == -1 and column == 1
      return false

    if dp == 1 and column == @num_columns
      return false

    @move dp

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


{ :Frame, :MenuStack, :MenuGroup, :BaseList, :VerticalList, :HorizontalList,
  :ColumnList, :GreenBar, :RedBar, :BlueBar }


