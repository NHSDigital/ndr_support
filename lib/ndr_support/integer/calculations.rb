class Integer
  # Gets binomial coefficients:
  #
  #   4.choose(2) #=> 6
  #
  def choose(k)
    fail(ArgumentError, "cannot choose #{k} from #{self}") unless (0..self) === k
    self.factorial / (k.factorial * (self - k).factorial)
  end

  def factorial
    fail("cannot calculate #{self}.factorial") unless self >= 0 # limited implementation
    self.zero? ? 1 : (1..self).inject { |product, i| product * i }
  end
end
