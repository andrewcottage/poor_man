module StarHelper

  def full_stars(rating)
    rating.to_i
  end

  def half_star(rating)
    (rating - full_stars(rating) >= 0.5)
  end

  def empty_stars(rating)
    5 - full_stars(rating) - (half_star(rating) ? 1 : 0)
  end
end
