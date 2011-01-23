
require 'rubygems'
require 'chingu'

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
    switch_game_state(StartGame.new)
  end
end

class StartGame < GameState
  traits :viewport, :timer
  
  # :file => "level.yml"
  
  def setup
    load_game_objects
  
    self.input = { :escape => :exit, :e => :edit }
    self.viewport.game_area = [0, 0, 4096, 768]
    self.viewport.lag = 2
    
    #32.times do |x|
    #  24.times do |y|
    #    Dirt.create( :x => x * 32, :y => y * 32 )
    #  end
    #end
    #12.times do |i|
    #  Stone.create(:x => 128 + (i*32), :y => 512)
    #end
    #32.times do |i|
    #  Stone.create(:x => 256 + (i*32), :y => 256)
    #end
    #2.times do |x|
    #  Stone.create(:x => x * 32, :y => 512)
    #end
    #
    #32.times do |x|
    #  Fire.create(:x => x * 32, :y => 768 - 32 )
    #end
    
    Backdrop.create :zorder => 0
    
    @player = Player.create :x => 256, :y => 256, :zorder => 1000
    
    @cursor = Cursor.create :x => 100, :y => 100, :zorder => 2000
  end
  
  def edit
    
    push_game_state( GameStates::Edit )
  end
  
  def update
    super
    @cursor.x = $window.mouse_x
    @cursor.y = $window.mouse_y
    self.viewport.center_around @player
    @cursor.x += self.viewport.x
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

class Grabber < GameObject
  traits :collision_detection, :bounding_box
  
  def setup
    @image = Image["claw.png"]
    self.scale = 2
  end
end

class PlayerSpring < GameObject
  traits :effect, :timer, :bounding_box
  
  def setup
    @image = Image["spring.png"]
    self.scale = 2
    self.factor_x = 2 
    self.rotation_center = :middle_left
    @target = [0,0]
    @target_factor = 2
    @tween_length = 3.0
    @ready = true
    
    @desired_factor = 2
    
    @claw = Grabber.create
    @clamped = false
  end
  
  def player_is player
    @player = player
  end
  
  def update
    if self.visible
      

      unless @clamped
        @claw.each_bounding_box_collision(Stone) do |claw, stone|
          puts "#{stone.class}: #{stone.x}, #{stone.y}"
          @clamped = true
        end
      end
      
      if @clamped
        self.factor_x = dist(@claw.x,@claw.y,self.x,self.y) / 16.0
        self.angle = Math.atan2( @claw.y - self.y, @claw.x - self.x) * ( 180.0 / 3.14159 )
        
        s = (self.factor_x*self.factor_x) * 0.03
        s = 1.2 if s > 1.2
        @player.acceleration_x += s * Math.cos(self.angle * (3.14159 / 180.0 ))
        @player.velocity_y += s * Math.sin(self.angle * (3.14159 / 180.0 ))
        
      else
        self.factor_x = ( (self.factor_x * @tween_length) + @target_factor ) / (@tween_length + 1)
        @claw.x = ( ( @claw.x * @tween_length ) + @target[0] ) / (@tween_length + 1)
        @claw.y = ( ( @claw.y * @tween_length ) + @target[1] ) / (@tween_length + 1)
      end
    end
  end
  
  
  def fire_at x, y
    if @ready
      @target = [x,y]
      @target_factor = dist(x,y,self.x,self.y) / 16.0
      self.angle = Math.atan2( y - self.y, x - self.x) * ( 180.0 / 3.14159 )
      self.show!
      @claw.show!
      @claw.x = self.x
      @claw.y = self.y-32
      @claw.angle = self.angle
      after(250)  { retract unless @clamped }
    end
  end
  
  def retract
    if @clamped
      @clamped = false
      retract
    else
      @target = [self.x, self.y]
      @target_factor = 0
      @ready = true 
      self.hide!
      @claw.hide!
    end
  end
end

class Player < GameObject
  traits :bounding_box, :collision_detection, :velocity, :effect, :timer
  
  
  def setup
    
    self.input = { 
      [:holding_left, :holding_a] => :go_left, 
      [:holding_right, :holding_d] => :go_right, 
      [:space, :w, :up] => :jump,
      [:mouse_left] => :fire,
      [:released_mouse_left] => :retract
    }
    
    @speed = 1
    @jumping = false
    @alive = true
    @using_spring = false
    
    @spring = PlayerSpring.create
    @spring.player_is self
    @spring.hide!
    
    self.scale = 2
    self.max_velocity = 10
    self.rotation_center = :bottom_center
    
    @image = Image["hero.png"]
    
    update
  end
  
  def update
    self.acceleration_y = 0.5
    self.acceleration_x = 0
    
    if @jumping and @against_wall == :none
      self.acceleration_x += self.velocity_x * 0.02
      self.acceleration_y += self.velocity_y * 0.02
    end
    
    if @against_wall == :none
      self.velocity_x *= @jumping ? 0.95 : 0.6
      self.velocity_y *= 0.95
    end
    
    @spring.x = self.x
    @spring.y = self.y - 16
    
    @speed = @jumping ? 0.5 : 1.0
    
    @jumping = true
    @against_wall = :none
    self.each_collision(Stone) do |me, stone|
      #if self.previous_y > stone.y + 32 and self.previous_x < stone.x - 16 and self.previous_x > stone.x + 48
      #  me.y = stone.y + 70
      #  self.velocity_y *= -0.5
      #elsif self.previous_y <= stone.y and self.previous_x < stone.x - 16 and self.previous_x > stone.x + 48
      #  @jumping = false
      #  me.y = stone.y
      #elsif me.previous_x > stone.x and self.previous_y 
      #  me.x = stone.x + 54        
      #else
      #  me.x = stone.x - 16
      #end
      
      if self.previous_y >= stone.y + 46
        vertical = :bottom
      elsif self.previous_y <= stone.y
        vertical = :top
      else
        vertical = :middle
      end
      
      if self.previous_x >= stone.x + 46
        horizontal = :right
        #stone.color = Color::RED
      elsif self.previous_x <= stone.x - 14
        horizontal = :left
        #stone.color = Color::GREEN
      else
        horizontal = :center
        #stone.color = Color::BLUE
      end
      
      if self.velocity_y.abs > self.velocity_x.abs
        direction = :vertical
      else
        direction = :horizontal
      end
      
      if vertical == :top
        if horizontal == :center
          self.y = stone.y
          self.velocity_y = 0
          @jumping = false
        elsif horizontal == :left
          if direction == :horizontal
            self.y = stone.y
            self.velocity_y = 0
            @jumping = false
          else
            self.x = stone.x - 14
            self.velocity_x = 0
            self.acceleration_x = 0
            @against_wall = :left
          end
        elsif horizontal == :right
          if direction == :horizontal
            self.y = stone.y
            self.velocity_y = 0
            @jumping = false
          else
            self.x = stone.x + 46
            self.velocity_x = 0
            self.acceleration_x = 0
            @against_wall = :right
          end
        end
      elsif vertical == :bottom
        if horizontal == :center
          self.y = stone.y + 64
          self.velocity_y = 0
        elsif horizontal == :left
          if direction == :horizontal
            self.y = stone.y + 64
            self.velocity_y = 0
          else
            self.x = stone.x - 14
            self.velocity_x = 0
            self.acceleration_x = 0
            @against_wall = :left
          end
        elsif horizontal == :right
          if direction == :horizontal
            self.y = stone.y + 64
            self.velocity_y = 0
          else
            self.x = stone.x + 46
            self.velocity_x = 0
            self.acceleration_x = 0
            @against_wall = :right
          end
        end
      elsif vertical == :middle
        if horizontal == :center
          # there is no way this should happen.. but whatever
          if self.x > stone.x + 16 # right
            self.x = stone.x + 46
            self.velocity_x = 0
            self.acceleration_x = 0
            @against_wall = :right
          else
            self.x = stone.x - 14
            self.velocity_x = 0
            self.acceleration_x = 0
            @against_wall = :left
          end
        elsif horizontal == :left
          self.x = stone.x - 14
          self.velocity_x = 0
          self.acceleration_x = 0
          @against_wall = :left
        elsif horizontal == :right
          self.x = stone.x + 46
          self.velocity_x = 0
          self.acceleration_x = 0
          @against_wall = :right
        end
      end
    end
    
    self.each_collision(Fire) do |me, fire|
      if me.y > fire.y + 24
        me.die
      end
    end
    
    self.x = 16 if self.x < 16
    self.x = self.parent.viewport.game_area.width if self.x > self.parent.viewport.game_area.width
  end
  
  def go_left
    self.acceleration_x -= @speed unless @against_wall == :right
    self.factor_x = -2
  end
  
  def go_right
    self.acceleration_x += @speed unless @against_wall == :left
    self.factor_x = 2
  end
  
  def fire
    @spring.fire_at $window.mouse_x + self.parent.viewport.x, $window.mouse_y
  end
  
  def retract
    @spring.retract
  end
  
  def die
    if @alive
      self.velocity_y = -10
      self.rotation_rate = -4
      @alive = false
      after(1000) { self.spawn }
      during(1000){ self.color = Color::RED }
    end
  end
  
  def spawn
    @alive = true
    self.color = Color::WHITE
    self.velocity_y = 0
    self.velocity_x = 0
    self.acceleration_y = 0.65
    self.acceleration_x = 0
    self.angle = 0
    self.rotation_rate = 0
    self.x = 256
    self.y = 64
  end
  
  def jump
    unless @jumping
      @jumping = true
      self.velocity_y = -10
    end
  end
  
end

class Tile < GameObject
  trait :bounding_box
  trait :collision_detection
  
  def setup
    self.scale = 2
    self.rotation_center = :left_top
  end
end

class Fire < Tile
  def setup
    super
    @animations = Animation.new( :file => "fire_16x16.png" )
    @animations.frame_names = { :scroll => 0..3 }
    @animation = @animations[:scroll]
    update
  end
  def update
    @image = @animation.next
  end
end

class Dirt < Tile
  
  def setup
    super
    @image = Image["dirt.png"]
  end
end

class Stone < Tile
  
  def setup
    super
    @image = Image["stone.png"]
    update
  end
  
  def update
    super
    self.color = Color::WHITE
  end
end



Game.new.show