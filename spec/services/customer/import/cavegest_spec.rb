require "spec_helper"

RSpec.describe Customer::Import::Cavegest do
  before(:all) { described_class.new(data_path("export_clients_cavegest.xlsx")).call }

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
end
