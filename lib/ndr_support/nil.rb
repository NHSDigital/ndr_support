# Extend Nilclass to avoid nil.xxx errors when empty data returned from database
class NilClass
  def to_date
    nil
  end

  def titleize
    nil
  end

  def surnameize
    nil
  end

  def postcodeize(*)
    nil
  end

  def upcase
    nil
  end

  def clean(*)
    nil
  end

  def squash
    nil
  end

  def gsub(*)
    ''
  end

  def strip
    nil
  end
end
