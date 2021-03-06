
import insert from table
{graphics: g} = love
{:min, :max} = math

local *

class BattleTransition extends Sequence
  time: 1.0

  new: (@before, @after) =>
    @p = 0
    @fade_out = false
    super ->
      tween @, @time, p: 1.0
      @fade_out = true
      tween @, @time/4, p: 0

  update: (dt) =>
    @after\update dt if @fade_out
    super dt

  draw: =>
    if @fade_out
      @after\draw!
      COLOR\pusha @p * 255
      g.rectangle "fill", 0,0, g.getWidth!, g.getHeight!
      COLOR\pop!
      return

    mid_x = g.getWidth!/2
    mid_y = g.getHeight!/2
    p2 = @p * @p

    if @canvas
      bm = g.getBlendMode!
      g.setBlendMode "multiplicative"

      g.setCanvas @canvas
      COLOR\push 20,20,20, 10
      g.draw @canvas, mid_x, mid_y, p2, 1 + @p, 1 + @p, mid_x, mid_y
      COLOR\pop!
      g.setCanvas!

      g.setBlendMode bm
    else
      @canvas = g.newCanvas g.getWidth!, g.getHeight!
      g.setCanvas @canvas
      @before\draw!
      g.setCanvas!


    g.draw @canvas, 0,0
    COLOR\pusha p2 * 255
    g.rectangle "fill", 0,0, g.getWidth!, g.getHeight!
    COLOR\pop!

{ :BattleTransition }
