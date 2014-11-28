class Fixnum
    # Gets binomial coefficients:
    #
    #   4.choose(2) #=> 6
    #
    def choose(k)
      raise(ArgumentError, "cannot choose #{k} from #{self}") unless (0..self) === k
      self.factorial / ( k.factorial * (self - k).factorial )
    end
    
    def factorial
      raise(RuntimeError, "cannot calculate #{self}.factorial") unless self >= 0 # limited implementation
      self.zero? ? 1 : (1..self).inject { |product, i| product*i }
    end
end