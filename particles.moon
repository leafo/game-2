
import insert from table
{graphics: g} = love
{:min, :max} = math

local *

class NumberParticle extends Particle
  life: 0.8
  spread: 20
  dir: Vec2d(2, -1)\normalized!

  new: (x, y, number) =>
    super x, y
    @number = tostring number

    @y -= 10
    @number = tostring number
    @vel = @dir\random_heading(@spread) * 60
    @accel = Vec2d 0, 100

    @s = 0.5
    @drot = (random_normal! - 0.5) * 5
    @rot = 0
    @a = 1

  update: (dt) =>
    t = 1 - @life / @@life
    @rot += dt * @drot

    if t < 0.2
      @s += dt * 5
    elseif t > 0.8
      @s -= dt

    if t > 0.5
      @a = 1 - (t - 0.5) / 0.5

    super dt

  draw: =>
    g.setFont fonts.number_font

    COLOR\pusha @a * 255

    g.push!
    g.translate @x, @y
    g.print @number, 0,0, @rot, @s, @s, 4, 4
    g.pop!

    COLOR\pop!

    g.setFont fonts.main_font

{ :NumberParticle }
