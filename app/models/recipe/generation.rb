# == Schema Information
#
# Table name: recipe_generations
#
#  id         :integer          not null, primary key
#  data       :text
#  prompt     :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer          not null
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

  after_create_commit :generate_later

  belongs_to :user

  def complete?
    data.present? && image.attached? && images.attached?
  end
  
  def generate_later
    generate_recipe_later
    generate_images_later
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

  def generate_images_later
    Recipe::Generation::GenerateImagesJob.perform_later(self)
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
      "instructions": "Complete cooking instructions in HTML format with proper paragraph tags",
      "tags": ["tag1", "tag2", "tag3"],
      "difficulty": 3,
      "prep_time": 30,
      "cost": 15.99,
      "category": "Category Name"
    }
    
    Guidelines:
    - difficulty should be 1-5 (1 = very easy, 5 = very hard)
    - prep_time should be in minutes
    - cost should be estimated ingredient cost in USD
    - instructions A combined section that includes both the list of ingredients and step-by-step guidance on how to make the dish, written in an SEO-friendly manner.
    - tags should be relevant cooking/ingredient tags
    - category should be a broad category like "Breakfast", "Dinner", "Dessert", etc.
    
    Return ONLY the JSON object, no additional text.
    PROMPT
  end
end
