class Customer::Import::Cavegest < Importer::Base
  N = Importer::Normalization

  KINDS = { "C" => "customer", "F" => "supplier", "P" => "prospect", "R" => "reseller"}.freeze

  def call
    customers = []

    sheet.parse.each do |row|
      next if row[0] == 'TOTAL' || row.all?(&:blank?)
      
      customers << Customer.new(
        reference:         N.text(row[0]),
        first_name:        N.text(row[1]),
        last_name:         N.text(row[2]),
        company_name:      N.text(row[3]).blank? ? N.text(row[2]) : N.text(row[3]),
        address1:          N.text(row[4]),
        zip:               N.zip(row[5], N.country_code(row[7])),
        city:              N.text(row[6]),
        country_code:      N.country_code(row[7]),
        email:             row[8].to_s,
        phone:             row[9].to_s,
        mobile:            row[10].to_s,
        kind:              KINDS[N.text(row[19])],
        customer_category: N.text(row[20]),
        price_grid_code:   N.text(row[21]),
        vat_number:        N.text(row[23]),
        excise_number:     N.text(row[24])
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
end
