# == Schema Information
#
# Table name: recipe_generations
#
#  id                  :integer          not null, primary key
#  avoid_ingredients   :text
#  customization_notes :text
#  data                :text
#  dietary_preference  :string
#  ingredient_swaps    :text
#  prompt              :text
#  servings            :integer          default(4), not null
#  skill_level         :string
#  target_difficulty   :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  user_id             :integer          not null
#
# Indexes
#
#  index_recipe_generations_on_user_id  (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
class Recipe::Generation < ApplicationRecord

  serialize :data, coder: JSON, default: {}

  has_one_attached :image
  has_many_attached :images

  validates :prompt, presence: true
  validates :servings, numericality: { only_integer: true, greater_than: 0 }
  validates :target_difficulty, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 5 }, allow_blank: true

  after_create_commit :generate_later

  belongs_to :user

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
    client = OpenAI::Client.new

    response = client.images.generate(
      parameters: {
        prompt: formatted_image_prompt,
        model: "dall-e-3",
        size: "1024x1024"
      }
    )

    url = response.dig("data", 0, "url")

    # Download the image and attach it properly to Active Storage
    downloaded_file = Down.download(url)

    image.attach(io: downloaded_file, filename: "ai_generated_#{id}.jpg", content_type: "image/jpeg")
  end

  def generate_images_later
    Recipe::Generation::GenerateImagesJob.perform_later(self)
  end

  def generate_images
    formatted_images_prompts.each_with_index do |prompt, index|
      client = OpenAI::Client.new

      response = client.images.generate(
        parameters: {
          prompt: prompt,
          model: "dall-e-3",
          size: "1024x1024"
        }
      )

      url = response.dig("data", 0, "url")

      # Download the image and attach it properly to Active Storage
      downloaded_file = Down.download(url)

      images.attach(io: downloaded_file, filename: "ai_generated_#{id}_#{index}.jpg", content_type: "image/jpeg")
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

  private

  def formatted_images_prompts
    [
      "A beautiful plated #{prompt} served on an elegant plate.",
      "A close-up of the #{prompt} with the ingredients visible.",
      "A person eating the #{prompt}.",
    ]
  end

  def formatted_image_prompt
    """
    A beautifully plated #{prompt} served on an elegant plate. 
    The dish should look appetizing and professional, with good lighting and food photography style. 
    Focus on the food presentation, vibrant colors, and make it look delicious and restaurant-quality.
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
