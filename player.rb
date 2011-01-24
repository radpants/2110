include Chingu

class Player < GameObject
  traits :bounding_box, :collision_detection, :velocity, :effect, :timer
  attr_accessor :held_crate
  
  def setup
    self.input = { 
      [:holding_left, :holding_a] => :go_left, 
      [:holding_right, :holding_d] => :go_right, 
      [:w, :up] => :jump,
      [:mouse_left] => :fire,
      [:released_mouse_left] => :retract,
      [:space, :mouse_right, :e] => :action
    }
    
    @speed = 1
    @jumping = false
    @alive = true
    @using_spring = false
    
    @jump_sound = Sound["jump.wav"]
    @shoot_hook_sound = Sound["shoot_hook.wav"]
    @pick_up_crate_sound = Sound["pick_up_crate.wav"]
    @die_sound = Sound["die.wav"]
    
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
    
    unless @held_crate.nil?
      @held_crate.x = self.x - 14
      @held_crate.y = self.y - 52
    end
    
    @spring.x = self.x
    @spring.y = self.y - 16
    
    if @held_crate and !@jumping
      @speed = @jumping ? 0.2 : 0.5
    else
      @speed = @jumping ? 0.5 : 1.0
    end
    
    
    @jumping = true
    @against_wall = :none
    @near_crate = nil
    self.each_collision(Stone, Crate) do |me, stone|
      
      unless stone == @held_crate or self.previous_y.nil? or self.previous_x.nil?
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
    end
    
    self.each_collision(Fire) do |me, fire|
      if me.y > fire.y + 24
        me.die
      end
    end
    
    self.each_collision(Crate) do |me, crate|
      @near_crate = crate
    end
    
    self.x = 16 if self.x < 16
    self.x = self.parent.viewport.game_area.width if self.x > self.parent.viewport.game_area.width
    die if self.y > 768
  end
  
  def go_left
    return unless @alive
    self.factor_x = -2
    self.acceleration_x -= @speed unless @against_wall == :right
  end
  
  def go_right
    return unless @alive
    self.factor_x = 2
    self.acceleration_x += @speed unless @against_wall == :left
  end
  
  def fire
    @shoot_hook_sound.play
    @spring.fire_at $window.mouse_x + self.parent.viewport.x, $window.mouse_y
  end
  
  def retract
    @spring.retract
  end
  
  def action
    unless @held_crate.nil?
      self.drop_crate
      return
    end
    unless @near_crate.nil?
      @pick_up_crate_sound.play
      @held_crate = @near_crate
      @held_crate.being_held = true
      @held_crate.zorder = 999
    end
  end
  
  def drop_crate
    return if @held_crate.nil?
    @held_crate.being_held = false
    @pick_up_crate_sound.play
    @held_crate.y = self.y - 32
    self.y = @held_crate.y
    @held_crate = nil
  end
  
  def destroy
    super
    @spring.destroy
  end
  
  def die
    if @alive
      @die_sound.play
      self.drop_crate      
      self.velocity_y = -10
      self.rotation_rate = -4
      @alive = false
      after(500) { self.spawn }
      during(500){ self.color = Color::RED }
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
    self.x = self.parent.spawn_point.x
    self.y = self.parent.spawn_point.y
  end
  
  def jump
    unless @jumping
      @jumping = true
      @jump_sound.play
      self.velocity_y = @held_crate ? -3 : -10
    end
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
    @clamp_sound = Sound["clamp.wav"]
    @desired_factor = 2
    
    @claw = Grabber.create
    @clamped = false
  end
  
  def destroy
    super
    @claw.destroy
  end
  
  def player_is player
    @player = player
  end
  
  def draw
    if true
      angle_to_player = Math.atan2( @claw.y - @player.y, @claw.x - @player.x )
      self.factor_x = dist(@claw.x,@claw.y,self.x,self.y) / 16.0
      self.angle = Math.atan2( @claw.y - self.y, @claw.x - self.x) * ( 180.0 / 3.14159 )
    end
    super
  end
  
  def update
    if self.visible
      
      angle_to_player = Math.atan2( @claw.y - @player.y, @claw.x - @player.x )
      #self.factor_x = dist(@claw.x,@claw.y,self.x,self.y) / 16.0
      #self.angle = Math.atan2( @claw.y - self.y, @claw.x - self.x) * ( 180.0 / 3.14159 )
      
      if @clamped
        s = (self.factor_x*self.factor_x) * 0.03
        s = 1.2 if s > 1.2
        @player.acceleration_x += s * Math.cos(self.angle * (3.14159 / 180.0 ))
        @player.velocity_y += s * Math.sin(self.angle * (3.14159 / 180.0 ))
      else
        @claw.acceleration_x = -4 * Math.cos(angle_to_player)
        @claw.acceleration_y = -4 * Math.sin(angle_to_player) 
        
        @claw.each_bounding_box_collision(Stone, Crate) do |claw, stone|
          unless stone == @player.held_crate
            @clamped = true
            @clamp_sound.play
            puts "CLAMPS!"
            @claw.acceleration_y = 0
            @claw.acceleration_x = 0
            @claw.velocity_y = 0
            @claw.velocity_x = 0
          end
        end       
      end
      
      #
      #
      #unless @clamped
      
      #end
      #
      #if @clamped
      #  self.factor_x = dist(@claw.x,@claw.y,self.x,self.y) / 16.0
      #  self.angle = Math.atan2( @claw.y - self.y, @claw.x - self.x) * ( 180.0 / 3.14159 )
      #  
      #  s = (self.factor_x*self.factor_x) * 0.03
      #  s = 1.2 if s > 1.2
      #  @player.acceleration_x += s * Math.cos(self.angle * (3.14159 / 180.0 ))
      #  @player.velocity_y += s * Math.sin(self.angle * (3.14159 / 180.0 ))
      #  
      #else
      #  self.factor_x = ( (self.factor_x * @tween_length) + @target_factor ) / (@tween_length + 1)
      #  @claw.x = ( ( @claw.x * @tween_length ) + @target[0] ) / (@tween_length + 1)
      #  @claw.y = ( ( @claw.y * @tween_length ) + @target[1] ) / (@tween_length + 1)
      #end
    end
  end
  
  
  def fire_at x, y
    #if @ready
    #  @target = [x,y]
    #  @target_factor = dist(x,y,self.x,self.y) / 16.0
    #  self.angle = Math.atan2( y - self.y, x - self.x) * ( 180.0 / 3.14159 )
    #  self.show!
    #  @claw.show!
    #  @claw.x = self.x
    #  @claw.y = self.y-32
    #  @claw.angle = self.angle
    #  after(250)  { retract unless @clamped }
    #end
    @claw.acceleration_x = 0
    @claw.acceleration_y = 0
    @claw.velocity_x = 0
    @claw.velocity_y = 0
    
    theta = Math.atan2( y - @player.y, x - @player.x)
    @claw.x = @player.x
    @claw.y = @player.y
    @claw.angle = theta * ( 180.0 / 3.14159 )
    @claw.show!
    self.show!
    @claw.velocity_x = 50 * Math.cos(theta)
    @claw.velocity_y = 50 * Math.sin(theta)
    
    
  end
  
  def retract
    #if @clamped
    #  @clamped = false
    #  retract
    #else
    #  @target = [self.x, self.y]
    #  @target_factor = 0
    #  @ready = true 
    #  self.hide!
    #  @claw.hide!
    #end
    @clamped = false
    @claw.x = @player.x
    @claw.y = @player.y
    @claw.acceleration_x = 0
    @claw.acceleration_y = 0
    @claw.velocity_x = 0
    @claw.velocity_y = 0
    self.hide!
    @claw.hide!
    self.factor_x = 2
  end
end

class SpawnPoint < GameObject
end

class Grabber < GameObject
  traits :collision_detection, :bounding_box, :velocity
  
  def setup
    @image = Image["claw.png"]
    self.scale = 2
    self.rotation_center = :left_middle
    self.hide!
  end
end