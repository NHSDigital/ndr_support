# Adds the 'clean' method to String, which can be used to clean strings in various ways
# depending on the contents
module CleanMethodable
  extend ActiveSupport::Concern

  ROMAN_ONE_TO_FIVE_MAPPING = { 'I' => '1', 'II' => '2', 'III' => '3', 'IIII' => '4', 'IV' => '4', 'V' => '5' }.freeze

  CLEAN_METHODS = {
    nhsnumber: :clean_nhsnumber,
    postcode: :clean_postcode, get_postcode: :clean_postcode,
    lpi: :clean_lpi,
    gender: :clean_gender, sex: :clean_sex, sex_c: :clean_sex_c,
    name: :clean_name,
    ethniccategory: :clean_ethniccategory,
    code: :clean_code, code_icd: :clean_code_icd, icd: :clean_icd,
    code_opcs: :clean_code_opcs,
    hospitalnumber: :clean_hospitalnumber,
    xmlsafe: :clean_xmlsafe, make_xml_safe: :clean_xmlsafe,
    roman5: :clean_roman5,
    tnmcategory: :clean_tnmcategory,
    strip: :strip, upcase: :upcase, itself: :itself,
    log10: :clean_log10
  }.freeze

  def clean(what)
    cleaning_method = CLEAN_METHODS[what]
    return send(cleaning_method) if cleaning_method

    gsub(' ?', ' ')
  end

  private

  def clean_nhsnumber
    delete('^0-9')[0..9]
  end

  def clean_postcode
    postcodeize(:db)
  end

  def clean_lpi
    upcase.delete('^0-9A-Z')
  end

  def clean_gender
    return '1' if self =~ /\AM(ale)?/i
    return '2' if self =~ /\AF(emale)?/i

    self
  end

  def clean_sex
    # SECURE: BNS 2012-10-09: But may behave oddly for multi-line input
    return '1' if self =~ /^M|1/i
    return '2' if self =~ /^F|2/i

    '0'
  end

  def clean_sex_c
    return 'M' if self =~ /^M|1/i
    return 'F' if self =~ /^F|2/i

    ''
  end

  def clean_name
    substitutions = {
      '.'      => '',
      /,|;/    => ' ',
      /\s{2,}/ => ' ',
      '`'      => '\''
    }
    substitutions.inject(upcase) { |a, e| a.gsub(*e) }.strip
  end

  def clean_ethniccategory
    replace_ethniccategory = {
      '0' => '0', '1' => 'M', '2' => 'N',
      '3' => 'H', '4' => 'J', '5' => 'K',
      '6' => 'R', '7' => '8', '&' => 'X',
      ' ' => 'X', '99' => 'X'
    }
    replace_ethniccategory[self] || upcase
  end

  def clean_code
    split_on_separators.map do |code|
      code.blank? ? next : code.delete('.')
    end.compact.join(' ')
  end

  def clean_code_icd
    warn '[DEPRECATION] clean(:code_icd) is deprecated - consider using clean(:icd) instead.'
    # regexp = /[A-Z][0-9]{2}(\.(X|[0-9]{1,2})|[0-9]?)( *(D|A)( |,|;|$))/
    codes = upcase.split_on_separators.delete_if { |x| x.squash.blank? }
    cleaned_codes = []
    codes.each do |code|
      if %w[A D].include?(code)
        cleaned_codes[-1] += code
      else
        cleaned_codes << code
      end
    end
    cleaned_codes.join(' ')
  end

  def clean_icd
    codes = upcase.squish.split_on_separators.reject(&:blank?)
    codes.map { |code| code.gsub(/(?<=\d)(\.?X?)/, '') }.join(' ')
  end

  def clean_hospitalnumber
    self[-1..] =~ /\d/ ? self : self[0..-2]
  end

  def clean_xmlsafe
    strip_xml_unsafe_characters
  end

  def clean_roman5
    # This deromanises roman numerals between 1 and 5
    gsub(/[IV]+/i) { |match| ROMAN_ONE_TO_FIVE_MAPPING[match.upcase] }
  end

  def clean_tnmcategory
    sub!(/\A[tnm]/i, '')
    if self =~ /\Ax\z/i
      upcase
    else
      downcase
    end
  end

  def clean_code_opcs
    split_on_separators.map do |code|
      db_code = code.squash
      next unless 4 == db_code.length || db_code =~ /CZ00[12]/

      db_code
    end.compact.join(' ')
  end

  def clean_log10
    f_value = Float(self, exception: false)
    return self if f_value.nil? || f_value.negative?

    f_value.zero? ? '0.0' : Math.log10(f_value).to_s
  end
end
