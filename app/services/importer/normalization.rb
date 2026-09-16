module Importer::Normalization
  module_function

  def text(value)
    return nil if value.nil?

    value.to_s.strip
  end

  def zip(value, _country_code = "FR")
    value = text(value)
    return nil if value.blank?
    
    value.prepend('0') if value.size == 4 && _country_code == "FR"
  end

  def country_code(value)
    text(value)&.first(2)&.upcase
  end

  def decimal(value)
    value.to_s.to_f
  end
end
