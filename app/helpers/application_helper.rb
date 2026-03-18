module ApplicationHelper
  include Pagy::Frontend

  def stovaro_nav_link_classes(active = false)
    base = "inline-flex items-center rounded-full px-4 py-2 text-sm font-semibold transition-colors duration-150"

    if active
      "#{base} bg-slate-900 text-white shadow-sm"
    else
      "#{base} text-slate-700 hover:bg-white hover:text-slate-900"
    end
  end

  def stovaro_mobile_nav_link_classes(active = false)
    base = "-mx-2 block rounded-2xl px-4 py-3 text-base font-semibold leading-7 transition-colors duration-150"

    if active
      "#{base} bg-white text-slate-950"
    else
      "#{base} text-slate-200 hover:bg-white/10 hover:text-white"
    end
  end

  def stovaro_account_menu_link_classes(danger: false)
    base = "block rounded-xl px-4 py-2 text-sm font-medium transition-colors duration-150"

    if danger
      "#{base} text-red-700 hover:bg-red-50"
    else
      "#{base} text-slate-700 hover:bg-stone-100"
    end
  end

  def stovaro_account_label(user = Current.user)
    return "Account" if user.blank?

    user.username.presence || user.email.to_s.split("@").first
  end

  def stovaro_account_initials(user = Current.user)
    label = stovaro_account_label(user)

    label.scan(/[A-Za-z0-9]/).first(2).join.upcase.presence || "ST"
  end

  def opengraph_title
    title = @opengraph_title || I18n.t("meta.title")

    content_tag(:meta, nil, property: 'og:title', content: title)
  end

  def opengraph_description
    description = @opengraph_description || I18n.t("meta.description")

    content_tag(:meta, nil, property: 'og:description', content: description)
  end

  def opengraph_image
   image =  @opengraph_image || image_url('logo.png')

    content_tag(:meta, nil, property: 'og:image', content: image)
  end
end
