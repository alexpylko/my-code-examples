class GameBoard
  include Comparable
  include Enumerable

  SQUARE_SIZE = 3
  MATRIX_SIZE = SQUARE_SIZE ** 2

  def initialize(*args)
    @items = Array.new(args)
  end

  def zero_indexes
    @items.each_with_index.map{ |el, i| (0 == el) ? i : nil }.compact
  end

  def [](i)
    @items[i]
  end

  def each
    @items.each{ |i| yield( i ) }
  end

  def []=(i, value)
    @items[i] = value
  end

  def to_a
    @items
  end

  def size
    @items.size
  end

  def <=>(other)
    @items <=> other.to_a
  end

  def inspect
    @items.inspect
  end

  def to_s
    @items.to_s
  end

end