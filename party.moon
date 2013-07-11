
import insert from table
{graphics: g} = love
{:min, :max} = math


class Character
  lazy sprite: -> Spriter "img/characters.png"

  name: "Unknown"

  level: 1
  hp: 0
  max_hp: 100

  mp: 0
  max_mp: 100

  exp: 0
  exp_next: 100

  image: "16,64,16,32"

  speed: 10

  new: =>
    @equip = {}
    @calc_stats!

  calc_stats: =>
    @mod_stats = setmetatable {}, __index: @

class Party
  new: =>
    @characters = {}
    @items = {}

    -- dummy party
    insert @characters, with Character!
      .name = "Arkeus"

    insert @characters, with Character!
      .name = "Leafo"

    insert @characters, with Character!
      .name = "Adam D."


{ :Party }
