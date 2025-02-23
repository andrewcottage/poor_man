module Recipe::ImageGeneration
  extend ActiveSupport::Concern

  included do
    after_create_commit :generate_image, if: -> { image.blank? && author.admin? }
  end

  def generate_image_later
    Recipe::ImageGenerationJob.perform_later(self)
  end

  def generate_image
    client = OpenAI::Client.new

    response = client.images.generate(
      parameters: {
        prompt: image_prompt,
      }
    )

    url = response.dig("data", 0, "url")

    download = Down.download(url)

    image.attach(io: download, filename: "image.jpg")
  end

  def image_prompt
    client = OpenAI::Client.new

    content = """
    generate an image prompt that I can use for dalle for the following recipe
    title: #{title}
    instructions: #{instructions.body.to_plain_text}

    give me the prompt only. Nothing else. I'm going to copy and paste it into dalle.
    """

    response = client.chat(
      parameters: {
        model: "gpt-4o-mini", 
        messages: [{ role: "user", content: content}]    
      }
    )

    response.dig("choices", 0, "message", "content")
  end
end