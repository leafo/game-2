
require "lovekit.all"

{graphics: g} = love

{:min, :max} = math

enum = (tbl) ->
  for k,v in pairs tbl
    tbl[v] = k
  tbl

-- item: {name, type}
class ItemList
  lazy_value @, "icons", ->
    Spriter "img/icons.png", 8

  item_types: enum {
    "sword", "staff", "potion", "shield", "armor", "boot", "helmet", "ring",
    "glove"
  }

  row_height: 8
  row_spacing: 4
  icon_padding: 10
  scrollbar_width: 4

  new: (@items) =>
    @update_dimension!
    @offset_x = 0
    @selected_item = 1

  update_dimension: =>
    @inner_height = (@row_height + @row_spacing) * #@items
    @offset_x = 0

  update: (dt) =>

  on_key: (key) =>
    switch key
      when "up"
        @selected_item = max @selected_item - 1, 1
      when "down"
        @selected_item = min @selected_item + 1, #@items

  draw_row: (i, item) =>
    {name, item_type} = item

    y = (i - 1) * (@row_height + @row_spacing)

    -- g.setColor 255,0,0,64
    -- g.rectangle "fill", 0, y, 100, @row_height
    -- g.setColor 255,255,255,255

    @icons\draw @item_types[item_type], 0, y
    g.print name\lower!, @icon_padding, y + 1

  draw_scrollbar: (w, h) =>
    return if @inner_height <= h

  draw: (v, x,y, w, h) =>
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
    @icons\draw 0, 0, (@selected_item - 1) * (@row_height + @row_spacing)

    @draw_scrollbar w, h

    g.pop!
    g.setScissor!

class Game
  new: =>
    @viewport = Viewport scale: 2

    @items = ItemList {
      { "Good Sword", "sword" }
      { "Death Bringer", "sword" }
      { "Wallshield", "shield" }
      { "Small Potion", "potion" }
      { "Charged Rod", "staff" }
      { "Sturdy Tarp", "helmet" }
      { "Battle Greaves", "boot" }
      { "Crimson Rock", "ring" }
      { "Thick Hands", "glove" }
    }

  on_key: (...) =>
    @items\on_key ...

  draw: =>
    @viewport\apply!
    -- g.print "how is it going!?", 10, 10
    @items\draw @viewport, 10, 10, 120, 140
    @viewport\pop!

load_font = (img, chars)->
  font_image = imgfy img
  g.newImageFont font_image.tex, chars

love.load = ->
  g.setBackgroundColor 30,30,30

  main_font = load_font "img/font.png",
    [[ abcdefghijklmnopqrstuvwxyz-1234567890!.,:;'"?$&]]

  g.setFont main_font

  dispatch = Dispatcher Game!
  dispatch\bind love

