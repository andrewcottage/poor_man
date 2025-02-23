module Recipe::ImageGeneration
  extend ActiveSupport::Concern

  included do
    after_create_commit :generate_image, if: -> { image.blank? && author.admin?}
  end

  def generate_image_later
    Recipe::ImageGenerationJob.perform_later(self)
  end

  def generate_image
    client = OpenAI::Client.new

    prompt = """
      image for a the following recipe:
      title: #{title}
      instructions: #{instructions.body.to_plain_text}
    """

    response = client.images.generate(
      parameters: {
        prompt:,
      }
    )

    url = response.dig("data", 0, "url")

    download = Down.download(url)

    image.attach(io: download, filename: "image.jpg")
  end
end