module ApplicationHelper
  include Pagy::Frontend

  def opengraph_title
    title = content_for(:opengraph_title) || 'Poor Man With a Pan | Recipes for the Home Cook'

    content_tag(:meta, nil, property: 'og:title', content: title)
  end

  def opengraph_description
    description = content_for(:opengraph_description) || 'Recipes for the Home Cook'

    content_tag(:meta, nil, property: 'og:description', content: description)
  end

  def opengraph_image
   image =  content_for(:opengraph_image) || image_url('logo.jpg')

    content_tag(:meta, nil, property: 'og:image', content: image)
  end
end
