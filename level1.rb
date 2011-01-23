class Level1 < GameState
  traits :viewport, :timer
  
  def setup
    load_game_objects
  
    self.input = { :escape => :exit }
    self.viewport.game_area = [0, 0, 4096, 768]
    self.viewport.lag = 2
    
    Backdrop.create :zorder => 0
    
    @player = Player.create :x => 256, :y => 256, :zorder => 1000
    
    @cursor = Cursor.create :x => 100, :y => 100, :zorder => 2000
  end
    
  def update
    super
    @cursor.x = $window.mouse_x
    @cursor.y = $window.mouse_y
    self.viewport.center_around @player
    @cursor.x += self.viewport.x
  end
  
end