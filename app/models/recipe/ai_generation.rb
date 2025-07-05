module Recipe::AiGeneration
  extend ActiveSupport::Concern

  class_methods do
    def generate_from_prompt(prompt)
      client = OpenAI::Client.new
      
      # Get available categories for better suggestions
      categories = Category.all.map { |c| { id: c.id, title: c.title } }
      formatted_categories = categories.map { |c| "#{c[:id]}: #{c[:title]}" }.join(", ")
      
      system_prompt = <<~PROMPT
        You are a professional chef and recipe creator. Generate a complete recipe based on the user's prompt.
        
        Here are the available recipe categories: #{formatted_categories}
        
        Return the response as a JSON object with the following structure:
        {
          "title": "Recipe Title",
          "blurb": "A brief description of the recipe (2-3 sentences)",
          "instructions": "Detailed step-by-step cooking instructions in HTML format",
          "tag_names": "comma-separated list of relevant tags",
          "cost": "estimated cost in USD (just the number, e.g., 15.99)",
          "difficulty": "difficulty level from 1-5 (integer)",
          "prep_time": "preparation time in minutes (integer)",
          "suggested_category_id": "the ID of the most appropriate category from the list above",
          "image_prompt": "a detailed prompt for generating an image of this dish"
        }
        
        Make sure the instructions are detailed and clear, formatted as HTML with proper paragraphs and lists.
        The cost should be a reasonable estimate for the ingredients.
        Tags should be relevant cooking terms, ingredients, or cuisine types.
        Choose the most appropriate category ID from the available categories.
      PROMPT

      response = client.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [
            { role: "system", content: system_prompt },
            { role: "user", content: prompt }
          ],
          response_format: { type: "json_object" }
        }
      )

      generated_content = JSON.parse(response.dig("choices", 0, "message", "content"))
      
      # Generate slug from title
      slug = generated_content["title"].parameterize
      base_slug = slug
      counter = 1
      
      while Recipe.exists?(slug: slug)
        slug = "#{base_slug}-#{counter}"
        counter += 1
      end
      
      generated_content["slug"] = slug
      
      # Validate category suggestion
      if generated_content["suggested_category_id"] && 
         !Category.exists?(id: generated_content["suggested_category_id"])
        generated_content["suggested_category_id"] = Category.first&.id
      end
      
      # Generate image if image_prompt is present
      if generated_content["image_prompt"].present?
        begin
          image_url = generate_image_from_prompt(generated_content["image_prompt"])
          generated_content["image_url"] = image_url
        rescue StandardError => e
          Rails.logger.error "Failed to generate image: #{e.message}"
          # Continue without image
        end
      end
      
      generated_content
    end

    private

    def generate_image_from_prompt(image_prompt)
      client = OpenAI::Client.new

      response = client.images.generate(
        parameters: {
          prompt: image_prompt,
          size: "1024x1024",
          quality: "standard",
          n: 1
        }
      )

      response.dig("data", 0, "url")
    end
  end
end