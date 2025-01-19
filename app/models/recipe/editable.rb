module Recipe::Editable
  extend ActiveSupport::Concern

  def current_user_editable?
    Current&.user&.recipes&.include?(self)
  end
end