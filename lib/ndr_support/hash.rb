class Hash
  # Special intersection method allowing us to intersect a hash with
  # an array of keys. Matches string and symbol keys (like stringify_keys)
  #
  # For example
  # {:a => 1, :b => :two, 'c' => '3'} & [:a, :c]
  # => {:a => 1, 'c' => '3'}
  def &(*keys)
    h = {}
    self.each { |k, v| h[k] = v if keys.flatten.map(&:to_s).include?(k.to_s) }
    h
  end

  # This method allows us to walk the path of nested hashes to reference a value
  #
  # For example,
  # my_hash = { 'one' => '1', 'two' => { 'twopointone' => '2.1', 'twopointtwo' => '2.2' } }
  # my_hash['one']                 becomes  my_hash.value_by_path('one')
  # my_hash['two']['twopointone']  becomes  my_hash.value_by_path('two', 'twopointone')
  #
  def value_by_path(first_key, *descendant_keys)
    result = self[first_key]
    descendant_keys.each do |key|
      result = result[key]
    end
    result
  end

  # This method merges this hash with another, but also merges the :rawtext
  # (rather than replacing the current hashes rawtext with the second).
  # Additionally it can raise a RuntimeError to prevent the second hash
  # overwriting the value for a key from the first.
  def rawtext_merge(hash2, prevent_overwrite = true)
    hash1_rawtext = self[:rawtext] || {}
    hash2_rawtext = hash2[:rawtext] || {}

    if prevent_overwrite
      non_unique_rawtext_keys = hash1_rawtext.keys & hash2_rawtext.keys
      unless non_unique_rawtext_keys.empty?
        fail("Non-unique rawtext keys: #{non_unique_rawtext_keys.inspect}")
      end
      non_unique_non_rawtext_keys = (self.keys & hash2.keys) - [:rawtext]
      unless non_unique_non_rawtext_keys.empty?
        fail("Non-unique non-rawtext keys: #{non_unique_non_rawtext_keys.inspect}")
      end
    end

    self.merge(hash2).merge(
      :rawtext => hash1_rawtext.merge(hash2_rawtext)
    )
  end
end
