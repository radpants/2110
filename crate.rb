class Crate < GameObject
  traits :bounding_box, :collision_detection
  
  def setup
    @image = Image['crate.png']
    self.rotation_center = :left_top
  end
  
  def update
    
  end
  
end