class Customer::Import::Cavegest::Address
  N = Importer::Normalization
  COMPARED_ATTRIBUTES = %i[address1 zip city].freeze

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
        zip: N.zip(row[indexes.zip], country_code),
        city: N.text(row[indexes.city]),
        country_code: country_code
      }
  end

  def shipping_address
    @shipping_address ||=
      {
        shipping_last_name: N.text(row[indexes.shipping_last_name]),
        shipping_first_name: N.text(row[indexes.shipping_first_name]),
        shipping_company_name: N.text(row[indexes.shipping_company_name]),
        shipping_address1: N.text(row[indexes.shipping_address1]),
        shipping_zip: N.zip(row[indexes.shipping_zip], country_code(billing: false)),
        shipping_city: N.text(row[indexes.shipping_city]),
        shipping_country_code: country_code(billing: false),
        shipping_phone: N.phone(row[indexes.shipping_phone], country_code(billing: false))
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

  def country_code(billing: true)
    if billing
      @country_code_billing ||= N.country_code(row[indexes.country_code])
    else
      @country_code_shipping ||= N.country_code(row[indexes.shipping_country_code])
    end
  end
end