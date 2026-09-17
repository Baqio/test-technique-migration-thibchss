class Customer < ActiveRecord::Base
  KINDS = %w[customer supplier prospect reseller].freeze

  validates :reference, presence: true, uniqueness: true
  validates :kind, inclusion: { in: KINDS }
  validate  :name_present

  def name_present?
    company_name.present? || first_name.present? || last_name.present?
  end

  private

  def name_present
    return if name_present?

    errors.add(:base, "ni raison sociale, ni nom, ni prénom")
  end
end
