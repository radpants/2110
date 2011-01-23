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