class ProductPrice::Import::Cavegest < Importer::Base
  N = Importer::Normalization

  COLUMN_SEP = ";".freeze
  GRID_CODES = %w[DEPC CHR EXPO PART SALON].freeze

  def call
    imported = 0

    CSV.parse(clean_csv, headers: true, col_sep: COLUMN_SEP).each do |row|
      reference = N.text(row["Ref"])
      next if should_skip?(reference)

      product = Product.create!(
        reference: reference,
        name:      N.text(row["Désignation"]),
        color:     N.text(row["Couleur"]),
        volume_ml: volume_ml(row["Contenant"]),
        vat_rate:  N.decimal(row["TVA"]),
        stock:     N.decimal(row["Stock"]).to_i
      )

      import_prices(product, row)
      imported += 1
    end

    puts "#{imported} produits importés"
  end

  private

  def import_prices(product, row)
    GRID_CODES.each do |grid_code|
      amount = N.decimal(row[grid_code])

      # La grille EXPO est saisie en TTC dans CaveGest, on stocke du HT.
      amount /= 1.2 if grid_code == "EXPO"

      ProductPrice.create!(
        product:   product,
        grid_code: grid_code,
        amount_ht: amount.round(2)
      )
    end
  end

  def volume_ml(value)
    value.to_s[/\d+/].to_i * 10
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
end
