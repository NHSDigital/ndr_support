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
	def postcodeize(option = :user)
    nil
  end
  def upcase
  	nil
  end
  def clean(what)
    nil
  end
  def squash
    nil
  end
  def gsub(*a)
  	''
  end
  def strip
  	nil
  end
end
