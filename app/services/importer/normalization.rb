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
    value
  end

  def country_code(value)
    value = text(value)&.downcase

    return nil if value.blank?
    return value.upcase if value.size == 2

    @country_codes ||= {}
    @country_codes[value] ||= ISO3166::Country.find_country_by_any_name(value)

    @country_codes[value].alpha2
  end

  def decimal(value)
    value.to_s.to_f
  end
end
