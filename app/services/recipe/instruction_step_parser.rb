class Recipe::InstructionStepParser
  class << self
    def parse(source)
      plain_text = ActionView::Base.full_sanitizer.sanitize(source.to_s).to_s
      paragraphs = plain_text.split(/\n+/).map(&:strip).reject(&:blank?)

      return paragraphs if paragraphs.many?

      plain_text.split(/(?<=[.!?])\s+/).map(&:strip).reject(&:blank?)
    end
  end
end
