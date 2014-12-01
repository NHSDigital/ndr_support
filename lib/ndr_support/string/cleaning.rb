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
    nspce = delete(' ').upcase
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
      self.delete('^0-9')[0..9]
    when :postcode, :get_postcode
      self.postcodeize(:db)
    when :lpi
      self.upcase.delete('^0-9A-Z')
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
      substitutions.inject(self.upcase) { |str, scheme| str.gsub(*scheme) }.strip
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
      replace_ethniccategory[self] || self.upcase
    when :code
      self.split(/ |,|;/).map do |code|
        code.blank? ? next : code.gsub('.', '')
      end.compact.join(' ')
    when :code_icd
      # regexp = /[A-Z][0-9]{2}(\.(X|[0-9]{1,2})|[0-9]?)( *(D|A)( |,|;|$))/
      codes = self.upcase.split(/ |,|;/).delete_if { |x| x.squash.blank? }
      cleaned_codes = []
      codes.each do |code|
        if code == 'D' || code == 'A'
          cleaned_codes[-1] += code
        else
          cleaned_codes << code
        end
      end
      cleaned_codes.join(' ')
    when :code_opcs
      self.split(/ |,|;/).map do |code|
        db_code = code.squash
        db_code.length < 3 || db_code.length > 4 ? next : db_code
      end.compact.join(' ')
    when :hospitalnumber
      self[-1..-1] =~ /\d/ ? self : self[0..-2]
    when :xmlsafe, :make_xml_safe
      self.strip_xml_unsafe_characters
    when :roman5
      # This deromanises roman numerals between 1 and 5
      self.gsub(/[IV]+/i) { |match| ROMAN_ONE_TO_FIVE_MAPPING[match.upcase] }
    when :tnmcategory
      self.sub!(/\A[tnm]/i, '')
      if self =~ /\Ax\z/i
        self.upcase
      else
        self.downcase
      end
    else
      self.gsub(' ?', ' ')
    end
  end

  def strip_xml_unsafe_characters
    self.gsub(String::INVALID_CONTROL_CHARS, '')
  end

  def xml_unsafe?
    self =~ String::INVALID_CONTROL_CHARS
  end
end
