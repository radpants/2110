class Play < GameState
  traits :viewport, :timer
  attr_reader :crates_to_win, :spawn_point
  
  def setup
    self.input = { :escape => :exit }
    self.viewport.game_area = [0, 0, 4096, 768]
    
    @levels = [:intro, :level1, :level2]
    @current_level_index = 0
    
    
    @player = Player.create :zorder => 1000
    load :intro
  end
  
  def next_level
    @current_level_index = ( @current_level_index + 1 ) % @levels.count
    load @levels[@current_level_index]
  end
  
  def load level
    
    game_objects.each do |object|
      unless object == @player or object.class == Grabber or object.class == PlayerSpring
        object.destroy
      end
    end
    
    
    @backdrop = Backdrop.create :zorder => 0
    
    if level == :intro
      @backdrop.image = Image["intro_bg.png"]
      @crates_to_win = 1
      load_game_objects :file => "intro.yml"
    elsif level == :level1
      @backdrop.image = Image["bg_blue.png"]
      @crates_to_win = 3
      load_game_objects :file => "level1.yml"
    else level == :level2
      @backdrop.image = Image["bg_red.png"]
      @crates_to_win = 5
      load_game_objects :file => "level2.yml"
    end
    
    @spawn_point = game_objects.of_class(SpawnPoint).first
    @player.x = spawn_point.x
    @player.y = spawn_point.y
    puts "moving player to (#{spawn_point.x},#{spawn_point.y})"
    
    @cursor = Cursor.create :x => 100, :y => 100, :zorder => 2000
  end
  
  def update
    super
    @cursor.x = $window.mouse_x
    @cursor.y = $window.mouse_y
    self.viewport.center_around @player unless @player.nil?
    @cursor.x += self.viewport.x
  end
  
end