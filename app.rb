require 'rubygems'
require 'chingu'

require 'player'
require 'play'
require 'tiles'
require 'crate'

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
    @music = Song["I_am_a_robot_I_save_cats.mp3"]
    @music.play true
    retrofy
    self.factor = 2
    push_game_state Play
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
  
  def set_image path
    @image = Image[path]
  end
end

Game.new.show