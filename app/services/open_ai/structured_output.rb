# frozen_string_literal: true

module OpenAI
  module StructuredOutput
    module_function

    def parse_json_object!(content)
      parsed = JSON.parse(normalized_content(content))
      return parsed if parsed.is_a?(Hash)

      raise JSON::ParserError, "Expected JSON object response"
    end

    def normalized_content(content)
      raw = extract_text(content).strip
      return raw if raw.start_with?("{") && raw.end_with?("}")

      fenced = raw.match(/```(?:json)?\s*(\{.*\})\s*```/m)
      return fenced[1] if fenced

      first_brace = raw.index("{")
      last_brace = raw.rindex("}")
      return raw[first_brace..last_brace] if first_brace && last_brace && last_brace > first_brace

      raw
    end

    def extract_text(content)
      case content
      when String
        content
      when Array
        content.filter_map do |part|
          next unless part.is_a?(Hash)
          next part["text"] if part["type"] == "text"

          part["content"]
        end.join("\n")
      when Hash
        content["text"].presence || content["content"].to_s
      else
        content.to_s
      end
    end
  end
end
