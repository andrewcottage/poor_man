# frozen_string_literal: true

require "stringio"

class CategorySeedRunPublisher
  class PublishError < StandardError; end

  def initialize(category_seed_run)
    @category_seed_run = category_seed_run
  end

  def call
    category_seed_run.with_lock do
      return category_seed_run.published_category if category_seed_run.published_category.present?

      ensure_publishable!

      category = find_or_initialize_category
      category.title = title
      category.slug = resolved_slug(category)
      category.description = description
      attach_preview_image!(category)
      category.save!

      category_seed_run.update!(
        published_category: category,
        published_at: Time.current,
        seed_publish_error: nil
      )

      category
    end
  rescue StandardError => error
    category_seed_run.update_column(:seed_publish_error, error.message) if category_seed_run.persisted?
    raise
  end

  private

  attr_reader :category_seed_run

  def ensure_publishable!
    raise PublishError, "Category preview is still in progress." unless category_seed_run.complete?
    raise PublishError, "Category preview is missing a title." if title.blank?
  end

  def find_or_initialize_category
    Category.find_by("LOWER(title) = ? OR LOWER(slug) = ?", title.downcase, slug.downcase) || Category.new
  end

  def resolved_slug(category)
    return category.slug if category.persisted?
    return slug unless Category.exists?(slug: slug)

    counter = 2
    candidate = "#{slug}-#{counter}"

    while Category.exists?(slug: candidate)
      counter += 1
      candidate = "#{slug}-#{counter}"
    end

    candidate
  end

  def attach_preview_image!(category)
    category.image.attach(
      io: StringIO.new(category_seed_run.image.download),
      filename: category_seed_run.image.filename.to_s,
      content_type: category_seed_run.image.content_type
    )
  end

  def data
    category_seed_run.data || {}
  end

  def title
    data["title"].to_s.squish
  end

  def slug
    data["slug"].to_s.parameterize.presence || title.parameterize
  end

  def description
    data["description"].to_s.squish
  end
end
