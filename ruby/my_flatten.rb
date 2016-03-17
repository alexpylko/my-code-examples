class Array
  def my_flatten
    (proc = -> (a, ini=[]) { a.inject(ini) { |memo, val|
      val.is_a?(Array) ? proc.call(val, memo) : memo << val
    } } ).call(self)
  end
end

require "minitest/autorun"

class Tests < MiniTest::Unit::TestCase

  def test_my_flatten
    assert_equal [1, 2, 3, 4], [[1,2,[3]],4].my_flatten
  end

  def test_my_flatten2
    assert_equal [1, 2, 3, 4, 5, 6, 7, 8, 9], [[1,2,[3]],4, [5, [6, [7, [8, 9]]]]].my_flatten
  end

end