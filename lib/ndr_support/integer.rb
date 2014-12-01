class Integer
  # Rounds up to _p_ digits. For graphs. Josh Pencheon 22/08/2007
  def round_up_to(p)
    return nil if p > self.to_s.length || p < 0
    p = p.to_i
    s = self.to_s.split('')
    d = s[0..(p - 1)]
    d[p - 1] = s[p - 1].to_i + 1
    s[p..-1].each_with_index { |_v, i| d[i + p] = '0' }
    d.join.to_i
  end
end
