# This class provides the ability to define a range using numbers or regular expressions
# and when provided with an array, will return a normal ruby Range object based on the matching
# elements in the array. NOTE this class is has the same attributes as Range and is identical
# when serialized (except for the class declaration obviously), but it is NOT a substitute for
# Range (only a facade).
class RegexpRange
  class PatternMatchError < StandardError
  end

  attr_reader :begin, :end, :excl

  def initialize(range_start, range_end, exclusive = false)
    @begin = range_start
    @end = range_end
    @excl = exclusive
  end

  def to_range(lines)
    start_line_number = @begin
    if start_line_number.is_a?(Regexp)
      lines.each_with_index do |line, i|
        if line.match(start_line_number)
          start_line_number = i
          break
        end
      end

      if start_line_number.is_a?(Regexp)
        fail PatternMatchError, "begin pattern #{start_line_number.inspect} not found"
      end
    end

    end_line_number = @end
    if end_line_number.is_a?(Regexp)
      start_scan_line = start_line_number + 1
      lines[start_scan_line..-1].each_with_index do |line, i|
        # puts "##{start_scan_line + i}: #{line}"
        if line.match(end_line_number)
          end_line_number = start_scan_line + i
          break
        end
      end
      if end_line_number.is_a?(Regexp)
        fail PatternMatchError,
             "end pattern #{end_line_number.inspect} not found on or after line #{start_scan_line}"
      end
    end

    Range.new(start_line_number, end_line_number, @excl)
  end
end
