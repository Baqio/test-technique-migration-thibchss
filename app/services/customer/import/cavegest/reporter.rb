class Customer::Import::Cavegest::Reporter < Reporter::Base
  def call
    check_for_errors
    check_for_warning
  end

  def errors?
    @errors
  end

  def creation_error
    record.valid?
    
    error(message: "Erreur(s) lors de la création du client : #{record.errors.full_messages}")
  end

  private

  def check_for_errors
    unless record.name_present?
      error(message: 'Raison sociale, nom et prénom manquants')
      @errors ||= true
    end

    if record.reference.blank?
      error(message: 'Référence manquante')
      @errors ||= true
    end

    if Customer::KINDS.exclude?(record.kind)
      error(message: 'Code famille client inconnu')
      @errors ||= true
    end

    if @datas[:references].include?(record.reference)
      error(message: 'La référence est déjà existante')
      @errors ||= true
    end
  end

  def check_for_warning
    if record.country_code.blank? || (!record.use_billing_address && record.shipping_country_code.blank?)
      warning(message: "Pays pour l'adresse de facturation ou d'expédition manquant ou non reconnu")
    end
    
    if record.use_billing_address && uncontactable?
      warning(message: "Aucune information de contact")
    elsif uncontactable?(billing: false)
      warning(message: "Aucune information de contact pour la facturation ou l'expédition")
    end

    unless record.active
      warning(message: "Client est marqué comme inutilisable/inactif")
    end
  end

  def uncontactable?(billing: true)
    if billing
      record.email.blank? && record.phone.blank? && record.mobile.blank?
    else
      uncontactable? && record.shipping_phone.blank?
    end
  end

  def locator
    @locator ||=
      record.reference.presence || record.company_name.presence || 
        "#{record.first_name} #{record.last_name}".presence || 'Aucune information pour identifier le client'
  end
end