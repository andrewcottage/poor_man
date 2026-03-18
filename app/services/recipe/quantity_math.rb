class Recipe::QuantityMath
  class << self
    def parse(value)
      text = value.to_s.strip
      return if text.blank?

      case text
      when /\A\d+\z/
        Rational(text.to_i, 1)
      when /\A\d+\.\d+\z/
        Rational(text)
      when /\A\d+\/\d+\z/
        Rational(text)
      when /\A\d+\s+\d+\/\d+\z/
        whole, fraction = text.split(/\s+/, 2)
        Rational(whole.to_i, 1) + Rational(fraction)
      else
        nil
      end
    end

    def format(value)
      return if value.blank?

      whole = value.to_i
      remainder = value - whole

      return whole.to_s if remainder.zero?
      return remainder.to_s if whole.zero?

      "#{whole} #{remainder}"
    end

    def scaled_text(quantity, factor)
      parsed = parse(quantity)
      return quantity if parsed.blank?

      format(parsed * factor)
    end
  end
end
