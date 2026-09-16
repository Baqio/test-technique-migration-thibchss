class Customer::Import::Cavegest < Importer::Base
  N = Importer::Normalization

  KINDS = { 
    "C" => "customer", 
    "F" => "supplier", 
    "P" => "prospect", 
    "R" => "reseller"
  }.freeze

  def call
    customers = []

    sheet.parse.each do |row|
      next if row[indexes.reference] == 'TOTAL' || row.all?(&:blank?)
      
      customers << Customer.new(
        reference:         N.text(row[indexes.reference]),
        last_name:         N.text(row[indexes.last_name]),
        first_name:        N.text(row[indexes.first_name]),
        company_name:      company_name(row),
        email:             row[indexes.email].to_s,
        phone:             row[indexes.phone].to_s,
        mobile:            row[indexes.mobile].to_s,
        kind:              KINDS[N.text(row[indexes.kind])],
        customer_category: N.text(row[indexes.customer_category]),
        price_grid_code:   N.text(row[indexes.price_grid_code]),
        vat_number:        N.text(row[indexes.vat_number]),
        excise_number:     N.text(row[indexes.excise_number]),
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
