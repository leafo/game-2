
import insert from table
{graphics: g} = love
{:min, :max} = math

import ColumnList, MenuStack, MenuGroup, VerticalList, HorizontalList, RedBar,
  BlueBar, GreenBar from require "dialog"

ease_out = do
  import sqrt from math
  (a, b, t) -> sqrt a + (b - a) * t

local *

-- item: {name, type}
class ItemList extends ColumnList
  icon_padding: 10

  padding_left: 10
  padding_top: 5

  new: (@parent, items, ...) =>
    super items, ...

  draw_frame: =>
    @parent\draw_container 0,0, @w, @h

  -- item type name -> icon
  item_types: enum {
    "sword", "staff", "potion", "shield", "armor", "boot", "helmet", "ring",
    "glove"
  }

  on_select: =>
    sfx\play "blip2"

  draw_cell: (i, item) =>
    {name, item_type} = item
    x,y = @cell_offset i

    -- COLOR\push 255,0,0,64
    -- g.rectangle "fill", 0, y, 100, @row_height
    -- COLOR\pop!

    MenuGroup.icons\draw @item_types[item_type], x, y
    g.print name\lower!, x + @icon_padding, y + 1

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


class BaseMenu extends MenuStack
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

    super @viewport

    @ui_sprite\draw "63,0,37,11", 0,0
    p "help", 5,1
    p "use or trash items", 40, 2

    @draw_inside!

    @viewport\pop!

  on_key: (key, code) =>
    unless super key, code
      if key == "x"
        DISPATCH\pop!
        return true

  draw_inside: => -- override me

  draw_container: (x,y,w,h) =>
    -- back
    COLOR\push 0,0,0, .09 * 255
    g.rectangle "fill", x,y,w,h

    -- top line
    COLOR\set 0,0,0, .25 * 255
    g.rectangle "fill", x,y,w,1

    -- bottom line
    COLOR\set 233,236,204, .25 * 255
    g.rectangle "fill", x,y + h - 1,w,1

    COLOR\pop!

  draw_background: =>
    @_tile_quad or= g.newQuad 0, 0, @viewport.w, @viewport.h, @tile_bg\width!, @tile_bg\height!
    @tile_bg\draw @_tile_quad, 0, 0

class ItemsMenuTabs extends HorizontalList
  padding_left: 10
  padding_top: 5

  new: (@parent, ...) =>
    super {
      { "Use", "use" }
      { "Sort", "sort" }
      { "Rare", "rare" }
    }, ...

  draw_frame: =>
    @parent\draw_container 0,0, @w, @h

  draw_cell: (i, item) =>
    super i, item[1]

  on_select: =>
    name = @items[@selected_item][2]
    sfx\play "select2"
    @parent\push name

class ItemsMenu extends BaseMenu
  new: (@parent) =>
    super!

    @add "tabs", ItemsMenuTabs @, 10, 18, 300, 20

    @add "use", ItemList @, {
      { "Good Sword", "sword" }
      { "Death Bringer", "sword" }
      { "Wallshield", "shield" }
      { "Small Potion", "potion" }
      { "Charged Rod", "staff" }
      { "Sturdy Tarp", "helmet" }
      { "Battle Greaves", "boot" }
      { "Crimson Rock", "ring" }
      { "Thick Hands", "glove" }
    }, 10, 45, 300, 127

    @push "tabs"

  draw_inside: =>
    -- @draw_container 10, 45, 300, 127

class MainMenu extends BaseMenu
  summary_x: 18, summary_y: 25
  summary_margin: 6

  new: (@party) =>
    super!
    @add "main", MainMenuActions @, 219, 10, 91, 119
    @push "main"

  on_show: (dispatch) =>
    @game = dispatch\parent!

    x,y = @summary_x, @summary_y
    @summaries = for char in *@party.characters
      with CharacterSummary char, @
        .x = x
        .y = y
        y += CharacterSummary.h + @summary_margin

    @p = 0
    @effect = Sequence ->
      tween @, 0.2, { p: 1.0 }, ease_out
      @effect = nil

  draw_inside: =>
    for i, s in ipairs @summaries
      g.push!
      g.translate (1 - @p) * -(20 + i * 30) , 0
      s\draw!
      g.pop!

  update: (dt) =>
    @effect\update dt if @effect
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

    COLOR\push @label_color
    p "Lv:", unpack @lv_pos
    p "Exp:", unpack @exp_pos

    p "HP:", unpack @hp_pos
    p "MP:", unpack @mp_pos
    COLOR\pop!

    p tostring(@char.level), unpack @lv_val_pos
    p "#{@char.exp}/#{@char.exp_next}", unpack @exp_val_pos
    p "#{@char.hp}/#{@char.max_hp}", unpack @hp_val_pos
    p "#{@char.mp}/#{@char.max_mp}", unpack @mp_val_pos

    for bar in *{@health_bar, @mana_bar, @exp_bar}
      bar\draw!

    g.pop!

  update: (dt) =>

{ :MainMenu }

