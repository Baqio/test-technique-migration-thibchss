class Customer::Import::Cavegest < Importer::Base
  N = Importer::Normalization

  KINDS = { 
    "C" => "customer", 
    "F" => "supplier", 
    "P" => "prospect", 
    "R" => "reseller"
  }.freeze

  def call
    sheet.parse.each do |row|
      reference = row[indexes.reference]
      next if reference == 'TOTAL' || row.all?(&:blank?)
      
      customer = Customer.find_or_initialize_by(reference: reference)

      customer.assign_attributes(
        reference: N.text(row[indexes.reference]),
        last_name: N.text(row[indexes.last_name]),
        first_name: N.text(row[indexes.first_name]),
        # TODO: Removed the fallback, put it in the audit as agregated datas, no info if need/necessite fallback
        company_name: N.text(row[indexes.company_name]),
        email: N.text(row[indexes.email]),
        phone: N.phone(row[indexes.phone], N.country_code(row[indexes.country_code])),
        mobile: N.phone(row[indexes.mobile], N.country_code(row[indexes.country_code])),
        kind: KINDS[N.text(row[indexes.kind])],
        customer_category: N.text(row[indexes.customer_category]).upcase,
        price_grid_code: N.text(row[indexes.price_grid_code]),
        vat_number: N.tax_number(row[indexes.vat_number]),
        excise_number: N.tax_number(row[indexes.excise_number]),
        creation_date: N.text(row[indexes.creation_date])&.to_date,
        active: N.text(row[indexes.active]).to_i.zero?,
        **Customer::Import::Cavegest::Address.new(row, indexes).call
      )
    end

    imported = 0
    not_imported = []

    customers.each do |customer|
      if customer.valid?
        customer.save!
        imported += 1
      else
        not_imported << customer
      end
    end

    puts "#{imported} clients importés"
    puts "#{not_imported.size} clients non importés"
  end

  private

  def sheet
    @sheet ||= Roo::Excelx.new(path).sheet(0)
  end

  def indexes
    @indexes ||= Customer::Import::Cavegest::Row.indexes
  end

  def company_name(row)
    if N.text(row[indexes.company_name]).blank?
      "#{N.text(row[indexes.first_name])} #{N.text(row[indexes.last_name])}"
    else
      N.text(row[indexes.company_name])
    end
  end
end
