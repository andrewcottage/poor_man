module Recipe::AiGeneration
  extend ActiveSupport::Concern

  class_methods do
    def generate_from_prompt(prompt, user = nil)
      client = OpenAI::Client.new
      
      content = generate_recipe_prompt(prompt)
      
      response = client.chat(
        parameters: {
          model: "gpt-4.1",
          messages: [{ role: "user", content: content }]
        }
      )
      
      recipe_data = JSON.parse(response.dig("choices", 0, "message", "content"))

      Rails.logger.info("Recipe data: #{recipe_data}")
      
      recipe = Recipe.new(
        title: recipe_data["title"],
        blurb: recipe_data["blurb"],
        tag_names: recipe_data["tags"]&.join(", "),
        difficulty: recipe_data["difficulty"],
        prep_time: recipe_data["prep_time"],
        cost: recipe_data["cost"],
        author: user || Current.user,
        ref_id: SecureRandom.uuid
      )
      
      recipe.category = find_or_create_category(recipe_data["category"])
      
      recipe.instructions = recipe_data["instructions"]

      image = recipe.generate_image(recipe.ref_id)
      
      [recipe, image]
    end

    private

    def generate_recipe_prompt(prompt)
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

    def find_or_create_category(category_name)
       return Category.first if category_name.blank?
       
       existing_category = Category.find_by(title: category_name)
       return existing_category if existing_category
       
       # Try to find an existing category with similar name
       similar_category = Category.where("title ILIKE ?", "%#{category_name}%").first
       return similar_category if similar_category
       
       # If no similar category found, return the first available category
       # to avoid creating new categories without images
       Category.first
     end
  end

  def generate_image(ref_id)
    client = OpenAI::Client.new
    
    prompt = generate_image_prompt_from_recipe
    
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
    
    temp_image = TempImage.create!(ref_id: ref_id, image: {
      io: downloaded_file,
      filename: "ai_generated_#{ref_id}.jpg",
      content_type: "image/jpeg"
    })

    temp_image
  end

  private

  def generate_image_prompt_from_recipe
    """
    A beautifully plated #{title.downcase} served on an elegant plate. 
    The dish should look appetizing and professional, with good lighting and food photography style. 
    Focus on the food presentation, vibrant colors, and make it look delicious and restaurant-quality.
    """
  end
end