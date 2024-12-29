module Recipe::Stars
  extend ActiveSupport::Concern

  def full_stars
    rating.to_i
  end

  def half_stars
    (rating - full_stars >= 0.5)
  end

  def empty_stars
    5 - full_stars - (half_stars ? 1 : 0)
  end

end