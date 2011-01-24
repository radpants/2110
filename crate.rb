class Crate < GameObject
  traits :bounding_box, :collision_detection, :velocity
  attr_accessor :being_held
  
  def setup
    @image = Image['gold_crate.png']
    self.rotation_center = :top_left
    @being_held = false
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
      :nice => 9..9,
      :seven => 10..10,
      :eight => 11..11,
      :nine => 12..12,
      :ten => 13..13,
      :eleven => 14..14,
      :twelve => 15..15
    }
    @numbers = [:one,:two,:three,:four,:five,:six,:seven,:eight,:nine,:ten,:eleven,:twelve]
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
  traits :bounding_box, :collision_detection, :timer
  
  def setup
    @image = Image['crate_drop.png']
    self.rotation_center = :bottom_left
    @sign = Sign.create :x => self.x + 26, :y => self.y - 154, :zorder => 1
    @win_crate_count = self.parent.crates_to_win
    puts "#{@win_crate_count} needed to win"
    @win_sound = Sound["win.wav"]
    reset
  end
  
  def update
    return if @won
    @current_crate_count = 0
    
    self.each_collision(Crate) do |me, crate|
      
      @current_crate_count += 1 unless crate.being_held
      if @current_crate_count >= @win_crate_count
        win
        return
      end
    end
    
    @sign.show_remaining @win_crate_count - @current_crate_count
    #puts @current_crate_count
  end
  
  def win
    @win_sound.play
    @sign.show_victory
    @won = true
    after(1000){ self.parent.next_level }
  end
  
  def reset
    @won = false
  end
    
end