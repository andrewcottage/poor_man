namespace :seeds do
  desc "Generate repo-backed seed images from the prompts in db/seeds/catalog/*.yml"
  task generate_images: :environment do
    require Rails.root.join("db/seeds/catalog").to_s

    SeedCatalog::ImageGenerator.new(
      target: ENV.fetch("TARGET", "recipes"),
      only: ENV["ONLY"],
      force: ENV["FORCE"].present?
    ).run
  end
end
