# frozen_string_literal: true

module OpenAITestHelper
  OPENAI_API_BASE = "https://api.openai.com/v1"
  OPENAI_IMAGE_FIXTURE = Rails.root.join("test/fixtures/files/vaporwave.jpeg")

  def stub_openai_recipe_generation_response(
    title:,
    blurb:,
    ingredients:,
    instructions:,
    tags:,
    difficulty:,
    prep_time:,
    cost:,
    servings:,
    category:
  )
    stub_request(:post, "#{OPENAI_API_BASE}/chat/completions").to_return(
      status: 200,
      headers: json_headers,
      body: {
        choices: [
          {
            message: {
              role: "assistant",
              content: {
                title: title,
                blurb: blurb,
                ingredients: ingredients,
                instructions: instructions,
                tags: tags,
                difficulty: difficulty,
                prep_time: prep_time,
                cost: cost,
                servings: servings,
                category: category
              }.to_json
            }
          }
        ]
      }.to_json
    )
  end

  def stub_openai_chat_responses(*messages)
    responses = messages.map do |message|
      {
        status: 200,
        headers: json_headers,
        body: {
          choices: [
            {
              message: message
            }
          ]
        }.to_json
      }
    end

    stub_request(:post, "#{OPENAI_API_BASE}/chat/completions").to_return(*responses)
  end

  def stub_openai_image_generation_sequence(count:, prefix: "seed-preview")
    urls = Array.new(count) { |index| "https://files.openai.test/#{prefix}-#{index}.jpg" }

    stub_request(:post, "#{OPENAI_API_BASE}/images/generations").to_return(
      *urls.map do |url|
        {
          status: 200,
          headers: json_headers,
          body: { data: [ { url: url } ] }.to_json
        }
      end
    )

    image_bytes = File.binread(OPENAI_IMAGE_FIXTURE)
    urls.each do |url|
      stub_request(:get, url).to_return(
        status: 200,
        headers: { "Content-Type" => "image/jpeg" },
        body: image_bytes
      )
    end
  end

  def stub_seed_preview_generation(
    title: "Roasted Cauliflower Grain Bowl",
    category: "Grain Bowls",
    tags: [ "vegetarian", "grain bowl" ]
  )
    stub_openai_recipe_generation_response(
      title: title,
      blurb: "A hearty bowl with roasted vegetables and tahini dressing.",
      ingredients: [
        { quantity: "1", unit: "head", name: "cauliflower" },
        { quantity: "1", unit: "cup", name: "farro" }
      ],
      instructions: "<p>Roast the cauliflower.</p><p>Cook the farro.</p>",
      tags: tags,
      difficulty: 2,
      prep_time: 35,
      cost: 14.5,
      servings: 4,
      category: category
    )

    stub_openai_image_generation_sequence(count: 4, prefix: title.parameterize)
  end

  def stub_openai_category_generation_response(
    title:,
    slug:,
    description:
  )
    stub_request(:post, "#{OPENAI_API_BASE}/chat/completions").to_return(
      status: 200,
      headers: json_headers,
      body: {
        choices: [
          {
            message: {
              role: "assistant",
              content: {
                title: title,
                slug: slug,
                description: description
              }.to_json
            }
          }
        ]
      }.to_json
    )
  end

  def stub_seed_category_preview(
    title: "Weeknight Pasta",
    slug: "weeknight-pasta",
    description: "Fast, satisfying pasta recipes built for busy evenings."
  )
    stub_openai_category_generation_response(
      title: title,
      slug: slug,
      description: description
    )

    stub_openai_image_generation_sequence(count: 1, prefix: slug)
  end

  private

  def json_headers
    { "Content-Type" => "application/json" }
  end
end
