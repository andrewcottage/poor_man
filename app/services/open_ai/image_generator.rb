# frozen_string_literal: true

require "base64"
require "stringio"

module OpenAI
  class ImageGenerator
    GeneratedImage = Struct.new(:io, :filename, :content_type, keyword_init: true)

    FALLBACK_MODELS = %w[gpt-image-1.5 gpt-image-1 dall-e-3].freeze

    def initialize(prompt:, size:, basename:, quality: :high, client: OpenAI::Client.new)
      @prompt = prompt
      @size = size
      @basename = basename
      @quality = quality
      @client = client
    end

    def call
      OpenAI::Config.ensure_configured!

      last_error = nil

      models.each do |model|
        return generate_with_model(model)
      rescue StandardError => error
        last_error = error
      end

      raise last_error || "OpenAI image generation failed"
    end

    private

    attr_reader :basename, :client, :prompt, :quality, :size

    def models
      ([ OpenAI::Config.image_model ] + FALLBACK_MODELS).compact.map(&:to_s).reject(&:blank?).uniq
    end

    def generate_with_model(model)
      response = client.images.generate(parameters: parameters_for(model))
      payload = response.fetch("data", []).first || {}

      if payload["b64_json"].present?
        build_from_base64(payload["b64_json"])
      elsif payload["url"].present?
        build_from_url(payload["url"])
      else
        raise "OpenAI image response did not include image data"
      end
    end

    def parameters_for(model)
      if model.start_with?("gpt-image")
        {
          model: model,
          prompt: prompt,
          size: size,
          quality: quality.to_s,
          output_format: "jpeg"
        }
      else
        {
          model: model,
          prompt: prompt,
          size: size,
          quality: quality == :high ? "hd" : "standard",
          style: "natural"
        }
      end
    end

    def build_from_base64(base64_data)
      GeneratedImage.new(
        io: StringIO.new(Base64.decode64(base64_data)),
        filename: "#{basename}.jpg",
        content_type: "image/jpeg"
      )
    end

    def build_from_url(url)
      GeneratedImage.new(
        io: Down.download(url),
        filename: "#{basename}.jpg",
        content_type: "image/jpeg"
      )
    end
  end
end
