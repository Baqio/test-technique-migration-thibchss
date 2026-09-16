require "spec_helper"

RSpec.describe Customer::Import::Cavegest do
  before { described_class.new(data_path("export_clients_cavegest.xlsx")).call }

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
end
