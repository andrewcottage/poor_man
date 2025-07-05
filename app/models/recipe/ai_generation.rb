module Recipe::AiGeneration
  extend ActiveSupport::Concern

  class_methods do
    def generate_from_prompt(prompt, user = nil)
      client = OpenAI::Client.new
      
      content = generate_recipe_prompt(prompt)
      
      response = client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [{ role: "user", content: content }]
        }
      )
      
      recipe_data = JSON.parse(response.dig("choices", 0, "message", "content"))
      
      recipe = Recipe.new(
        title: recipe_data["title"],
        blurb: recipe_data["blurb"],
        instructions: recipe_data["instructions"],
        tag_names: recipe_data["tags"]&.join(", "),
        difficulty: recipe_data["difficulty"],
        prep_time: recipe_data["prep_time"],
        cost: recipe_data["cost"],
        author: user || Current.user
      )
      
      recipe.category = find_or_create_category(recipe_data["category"])
      
      recipe
    end

    private

    def generate_recipe_prompt(prompt)
      """
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
      - instructions should be detailed, step-by-step in HTML format
      - tags should be relevant cooking/ingredient tags
      - category should be a broad category like "Breakfast", "Dinner", "Dessert", etc.
      
      Return ONLY the JSON object, no additional text.
      """
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

  def generate_image_from_ai
    return unless persisted?
    
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
    
    download = Down.download(url)
    image.attach(io: download, filename: "ai_generated_image.jpg")
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