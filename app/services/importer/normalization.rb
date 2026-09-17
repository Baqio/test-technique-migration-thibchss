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
    value.to_s.gsub(',', '.').to_f
  end

  def phone(value, country_code)
    value = text(value)

    return nil if value.blank?

    phone_number = Phonelib.parse(value, country_code ||= "FR").full_e164
    return nil if phone_number.blank?

    phone_number
  end

  def tax_number(value)
    text(value)&.delete(' ')
  end

  def volume_ml(value)
    value = (value.to_s[/\d+(?:[.,]\d+)?/].to_f * 10).round

    return nil if value == 60

    value
  end
end
