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

      validate_for_import!(customer)
    end

    generate_customers!
  end

  private

  def sheet
    @sheet ||= Roo::Excelx.new(path).sheet(0)
  end

  def indexes
    @indexes ||= Customer::Import::Cavegest::Row.indexes
  end

  def customers
    @customers ||= []
  end

  def valid_references
    @valid_references ||= Set.new
  end

  def generate_customers!
    customers.each do |customer|
      if customer.new_record?
        report.count(:customer_created)
      elsif customer.has_changes_to_save? && customer.persisted?
        report.count(:customer_updated) 
      else
        report.count(:customer_unchanged)
      end

      customer.save!
    end
  end

  def validate_for_import!(customer)
    validator = Customer::Import::Cavegest::Reporter.new(customer, report, 'Client', references: valid_references)
    validator.call

    unless validator.errors?
      if customer.valid?
        customers << customer
        valid_references << customer.reference
      else
        validator.creation_error
        report.count(:customer_not_created)
      end
    else
      report.count(:customer_not_created)
    end
  end
end