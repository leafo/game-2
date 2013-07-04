
require "lovekit.all"

{graphics: g} = love

class Game
  new: =>
    @viewport = Viewport scale: 2

  draw: =>
    @viewport\apply!
    g.print "how is it going!", 10, 10
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

