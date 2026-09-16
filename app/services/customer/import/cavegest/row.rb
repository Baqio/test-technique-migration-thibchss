class Customer::Import::Cavegest::Row
  RowIndex = Struct.new(
    :reference,
    :last_name,
    :first_name,
    :company_name,
    :address1, 
    :zip, 
    :city, 
    :country_code, 
    :email, 
    :phone, 
    :mobile,
    :shipping_last_name,
    :shipping_first_name,
    :shipping_company_name,
    :shipping_address1,
    :shipping_zip,
    :shipping_city,
    :shipping_country_code,
    :shipping_phone,
    :kind, 
    :customer_category, 
    :price_grid_code,
    :price_grid_label,
    :vat_number, 
    :excise_number,
    :creation_date,
    :active
  ).freeze

  def self.indexes
    @indexes ||= RowIndex.new(*(0..26).to_a)
  end 
end