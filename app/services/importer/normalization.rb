module Importer::Normalization
  module_function

  def text(value)
    return nil if value.nil?

    value.to_s.strip
  end

  def zip(value, _country_code = "FR")
    value.to_s.strip
  end

  def country_code(value)
    text(value)&.first(2)&.upcase
  end

  def decimal(value)
    value.to_s.to_f
  end
end
