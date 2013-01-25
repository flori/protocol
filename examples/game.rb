require 'protocol'

# Small example of the template method pattern with Protocol. (I think, it was
# inspired by this wikipedia article:
# http://en.wikipedia.org/wiki/Template_method_pattern
Gaming = Protocol do
  # defaults to specification mode

  # Initialize the game before entering the game loop.
  def initialize_game()
  end

  implementation # switch to implemetation mode

  attr_accessor :player_count

  attr_accessor :current_player

  specification # switch back to specification mode

  # Make the next move with player +player+.
  def make_move(player)
    player.is_a? Fixnum and player >= 0 or
      raise TypeError, "player #{player.class} is not a Fixnum >= 0"
  end

  # Return true if the game is over.
  def game_over?()
  end

  # Output the winner of the game after +game_over?+ returned true.
  def output_winner()
  end

  implementation # switch to implemetation mode again

  # Play the game with +player_count+ players.
  def play(player_count)
    self.player_count = player_count
    self.current_player = 0
    initialize_game
    loop do
      make_move current_player
      game_over? and break
      self.current_player = (current_player + 1) % player_count
    end
    output_winner
  end
end

class GuessGame
  def initialize_game
    @winner = nil
    @move = 0
    @secret_number = 1 + rand(10)
  end

  def make_move(player)
    @move += 1
    @guess = 1 + rand(10)
    puts "#@move. Player ##{player}'s move: number = #{@guess}?"
  end

  def game_over?
    if @guess == @secret_number
      @winner = current_player
      true
    else
      false
    end
  end

  def output_winner
    puts "The winner is player ##@winner, the secret number was #@secret_number!"
  end

  conform_to Gaming
end
game = GuessGame.new
game.play 2
game.play 3
