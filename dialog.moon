
import insert from table
{graphics: g} = love
{:min, :max} = math

ui = require "lovekit.ui"

local *

class Frame extends ui.Frame
  lazy sprite: =>
    with Spriter "img/ui.png", 4, 4, 4
      .ox = 63
      .oy = 11

  new: (...) =>
    super nil, ...

{ :Frame }
