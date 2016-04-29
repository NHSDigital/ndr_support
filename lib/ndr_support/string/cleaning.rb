require 'active_support/core_ext/string/filters'

class String
  INVALID_CONTROL_CHARS = /[\x00-\x08\x0b-\x0c\x0e-\x1f]/
  ROMAN_ONE_TO_FIVE_MAPPING = { 'I' => '1', 'II' => '2', 'III' => '3', 'IIII' => '4', 'IV' => '4', 'V' => '5' }

  # Used for comparing addresses
  def squash
    upcase.delete('^A-Z0-9')
  end

  # Show postcode in various formats.
  # Parameter "option" can be :user, :compact, :db
  def postcodeize(option = :user)
    nspce = gsub(/[[:space:]]/, '').upcase
    unless nspce.blank? || /([A-Z][0-9]|[A-Z][0-9][0-9]|[A-Z][0-9][A-Z]|[A-Z][A-Z][0-9]|[A-Z][A-Z][0-9][0-9]|[A-Z][A-Z][0-9][A-Z])[0-9][A-Z][A-Z]$/ =~ nspce
      return self  # Don't change old-style or malformed postcodes
    end
    case option
    when :compact
      nspce
    when :db
      case nspce.length
      when 5 then nspce.insert(-4, '  ')
      when 6 then nspce.insert(-4, ' ')
      else nspce
      end
    else # anything else, including :user --> friendly format
      nspce.length < 5 ? nspce : nspce.insert(-4, ' ')
    end
  end

  def clean(what)
    case what
    when :nhsnumber
      delete('^0-9')[0..9]
    when :postcode, :get_postcode
      postcodeize(:db)
    when :lpi
      upcase.delete('^0-9A-Z')
    when :sex
      # SECURE: BNS 2012-10-09: But may behave oddly for multi-line input
      if self =~ /^M|1/i
        '1'
      elsif self =~ /^F|2/i
        '2'
      else
        '0'
      end
    when :sex_c
      if self =~ /^M|1/i
        'M'
      elsif self =~ /^F|2/i
        'F'
      else
        ''
      end
    when :name
      substitutions = {
        '.'      => '',
        /,|;/    => ' ',
        /\s{2,}/ => ' ',
        '`'      => '\''
      }
      substitutions.inject(upcase) { |a, e| a.gsub(*e) }.strip
    when :ethniccategory
      replace_ethniccategory = {
        '0' => '0',
        '1' => 'M',
        '2' => 'N',
        '3' => 'H',
        '4' => 'J',
        '5' => 'K',
        '6' => 'R',
        '7' => '8',
        '&' => 'X',
        ' ' => 'X',
        '99' => 'X'
      }
      replace_ethniccategory[self] || upcase
    when :code
      split_on_separators.map do |code|
        code.blank? ? next : code.delete('.')
      end.compact.join(' ')
    when :code_icd
      warn '[DEPRECATION] clean(:code_icd) is deprecated - consider using clean(:icd) instead.'
      # regexp = /[A-Z][0-9]{2}(\.(X|[0-9]{1,2})|[0-9]?)( *(D|A)( |,|;|$))/
      codes = upcase.split_on_separators.delete_if { |x| x.squash.blank? }
      cleaned_codes = []
      codes.each do |code|
        if code == 'D' || code == 'A'
          cleaned_codes[-1] += code
        else
          cleaned_codes << code
        end
      end
      cleaned_codes.join(' ')
    when :icd
      codes = upcase.squish.split_on_separators.reject(&:blank?)
      codes.map { |code| code.gsub(/[.X]/, '') }.join(' ')
    when :code_opcs
      clean_code_opcs
    when :hospitalnumber
      self[-1..-1] =~ /\d/ ? self : self[0..-2]
    when :xmlsafe, :make_xml_safe
      strip_xml_unsafe_characters
    when :roman5
      # This deromanises roman numerals between 1 and 5
      gsub(/[IV]+/i) { |match| ROMAN_ONE_TO_FIVE_MAPPING[match.upcase] }
    when :tnmcategory
      sub!(/\A[tnm]/i, '')
      if self =~ /\Ax\z/i
        upcase
      else
        downcase
      end
    when :upcase
      upcase
    else
      gsub(' ?', ' ')
    end
  end

  def strip_xml_unsafe_characters
    gsub(String::INVALID_CONTROL_CHARS, '')
  end

  def xml_unsafe?
    self =~ String::INVALID_CONTROL_CHARS
  end

  protected

  def split_on_separators(regexp = / |,|;/)
    split(regexp)
  end

  private

  def clean_code_opcs
    split_on_separators.map do |code|
      db_code = code.squash
      next unless 4 == db_code.length || db_code =~ /CZ00[12]/
      db_code
    end.compact.join(' ')
  end
end
