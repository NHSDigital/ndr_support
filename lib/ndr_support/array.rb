class Array
  # A utility method to return those elements in an array where the item in a
  # corresponding array in true (matching by index)
  def values_matching(a)
    return [] unless a.respond_to?(:[])
    result = []
    each_with_index {|x, i| result << x if a[i]}
    result
  end
  
  # Returns the smallest, i.e. least, non-nil element (can be used for any 
  # type of object that supports the <=> operator, including dates)
  def smallest
    #self.compact.sort.first
    self.compact.min
  end
  
  # Returns the biggest, i.e. greatest, non-nil element
  def biggest
    #self.compact.sort.last
    self.compact.max
  end
  
  # Flattens range objects within an array to allow include? to work within
  # the array and within the ranges within the array.
  def ranges_include?(value)
    any? { |range| Array(range).include?(value) }
  end
  
  # Finds all the permutations of the array:
  #
  #   [1,2,3].permutations #=> [1,2,3], [1,3,2], [2,1,3], [2,3,1], [3,1,2], [3,2,1]
  #   [3,3].permutations   #=> [3,3], [3,3]
  #
  def permutations
    return [self] if length == 1

    orders = []
    positions = (0...length).to_a

    # Finding the permutations with a basic array of digits
    positions.each do |position|
      (positions - [position]).permutations.each do |permutation|
        orders << permutation.unshift(position)
      end
    end

    # We subsitute in our original elements. This prevents duplicate
    # elements from causing problems, and allows the [3,3] example to work.
    orders.map { |order| order.map { |index| self[index] } }
  end

end
