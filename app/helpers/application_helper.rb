module ApplicationHelper
  include Pagy::Frontend

  def opengraph_title
    title = @opengraph_title || I18n.t("meta_title")

    content_tag(:meta, nil, property: 'og:title', content: title)
  end

  def opengraph_description
    description = @opengraph_description || 'Recipes for the Home Cook'

    content_tag(:meta, nil, property: 'og:description', content: description)
  end

  def opengraph_image
   image =  @opengraph_image || image_url('logo.jpg')

    content_tag(:meta, nil, property: 'og:image', content: image)
  end
end
