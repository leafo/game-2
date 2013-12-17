
require "lovekit.all"
require "lovekit.screen_snap"
require "lovekit.reloader"

export moon = require "moon"

export fonts = {}
export DISPATCH
export enum = (tbl) ->
  for k,v in pairs tbl
    tbl[v] = k
  tbl

import insert from table
{graphics: g, :timer} = love
{:min, :max} = math

import MainMenu from require "menu"
import Party from require "party"
import BattleTransition from require "transitions"
import Battle from require "battle"

export p = (str, ...) -> g.print str\lower!, ...

local snapper

class Player extends Entity
  lazy sprite: -> Spriter "img/characters.png", 16, 32

  w: 12
  h: 6

  ox: 2, oy: 25

  speed: 80

  new: (x=10, y=10)=>
    super x, y

    with @sprite
      @anim = StateAnim "stand_down", {
        stand_left: \seq { 17 }
        stand_right: \seq { 17 }, 0, true

        stand_up: \seq { 16 }
        stand_down: \seq { 17 }

        walk_left: \seq {
          18, 17, 19, 17
        }, 0.2

        walk_right: \seq {
          18, 17, 19, 17
        }, 0.2, true

        walk_down: \seq {
          9, 17, 1, 17
        }, 0.2

        walk_up: \seq {
          8, 16, 0, 16
        }, 0.2

      }

  draw: =>
    @sprite\draw 2, @x - @ox, @y - @oy -- shadow
    @anim\draw @x - @ox, @y - @oy

    -- Box.draw @, {255,128,128, 128}

  update: (dt, world) =>
    @velocity = movement_vector @speed * dt
    @anim\set_state @direction_name!

    {dx, dy} = @velocity

    @fit_move dx, dy, world
    @anim\update dt


class Game
  new: =>
    @viewport = Viewport scale: 2

    @party = Party!

    @menu = MainMenu @party

    @player = Player!
    @map = TileMap.from_tiled "maps.first", {
      object: (o) ->
        switch o.name
          when "spawn"
            @player.x = o.x
            @player.y = o.y
    }

  on_key: (key) =>
    switch key
      when "x"
        DISPATCH\push @menu
      when "b"
        DISPATCH\push Battle(@)-- , BattleTransition

  update: (dt) =>
    @player\update dt, @map

  draw: =>
    @viewport\center_on_pt @player.x, @player.y, @map\to_box!
    @viewport\apply!


    @map\draw @viewport
    @player\draw!

    @viewport\pop!

    p "FPS: #{timer.getFPS!}", 5, 5

load_font = (img, chars)->
  font_image = imgfy img
  g.newImageFont font_image.tex, chars

love.load = ->
  g.setBackgroundColor 30,30,30

  main_font = load_font "img/font.png",
    [[ abcdefghijklmnopqrstuvwxyz-1234567890!.,:;'"?$&/]]

  thick_font = load_font "img/font_thick.png",
    [[ abcdefghijklmnopqrstuvwxyz-1234567890!.,:;'"?$&/]]

  number_font = load_font "img/font_numbers.png", [[ 1234567890]]

  g.setFont main_font

  fonts = { :main_font, :thick_font, :number_font }

  export sfx = lovekit.audio.Audio "sound"

  sfx\preload {
    "blip1"
    "blip2"
    "select"
    "select2"
  }

  with DISPATCH = Dispatcher Game!
    .default_transition = FadeTransition
    -- .default_transition = BattleTransition

    .update = (dt) =>
      snapper\tick!  if snapper
      Dispatcher.update @, dt

    .keypressed = (key, code) =>
      if key == " "
        if snapper
          snapper\write!
          snapper = nil
        else
          snapper = ScreenSnap!

      Dispatcher.keypressed @, key, code

    \bind love



