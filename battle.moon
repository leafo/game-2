
import insert from table
{graphics: g} = love
{:min, :max} = math

local *

class BattleMenu

class Battle
  viewport: Viewport scale: 2

  new: (@game) =>
    @map = TileMap.from_tiled "maps.battle"

  on_key: (key) =>
    if key == "b"
      DISPATCH\pop!
      return true

  update: (dt) =>

  draw: =>
    @viewport\apply!
    @map\draw!

    p "This is a battle", 10, 10

    @viewport\pop!


{ :Battle }
