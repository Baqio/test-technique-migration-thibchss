class Customer::Import::Cavegest::Address
  N = Importer::Normalization
  COMPARED_ATTRIBUTES = %i[address1 zip city country_code].freeze

  def initialize(row, indexes)
    @row = row
    @indexes = indexes
  end

  def call
    billing_address.merge(
      **used_shipping_address,
      use_billing_address: use_billing_address?
    ).compact
  end

  private

  attr_reader :row, :indexes

  def billing_address
    @billing_address ||=
      {
        address1: N.text(row[indexes.address1]),
        zip: N.zip(row[indexes.zip], N.country_code(row[indexes.country_code])),
        city: N.text(row[indexes.city]),
        country_code: N.country_code(row[indexes.country_code])
      }
  end

  def shipping_address
    @shipping_address ||=
      {
        shipping_last_name: N.text(row[indexes.shipping_last_name]),
        shipping_first_name: N.text(row[indexes.shipping_first_name]),
        shipping_company_name: N.text(row[indexes.shipping_company_name]),
        shipping_address1: N.text(row[indexes.shipping_address1]),
        shipping_zip: N.zip(row[indexes.shipping_zip], N.country_code(row[indexes.shipping_country_code])),
        shipping_city: N.text(row[indexes.shipping_city]),
        shipping_country_code: N.country_code(row[indexes.shipping_country_code]),
        shipping_phone: N.text(row[indexes.shipping_phone])
      }
  end

  def used_shipping_address
    billing_equals_shipping_address? ? {} : shipping_address
  end

  def use_billing_address?
    shipping_address.values.all?(&:blank?) || billing_equals_shipping_address?
  end

  def billing_equals_shipping_address?
    @billing_equals_shipping_address ||=
      COMPARED_ATTRIBUTES.all? do |attribute|
        billing_address[attribute] == shipping_address[:"shipping_#{attribute}"]
      end
  end
end