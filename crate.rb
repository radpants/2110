class Crate < GameObject
  traits :bounding_box, :collision_detection, :velocity
  
  def setup
    @image = Image['crate.png']
    self.rotation_center = :top_left
  end
  
  def update
    return unless self.parent.viewport.inside? self
  end
  
end

class Sign < GameObject
  
  def setup
    self.rotation_center = :top_left
    @animations = Animation.new( :file => "sign_38x20.png" )
    @animations.frame_names = { 
      :one => 0..0, 
      :two => 1..1,
      :three => 2..2,
      :four => 3..3,
      :five => 4..4,
      :six => 5..5,
      :yay => 6..6,
      :win => 7..7,
      :woot => 8..8,
      :nice => 9..9
    }
    @numbers = [:one,:two,:three,:four,:five,:six]
    @victories = [:yay, :win, :woot, :nice]
    @animation = @animations[:nice]
    update
  end
  
  def update
    @image = @animation.next
  end
  
  def show_remaining how_many
    if how_many >= 0 and how_many < @numbers.count
      @animation = @animations[ @numbers[ how_many - 1 ] ]
    end
  end
  
  def show_victory
    @animation = @animations[ @victories[ (rand * @victories.count).to_i ] ]
  end
end
    

class CrateDrop < GameObject
  traits :bounding_box, :collision_detection
  
  def setup
    @image = Image['crate_drop.png']
    self.rotation_center = :bottom_left
    @sign = Sign.create :x => self.x + 26, :y => self.y - 154, :zorder => 1
    @win_crate_count = 5
  end
  
  def update
    @current_crate_count = 0
    
    self.each_collision(Crate) do |me, crate|
      @current_crate_count += 1
      
      
      if @current_crate_count >= @win_crate_count
        win
      end
    end
    
    @sign.show_remaining @win_crate_count - @current_crate_count
  end
  
  def win
    @sign.show_victory
  end
    
end