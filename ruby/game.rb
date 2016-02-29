class Game

  def load_board(*args)
    @board = GameBoard.new(*args)
  end

  def solve
    zeros = @board.zero_indexes
    i = 0
    while (i > -1) && (i < zeros.length)
      cell = zeros[i]
      @board[cell] = cell_value(cell)
      if 0 == @board[cell]
        i -= 1
      else
        i += 1
      end
    end
    @board
  end

  private

  def cell_value(cell)
    values = existing_values(cell)
    value = 0
    ((@board[cell]+1)..GameBoard::MATRIX_SIZE).each do |val|
      unless values.include?(val)
        value = val
        break
      end
    end
    value
  end

  def existing_values(cell)
    col = cell % GameBoard::MATRIX_SIZE
    row = cell / GameBoard::MATRIX_SIZE
    cell_indexes(col, row).map{ |m| @board[m] }.uniq
  end

  def cell_indexes(col, row)
    col_indexes(col) | row_indexes(row) | square_indexes(col, row)
  end

  def col_indexes(col)
    GameBoard::MATRIX_SIZE.times.map { |i| col + (GameBoard::MATRIX_SIZE * i) }
  end

  def row_indexes(row)
    GameBoard::MATRIX_SIZE.times.map { |i| (row * GameBoard::MATRIX_SIZE) + i }
  end

  def square_indexes(col, row)
    rr = (row/GameBoard::SQUARE_SIZE) * GameBoard::SQUARE_SIZE
    cr = (col/GameBoard::SQUARE_SIZE) * GameBoard::SQUARE_SIZE
    first = cr + (rr * GameBoard::MATRIX_SIZE)
    line1 = GameBoard::SQUARE_SIZE.times.map{ |i| first + i }
    line2 = line1.map{ |m| m + GameBoard::MATRIX_SIZE }
    line3 = line2.map{ |m| m + GameBoard::MATRIX_SIZE }
    line1+ line2+ line3
  end

end