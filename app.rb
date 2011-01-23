require 'rubygems'
require 'chingu'

require 'player'
require 'level1'
require 'tiles'

include Gosu
include Chingu

def dist x1, y1, x2, y2
  Math.sqrt( (( x2 - x1 ) * ( x2 - x1 )) + (( y2 - y1 ) * (y2 - y1 ) ) )
end

class Game < Chingu::Window
  def initialize
    super(1024,768,false)
  end
  
  def setup
    retrofy
    self.factor = 3
    switch_game_state(Level1.new)
  end
end

class Cursor < GameObject
  def setup
    self.scale = 2
    @image = Image["dot.png"]
    update
  end
end

class Backdrop < GameObject
  def setup
    @image = Image["bg.png"]
    self.rotation_center = :left_top
  end
end

Game.new.show