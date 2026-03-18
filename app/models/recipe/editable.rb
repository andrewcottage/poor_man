module Recipe::Editable
  extend ActiveSupport::Concern

  def current_user_editable?
    Current.user&.admin? || Current.user&.recipes&.exists?(id: id)
  end
end
