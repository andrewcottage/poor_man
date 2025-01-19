module Recipe::Editable
  extend ActiveSupport::Concern

  def current_user_editable?
    Current&.user&.recipes&.find_by(id: id).present?
  end
end