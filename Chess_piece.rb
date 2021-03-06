# Assumptions
# => White is on the bottom of the board (high indexes)
# => White moves first
#
# require 'debugger'
class Piece
  attr_accessor :board, :pos, :color
  BOARD_RANGE = (0..7).to_a
  CARDINAL_DELTA = [[0,1], [1,0], [-1,0], [0,-1]]
  DIAG_DELTA = [[1,1], [-1,-1], [1,-1], [-1,1]]
  COMP_DELTA = CARDINAL_DELTA + DIAG_DELTA

  def initialize(board = nil, pos, color)# color = :b/:w
    @board, @pos, @color = board, pos, color
    board[pos] = self
  end


  private
  def on_board?(move)
    move.all? { |coord| BOARD_RANGE.include?(coord) }
  end



end

class SlidingPiece < Piece
  private
  def possible_slides(deltas) #NEED to refactor
    moves = []
    deltas.each do |delta|
      potential_move = pos.add_delta(delta)
      next unless on_board?(potential_move)
      target = board[potential_move]

      while on_board?(potential_move) && (target.nil? || target.color != self.color)
        moves << potential_move.dup
        break if (target != nil && target.color != self.color)
        potential_move.add_delta!(delta)
        target = board[potential_move] if on_board?(potential_move)
      end
    end
    moves
  end

end

class Castle < SlidingPiece
  def possible_moves
    possible_slides(CARDINAL_DELTA)
  end
end

class Bishop < SlidingPiece
  def possible_moves
    possible_slides(DIAG_DELTA)
  end
end

class Queen < SlidingPiece
  def possible_moves
    possible_slides(COMP_DELTA)
  end
end

class Pawn < Piece
  attr_accessor :moved
  KILLDELTA = [[0,-1],[0,1]]

  def initialize(board, pos, color)
    super(board, pos, color)
    @moved = false # move to main class if castling
  end

  def possible_moves
    regular_move + double_move + kill_move
  end

  private
  def regular_move
    color == :w ? [[(pos[0] - 1),(pos[1])]] : [[(pos[0] + 1),(pos[1])]]
  end

  def double_move #prevent if blocked
    return [] if moved
    moved = true
    color == :w ? [[(pos[0] - 2),(pos[1])]] : [[(pos[0] + 2),(pos[1])]]
  end

  def kill_move #need to specify that a enemy is in kill pos
    # if color == :w
    #   [[(pos[0]-1),(pos[1]+1)],[(pos[0]-1),(pos[1]-1)]].keep_if do |target|
    #     (board[target].class != nil) && (board[target].color == :b)
    #   end #white pawn
    # else
    #   [[(pos[0]+1),(pos[1]+1)],[(pos[0]+1),(pos[1]-1)]].keep_if do |target|
    #     (board[target].class != nil) && (board[target].color == :w)
    #   end #black pawn
    # end
    []
  end

  def kill_move
    kill_targets = color == :w ? [[-1,1],[-1,-1]] : [[1,1],[1,-1]]
    kill_targets.map!.with_index {|target| target.add_delta(pos)}
    kill_targets.keep_if do |square|
      (board[square] != nil) && (board[square].color != color)
    end

  end

end

class SteppingPiece < Piece
  private
  def in_range_moves(deltas) #possibly move to main class if needed
    deltas.map { |x, y| [self.pos[0]+x, self.pos[1]+y] }.keep_if do |move|
      on_board?(move)
    end
  end

end

class Knight < SteppingPiece
  KNIGHT_DELTA = [1,2,-1,-2].permutation(2).to_a.keep_if {|x,y| x != -y }

  def possible_moves
    in_range_moves(KNIGHT_DELTA)#narrow to moves that are legal
  end

end

class King < SteppingPiece
  def possible_moves
    in_range_moves(COMP_DELTA)
  end

end

class Array

  def add_delta(delta, &prc)
    self.dup.add_delta!(delta, &prc)
  end

  def add_delta!(delta, &prc)
    prc = Proc.new{ |x,y| x + y } unless prc
    self.each_with_index { |item,index| self[index] = prc.call(item,delta[index]) }
  end
end


