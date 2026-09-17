require "spec_helper"

RSpec.describe Customer::Import::Cavegest do
  before(:all) do
    @report = MigrationReport.new
    described_class.new(data_path("export_clients_cavegest.xlsx"), report: @report).call
  end

  let(:report) { @report }

  it "keeps the leading zero of postal codes" do
    expect(Customer.find_by(reference: "T00022").zip).to eq("01000")
  end

  it "skips the totals row at the bottom of the file" do
    expect(Customer.where(reference: "TOTAL")).to be_empty
  end

  it "stores the shipping address when it differs from the billing one" do
    customer = Customer.find_by(reference: "T00013")

    expect(customer.zip).to eq("04000")
    expect(customer.shipping_zip).to eq("11100")
  end

  it "doesn't store the shipping address when it's the same as the billing one" do
    customer = Customer.find_by(reference: "T00004")

    expect(customer.use_billing_address).to eq(true)
    expect(customer.shipping_address1).to be_nil
    expect(customer.shipping_zip).to be_nil
  end

  it "stores the proper country_code when there is a country written" do
    customer = Customer.find_by(reference: "T02756")

    expect(customer.country_code).to eq('DE')
  end

  it "stores the phone number with its country_code" do
    deutsch_customer = Customer.find_by(reference: "T02756")
    belgian_customer = Customer.find_by(reference: "T01205")
    french_customer = Customer.find_by(reference: "T00141")

    expect(deutsch_customer.phone).to eq("+49556174676")
    expect(belgian_customer.phone).to eq("+32272111757")
    expect(french_customer.phone).to eq("+33466824417")
  end

  shared_examples 'report error' do
    it 'records an error in the report' do
      error = report.errors.find { |e| e.locator == reference }

      expect(error).not_to be_nil
      expect(error.message).to eq(message)
    end
  end

  context 'when there is no first_name, last_name or company_name' do
    let(:reference) { 'T00078' }
    let(:message) { 'Raison sociale, nom et prénom manquants' }

    it 'does not persist the customer' do
      customer = Customer.find_by(reference: reference)
  
      expect(customer).to be_nil
    end

    include_examples 'report error'
  end

  context 'when there is a duplicated reference' do
    let(:reference) { 'T00101' }
    let(:message) { 'La référence est déjà existante' }

    it 'does not persist the customer' do
      customer = Customer.where(reference: reference)
  
      expect(customer.size).to eq(1)
    end

    include_examples 'report error'
  end

  it 'tracks the created and not created customers' do
    expect(report.counters).to include(
      {
        customer_created: 4991,
        customer_not_created: 6
      }
    )
  end

  it 'collects the proper warnings' do
    warnings_tallied = report.warnings.map(&:message).tally

    expect(warnings_tallied).to include(
      {
        "Pays pour l'adresse de facturation ou d'expédition manquant ou non reconnu" => 990,
        'Client est marqué comme inutilisable/inactif' => 340,
        'Aucune information de contact' => 17,
        "Aucune information de contact pour la facturation ou l'expédition"=>2
      }
    )
  end
end
