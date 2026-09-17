require "spec_helper"

RSpec.describe ProductPrice::Import::Cavegest do
  before(:all) { described_class.new(data_path("export_tarifs_cavegest.csv")).call }

  it "doesn't iterate on lines not relevant to the parsing (ex: --- / SOUS-TOTAL)" do
    invalid_refs = Product.where(
      "reference LIKE ? OR reference LIKE ? OR reference LIKE ? OR reference = ?",
      "%---%", "%SOUS-TOTAL%", "%CaveGest%", "TOTAL"
    )

    expect(invalid_refs).to be_empty
  end

  context 'when parsing on the volume' do
    it "converts 'Bouteille - 75.0' to 750" do
      product = Product.find_by(reference: 'COT196')

      expect(product.volume_ml).to eq(750)
    end

    it "converts '½ Bouteille - 37.5' to 375" do
      product = Product.find_by(reference: 'CUV234')

      expect(product.volume_ml).to eq(375)
    end
  end

  it 'remove currency symbols, spaces and name and returns the correct amount' do
    product = Product.find_by(reference: 'COT196')
    product_price = ProductPrice.find_by(product: product, grid_code: 'CHR')

    expect(product_price.amount_ht).to eq(16.99)
  end

  describe 'EXPO grid_code with to without tax conversion' do
    shared_examples 'calculate the correct amount' do
      it 'returns the calculated amount without VAT' do
        product = Product.find_by(reference: reference)
        product_price = ProductPrice.find_by(grid_code: 'EXPO', product: product)

        expect(product_price.amount_ht).to eq(result)
      end
    end

    context 'when the vat_rate is 20%' do
      let(:reference) { 'LANM3' }
      let(:result) { 13.32 }

      include_examples 'calculate the correct amount'
    end

    context 'when the vat_rate is 5%' do
      let(:reference) { 'CUV207' }
      let(:result) { 33.28 }

      include_examples 'calculate the correct amount'
    end
  end

  it 'does not create duplicate for the same reference' do
    duplicated_ref = 'CUV227'

    expect(Product.where(reference: duplicated_ref).size).to eq(1)
  end

  it 'normalize in lowercase the color' do
    products = Product.where(reference: %w[SEL208 VIE205])

    expect(products.pluck(:color)).to match_array(['blanc', 'blanc'])
  end
end
