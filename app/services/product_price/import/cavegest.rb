class ProductPrice::Import::Cavegest < Importer::Base
  N = Importer::Normalization

  COLUMN_SEP = ";".freeze
  GRID_CODES = %w[DEPC CHR EXPO PART SALON].freeze

  def call
    products = []

    CSV.parse(clean_csv, headers: true, col_sep: COLUMN_SEP).each do |row|
      reference = N.text(row["Ref"])
      next if should_skip?(reference)

      product = Product.new(
        reference: reference,
        name: N.text(row["Désignation"]),
        color: N.text(row["Couleur"])&.downcase,
        volume_ml: N.volume_ml(row["Contenant"]),
        vat_rate: N.decimal(row["TVA"]),
        stock: N.decimal(row["Stock"]).to_i
      )

      products << product

      build_product_prices(product, row)
    end

    imported = 0
    not_imported = []

    products.each do |product|
      if product.valid?
        product.save!
        save_product_prices!(product)

      imported += 1
      else
        not_imported << product
      end
    end

    puts "#{imported} produits importés"
    puts "#{not_imported.size} produits non importés"
  end

  private

  def build_product_prices(product, row)
    product_prices[product.reference] = 
      GRID_CODES.map do |grid_code|
      amount = N.decimal(row[grid_code])

      # La grille EXPO est saisie en TTC dans CaveGest, on stocke du HT.
        amount /= (1 + (product.vat_rate / 100)) if grid_code == "EXPO"

        # TODO: Add warning for this
        next if amount.zero?

        ProductPrice.new(
        grid_code: grid_code,
        amount_ht: amount.round(2)
      )
      end.compact
  end

  def raw_file_content
    File.read(path, encoding: 'iso-8859-1:utf-8')
  end

  def clean_csv
    lines = raw_file_content.lines
    headers_index = lines.index { |line| line.match?(/\ARef\b/)}

    lines[headers_index..].join
  end

  def should_skip?(reference)
    reference.nil? ||
      reference.start_with?('---') ||
        reference.include?('TOTAL')
  end

  def product_prices
    @product_prices ||= {}
  end

  def save_product_prices!(product)
    product_prices[product.reference].each do |product_price|
      product_price.product = product
      product_price.save!
    end
  end
end
