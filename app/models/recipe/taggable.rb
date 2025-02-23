module Recipe::Taggable
  extend ActiveSupport::Concern


  included do
    has_many :taggings, as: :taggable, dependent: :destroy
    has_many :tags, through: :taggings

    after_save :assign_tags
  end

  private

  def assign_tags
    puts ";;;;;;;;;;;;;;;;;;"
    puts tag_names
    puts ";;;;;;;;;;;;;;;;;;"
    return unless tag_names.present?

    # Convert input to a unique array of tag names
    new_tag_names = tag_names.split(",").map(&:strip).uniq

    # Find or create the necessary tags
    new_tags = new_tag_names.map { |name| Tag.find_or_create_by(name: name) }

    # Remove taggings that are no longer relevant
    self.tags = new_tags
  end
end