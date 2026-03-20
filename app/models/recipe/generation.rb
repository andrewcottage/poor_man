# == Schema Information
#
# Table name: recipe_generations
#
#  id                  :integer          not null, primary key
#  auto_publish_recipe :boolean          default(FALSE), not null
#  avoid_ingredients   :text
#  customization_notes :text
#  data                :text
#  dietary_preference  :string
#  ingredient_swaps    :text
#  prompt              :text
#  published_at        :datetime
#  seed_publish_error  :text
#  seed_tool           :boolean          default(FALSE), not null
#  servings            :integer          default(4), not null
#  skill_level         :string
#  target_difficulty   :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  published_recipe_id :integer
#  user_id             :integer          not null
#
# Indexes
#
#  index_recipe_generations_on_published_recipe_id  (published_recipe_id)
#  index_recipe_generations_on_user_id              (user_id)
#
# Foreign Keys
#
#  published_recipe_id  (published_recipe_id => recipes.id)
#  user_id              (user_id => users.id)
#
class Recipe::Generation < ApplicationRecord
  attr_accessor :skip_background_generation


  serialize :data, coder: JSON, default: {}

  has_one_attached :image
  has_many_attached :images

  validates :prompt, presence: true
  validates :servings, numericality: { only_integer: true, greater_than: 0 }
  validates :target_difficulty, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 5 }, allow_blank: true

  after_create_commit :generate_later, unless: :skip_background_generation

  belongs_to :user
  belongs_to :published_recipe, class_name: "Recipe", optional: true

  scope :seed_runs, -> { where(seed_tool: true) }

  def complete?
    data.present? && image.attached? && images.attached?
  end
  
  def generate_later
    generate_recipe_later
    generate_images_later
    generate_image_later
  end

  def generate_recipe_later
    Recipe::Generation::GenerateDataJob.perform_later(self)
  end

  def generate_recipe
    client = OpenAI::Client.new

    content = formatted_prompt

    response = client.chat(
      parameters: {
        model: "gpt-4.1",
        messages: [{ role: "user", content: content }]
      }
    )

    update(data: JSON.parse(response.dig("choices", 0, "message", "content")))
  end

  def generate_instructions
    return if data.blank?

    client = OpenAI::Client.new
    response = client.chat(
      parameters: {
        model: "gpt-4.1",
        messages: [{ role: "user", content: formatted_instruction_regeneration_prompt }]
      }
    )

    updated_data = data.deep_dup
    updated_data["instructions"] = response.dig("choices", 0, "message", "content").to_s.strip
    update!(data: updated_data)
  end

  def generate_image_later
    Recipe::Generation::GenerateImageJob.perform_later(self)
  end

  def generate_image
    generated_image = OpenAI::ImageGenerator.new(
      prompt: formatted_image_prompt,
      size: "1536x1024",
      basename: "ai_generated_#{id}"
    ).call

    image.attach(
      io: generated_image.io,
      filename: generated_image.filename,
      content_type: generated_image.content_type
    )
  end

  def generate_images_later
    Recipe::Generation::GenerateImagesJob.perform_later(self)
  end

  def generate_images
    formatted_images_prompts.each_with_index do |prompt, index|
      generated_image = OpenAI::ImageGenerator.new(
        prompt: prompt,
        size: "1536x1024",
        basename: "ai_generated_#{id}_#{index}"
      ).call

      images.attach(
        io: generated_image.io,
        filename: generated_image.filename,
        content_type: generated_image.content_type
      )
    end
  end

  def regenerate_recipe_data_later
    generate_recipe_later
  end

  def regenerate_instructions_later
    Recipe::Generation::GenerateInstructionsJob.perform_later(self)
  end

  def regenerate_images_later
    image.purge_later if image.attached?
    images.each(&:purge_later)
    generate_image_later
    generate_images_later
  end

  def auto_publish_seed_recipe?
    seed_tool? && auto_publish_recipe?
  end

  def publish_seed_recipe_if_ready_later
    return unless auto_publish_seed_recipe?
    return unless complete?
    return if published_recipe.present?

    Recipe::Generation::PublishJob.perform_later(self)
  end

  private

  def formatted_images_prompts
    [
      "Photorealistic editorial food photography of #{prompt}, plated as a finished hero dish in natural light, shallow depth of field, realistic texture, no illustration, no text.",
      "Tight photorealistic close-up of #{prompt} highlighting texture, steam, sauce, and ingredients with premium magazine-style food photography lighting, no illustration, no text.",
      "Overhead photorealistic table scene featuring #{prompt} served family-style with realistic props and natural shadows, premium cookbook styling, no illustration, no text."
    ]
  end

  def formatted_image_prompt
    """
    Photorealistic editorial food photography of #{prompt}.
    The dish should look genuinely cooked and camera-ready, with realistic ingredients, natural light,
    shallow depth of field, subtle steam when appropriate, premium magazine styling, and no illustration,
    CGI look, text, watermark, or surreal plating.
    """
  end

  def formatted_prompt
    <<~PROMPT
    Generate a complete recipe based on this prompt: "#{prompt}"
    
    Please respond with ONLY a valid JSON object with the following structure:
    {
      "title": "Recipe Title",
      "blurb": "A short description of the recipe (1-2 sentences)",
      "ingredients": [
        { "quantity": "2", "unit": "cups", "name": "flour", "notes": "all-purpose" }
      ],
      "instructions": "Step-by-step cooking instructions in HTML format with proper paragraph tags",
      "tags": ["tag1", "tag2", "tag3"],
      "difficulty": 3,
      "prep_time": 30,
      "cost": 15.99,
      "servings": 4,
      "category": "Category Name"
    }
    
    Guidelines:
    - difficulty should be 1-5 (1 = very easy, 5 = very hard)
    - prep_time should be in minutes
    - cost should be estimated ingredient cost in USD
    - servings should be the number of servings the recipe makes
    - ingredients should include quantity, unit when relevant, ingredient name, and optional notes
    - instructions should be step-by-step cooking guidance only, written in an SEO-friendly manner
    - tags should be relevant cooking/ingredient tags
    - category should be a broad category like "Breakfast", "Dinner", "Dessert", etc.
    - respect dietary_preference, skill_level, avoid_ingredients, ingredient_swaps, target_difficulty, servings, and customization_notes when present

    Generation settings:
    - dietary_preference: #{dietary_preference.presence || "none"}
    - skill_level: #{skill_level.presence || "standard"}
    - avoid_ingredients: #{avoid_ingredients.presence || "none"}
    - ingredient_swaps: #{ingredient_swaps.presence || "none"}
    - target_difficulty: #{target_difficulty.presence || "best fit"}
    - servings: #{servings}
    - customization_notes: #{customization_notes.presence || "none"}
    
    Return ONLY the JSON object, no additional text.
    PROMPT
  end

  def formatted_instruction_regeneration_prompt
    <<~PROMPT
    Rewrite only the instructions for this recipe and return HTML with paragraph tags. Do not include markdown or JSON.

    Title: #{data["title"]}
    Blurb: #{data["blurb"]}
    Ingredients: #{Array(data["ingredients"]).map { |ingredient| ingredient.to_json }.join(", ")}
    Dietary preference: #{dietary_preference.presence || "none"}
    Skill level: #{skill_level.presence || "standard"}
    Avoid ingredients: #{avoid_ingredients.presence || "none"}
    Ingredient swaps: #{ingredient_swaps.presence || "none"}
    Target difficulty: #{target_difficulty.presence || data["difficulty"] || "best fit"}
    Servings: #{servings}
    Customization notes: #{customization_notes.presence || "none"}
    PROMPT
  end
end
