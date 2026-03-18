class Recipe::IngredientParser
  QUANTITY_PATTERN = /
    (?:
      \d+\s+\d+\/\d+|
      \d+\/\d+|
      \d+(?:\.\d+)?(?:\s*(?:-|to)\s*\d+(?:\.\d+)?)?
    )
  /x

  UNITS = %w[
    teaspoon teaspoons tsp
    tablespoon tablespoons tbsp
    cup cups
    ounce ounces oz
    pound pounds lb lbs
    gram grams g
    kilogram kilograms kg
    milliliter milliliters ml
    liter liters l
    clove cloves
    can cans
    package packages pkg pkgs
    bunch bunches
    slice slices
    stick sticks
    pinch pinches
    dash dashes
    sprig sprigs
    head heads
  ].freeze

  INGREDIENTS_HEADER = /^ingredients?\b[:\s-]*/i
  SECTION_BREAK = /^(instructions?|method|directions?|steps?)\b/i
  INSTRUCTION_VERBS = /^(cook|heat|preheat|bake|saute|sauté|stir|mix|serve|simmer|boil|whisk|combine|add)\b/i
  UNIT_PATTERN = /(#{UNITS.join("|")})/i

  class << self
    def parse(source)
      normalized_lines(source).each_with_index.filter_map do |line, index|
        ingredient = parse_line(line)
        next if ingredient.blank?

        ingredient.merge(position: index + 1)
      end
    end

    def parse_structured(items)
      Array(items).each_with_index.filter_map do |item, index|
        attrs = item.to_h.with_indifferent_access
        name = attrs[:name].to_s.strip
        next if name.blank?

        {
          position: index + 1,
          quantity: attrs[:quantity].presence,
          unit: attrs[:unit].presence,
          name: name,
          notes: attrs[:notes].presence,
          raw: build_raw(
            quantity: attrs[:quantity],
            unit: attrs[:unit],
            name: name,
            notes: attrs[:notes]
          )
        }
      end
    end

    def format(items)
      Array(items).filter_map do |item|
        attrs = item.respond_to?(:as_structured_json) ? item.as_structured_json : item.to_h
        build_raw(
          quantity: attrs[:quantity] || attrs["quantity"],
          unit: attrs[:unit] || attrs["unit"],
          name: attrs[:name] || attrs["name"],
          notes: attrs[:notes] || attrs["notes"]
        ).presence
      end.join("\n")
    end

    private

    def normalized_lines(source)
      plain_text = strip_markup(source)
      lines = plain_text.split("\n").map { |line| normalize_line(line) }.reject(&:blank?)
      section_lines = extract_ingredient_section(lines)

      candidates = section_lines.presence || lines.select { |line| ingredient_candidate?(line) }
      candidates.uniq
    end

    def extract_ingredient_section(lines)
      capturing = false
      extracted = []

      lines.each do |line|
        if line.match?(INGREDIENTS_HEADER)
          capturing = true
          candidate = normalize_line(line.sub(INGREDIENTS_HEADER, ""))
          extracted << candidate if candidate.present?
          next
        end

        next unless capturing
        break if line.match?(SECTION_BREAK)

        extracted << line
      end

      extracted.reject(&:blank?)
    end

    def ingredient_candidate?(line)
      return false if line.blank?
      return false if line.match?(SECTION_BREAK)
      return false if line.match?(INSTRUCTION_VERBS) && !line.match?(/\A#{QUANTITY_PATTERN}\b/)

      line.match?(/\A#{QUANTITY_PATTERN}\b/) || line.match?(UNIT_PATTERN) || line.split.size <= 6
    end

    def parse_line(line)
      normalized = normalize_line(line)
      return if normalized.blank?

      with_unit = normalized.match(/\A(?<quantity>#{QUANTITY_PATTERN})\s+(?<unit>#{UNIT_PATTERN})\b\.?\s+(?<name>.+)\z/i)
      without_unit = normalized.match(/\A(?<quantity>#{QUANTITY_PATTERN})\s+(?<name>.+)\z/i)

      if with_unit
        name, notes = split_name_and_notes(with_unit[:name])
        return build_hash(
          quantity: with_unit[:quantity],
          unit: with_unit[:unit],
          name: name,
          notes: notes,
          raw: normalized
        )
      end

      if without_unit
        name, notes = split_name_and_notes(without_unit[:name])
        return build_hash(
          quantity: without_unit[:quantity],
          name: name,
          notes: notes,
          raw: normalized
        )
      end

      name, notes = split_name_and_notes(normalized)
      build_hash(name: name, notes: notes, raw: normalized)
    end

    def build_hash(quantity: nil, unit: nil, name:, notes: nil, raw:)
      return if name.blank?

      {
        quantity: quantity.presence,
        unit: unit.to_s.downcase.presence,
        name: name,
        notes: notes.presence,
        raw: raw
      }.compact
    end

    def split_name_and_notes(text)
      candidate = text.to_s.strip.sub(/\Aof\s+/i, "")

      if (match = candidate.match(/\A(?<name>.+?)\s*\((?<notes>.+)\)\z/))
        [ match[:name].strip, match[:notes].strip ]
      elsif candidate.include?(",")
        name, notes = candidate.split(",", 2)
        [ name.to_s.strip, notes.to_s.strip ]
      else
        [ candidate, nil ]
      end
    end

    def build_raw(quantity:, unit:, name:, notes: nil)
      text = [
        quantity.presence,
        unit.presence,
        name.to_s.strip.presence
      ].compact.join(" ")

      return text if notes.blank?

      "#{text}, #{notes}"
    end

    def normalize_line(line)
      line.to_s
        .gsub(/\u2022/, "*")
        .strip
        .sub(/\A(?:[-*]\s+|\d+[.)]\s+)/, "")
        .strip
    end

    def strip_markup(source)
      ActionView::Base.full_sanitizer
        .sanitize(source.to_s)
        .to_s
        .gsub(/\r\n?/, "\n")
    end
  end
end
