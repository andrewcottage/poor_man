# frozen_string_literal: true

require "digest"
require "erb"
require "fileutils"
require "stringio"
require "yaml"

module SeedCatalog
  class Loader
    DATA_ROOT = Rails.root.join("db/seeds/catalog")

    def self.run
      new.run
    end

    def run
      admin = seed_admin
      categories = seed_categories.index_by(&:slug)

      seed_recipes(author: admin, categories: categories)
    end

    private

    def seed_admin
      user = User.find_or_initialize_by(email: "admin@stovaro.com")
      user.username ||= "stovaro_admin"
      user.admin = true
      user.password = "password" if user.new_record? || user.password_digest.blank?
      user.save!
      user
    end

    def seed_categories
      dataset("categories.yml").map do |attrs|
        category = Category.find_or_initialize_by(slug: attrs.fetch("slug"))
        category.assign_attributes(
          title: attrs.fetch("title"),
          description: attrs.fetch("description")
        )
        attach_image!(category, attrs.fetch("image_path"))
        category.save!
        category
      end
    end

    def seed_recipes(author:, categories:)
      dataset("recipes.yml").each do |attrs|
        recipe = Recipe.find_or_initialize_by(slug: attrs.fetch("slug"))
        recipe.assign_attributes(
          title: attrs.fetch("title"),
          blurb: attrs.fetch("blurb"),
          instructions: format_instructions(attrs.fetch("instructions")),
          difficulty: attrs.fetch("difficulty"),
          prep_time: attrs.fetch("prep_time"),
          servings: attrs.fetch("servings"),
          cost: attrs.fetch("cost"),
          tag_names: Array(attrs["tags"]).join(", ")
        )
        recipe.author = author
        recipe.category = categories.fetch(attrs.fetch("category_slug"))
        attach_image!(recipe, attrs.fetch("image_path"))
        recipe.save!
        recipe.sync_recipe_ingredients!(structured_ingredients: attrs.fetch("ingredients"))
      end
    end

    def dataset(filename)
      YAML.safe_load_file(DATA_ROOT.join(filename), aliases: true)
    end

    def format_instructions(steps)
      Array(steps).map do |step|
        "<p>#{ERB::Util.html_escape(step)}</p>"
      end.join
    end

    def attach_image!(record, relative_path)
      path = Rails.root.join(relative_path)
      raise ArgumentError, "Missing seed image: #{relative_path}" unless path.exist?

      filename = path.basename.to_s
      desired_checksum = Digest::MD5.base64digest(File.binread(path))
      existing_checksum = record.image_attachment&.blob&.checksum
      return if record.image.attached? && existing_checksum == desired_checksum

      record.image.attach(
        io: StringIO.new(File.binread(path)),
        filename: filename,
        content_type: Marcel::MimeType.for(path, name: filename)
      )
    end
  end

  class ImageGenerator
    DATASETS = {
      "categories" => "categories.yml",
      "recipes" => "recipes.yml"
    }.freeze
    RECIPE_SIZE = "1792x1024"
    CATEGORY_SIZE = "1024x1024"

    def initialize(target:, only: nil, force: false)
      @targets = normalize_targets(target)
      @only = only.presence
      @force = force
      @client = OpenAI::Client.new
    end

    def run
      raise "OpenAI is not configured" if openai_not_configured?

      targets.each { |target| generate_target(target) }
    end

    private

    attr_reader :client, :force, :only, :targets

    def normalize_targets(target)
      requested = target.to_s.presence || "recipes"
      values = requested == "all" ? DATASETS.keys : requested.split(",").map(&:strip)
      values.select { |value| DATASETS.key?(value) }.presence || [ "recipes" ]
    end

    def generate_target(target)
      dataset(DATASETS.fetch(target)).each do |attrs|
        slug = attrs["slug"].presence || attrs["title"].to_s.parameterize
        next if only.present? && slug != only

        prompt = attrs["image_prompt"].to_s.strip
        next if prompt.blank?

        output_path = Rails.root.join(attrs.fetch("image_path"))
        next if output_path.exist? && !force

        puts "Generating #{target.singularize} image for #{slug}..."
        generate_image_file!(
          prompt: prompt,
          output_path: output_path,
          size: target == "recipes" ? RECIPE_SIZE : CATEGORY_SIZE
        )
      end
    end

    def generate_image_file!(prompt:, output_path:, size:)
      download = nil

      response = client.images.generate(
        parameters: {
          model: "dall-e-3",
          prompt: prompt,
          size: size,
          quality: "hd",
          style: "natural"
        }
      )

      url = response.dig("data", 0, "url")
      raise "OpenAI image response did not include a URL" if url.blank?

      download = Down.download(url)
      FileUtils.mkdir_p(output_path.dirname)
      IO.copy_stream(download, output_path)
    ensure
      download&.close! if download.respond_to?(:close!)
    end

    def dataset(filename)
      YAML.safe_load_file(Loader::DATA_ROOT.join(filename), aliases: true)
    end

    def openai_not_configured?
      credentials_secret = Rails.application.credentials.dig(:open_ai, :secret)
    rescue ActiveSupport::EncryptedFile::MissingKeyError, ActiveSupport::MessageEncryptor::InvalidMessage
      credentials_secret = nil
      secrets_secret = Rails.application.secrets.dig(:open_ai, :secret) if Rails.application.respond_to?(:secrets)

      credentials_secret.blank? && secrets_secret.blank?
    else
      secrets_secret = Rails.application.secrets.dig(:open_ai, :secret) if Rails.application.respond_to?(:secrets)

      credentials_secret.blank? && secrets_secret.blank?
    end
  end
end
