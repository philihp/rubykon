require_relative 'spec_helper'

module Rubykon
  RSpec.describe Rubykon::Game do
    let(:game) {described_class.new}

    context 'creation' do
      subject {game}
      it {is_expected.not_to be_nil}

      it 'has a default size of 19' do
        expect(game.board.size).to eq(19)
      end

      it 'has a move_count of 0' do
        expect(game.move_count).to eq 0
      end

      it 'has no moves playd' do
        expect(game).to be_no_moves_played
      end

      it 'can be created with another size' do
        size = 13
        expect(Rubykon::Game.new(size).board.size).to eq size
      end

      it 'can retrieve the board' do
        expect(game.board).not_to be_nil
      end
    end

    describe "next_turn_color" do
      it "is black for starters" do
        expect(game.next_turn_color).to eq Board::BLACK
      end

      it "is white after a black move" do
        game.play! *StoneFactory.build(color: Board::BLACK)
        expect(game.next_turn_color).to eq Board::WHITE
      end

      it "is black again after a white move" do
        game.play! *StoneFactory.build(color: Board::BLACK)
        game.play! *StoneFactory.build(x: 4, y: 5, color: Board::WHITE)
        expect(game.next_turn_color).to eq Board::BLACK
      end
    end

    describe "#finished?" do
      it "an empty game is not over" do
        expect(game).not_to be_finished
      end

      it "a game with one pass is not over" do
        game.play! *StoneFactory.pass(:black)
        expect(game).not_to be_finished
      end

      it "a game with two passes is over" do
        game.play! *StoneFactory.pass(:black)
        game.play! *StoneFactory.pass(:white)
        expect(game).to be_finished
      end
    end

    describe ".from" do
      let(:string) do
        <<-GAME
X---O
--X--
X----
-----
-X--O
        GAME
      end

      let(:new_game)  {Game.from string}
      let(:board)     {new_game.board}
      let(:group_overseer) {new_game.group_overseer}

      it "sets the right number of moves" do
        expect(new_game.move_count).to eq 6
      end

      it "also populates moves" do
        expect(new_game.moves).not_to be_empty
      end

      it "assigns the stones a group" do
        expect(group_from(1, 1)).not_to be_nil
      end

      it "does not assign a group to the empty fields" do
        expect(group_from(2, 2)).to be_nil
      end

      it "has stones in all the right places" do
        expect(board_at(1, 1)).to eq :black
        expect(board_at(5, 1)).to eq :white
        expect(board_at(3, 2)).to eq :black
        expect(board_at(1, 3)).to eq :black
        expect(board_at(2, 5)).to eq :black
        expect(board_at(5, 5)).to eq :white
        expect(board_at(2, 2)).to eq Board::EMPTY
        expect(board_at(1, 4)).to eq Board::EMPTY
      end
    end

    describe 'playing moves' do

      let(:game) {Game.from board_string}
      let(:board) {game.board}
      let(:group_overseer) {game.group_overseer}

      describe 'play!' do
        let(:game) {Game.new 5}

        it "plays moves" do
          game.play!(2, 2, :black)
          expect(board_at(2, 2)).to eq :black
        end

        it "raises if the move is invalid" do
          expect do
            game.play!(0, 0, :black)
          end.to raise_error(IllegalMoveException)
        end
      end

      describe 'capturing stones' do
        let(:captures) {group_overseer.prisoners}
        let(:identifier) {board.identifier_for(capturer[0], capturer[1])}
        let(:color) {capturer.last}


        before :each do
          game.set_valid_move identifier, color
        end

        describe 'simple star capture' do
          let(:board_string) do
            <<-BOARD
---
XOX
-X-
            BOARD
          end
          let(:capturer) {[2, 1, :black]}

          it "removes the captured stone from the board" do
            expect(board_at(1,1)).to eq Board::EMPTY
          end

          it "the stone made one capture" do
            expect(group_overseer.prisoners[:black]).to eq 1
          end

          it_behaves_like "has liberties at position", 2, 1, 3
          it_behaves_like "has liberties at position", 1, 2, 3
          it_behaves_like "has liberties at position", 2, 3, 3
          it_behaves_like "has liberties at position", 3, 2, 3
        end

        describe 'turtle capture' do
          let(:board_string) do
            <<-BOARD
-----
-OO--
OXX--
-OOO-
-----
            BOARD
          end
          let(:capturer) {[4, 3, :white]}

          it "removes the two stones from the board" do
            expect(board_at(2, 3)).to eq Board::EMPTY
            expect(board_at(3, 3)).to eq Board::EMPTY
          end

          it "has 2 captures" do
            expect(captures[:white]).to eq 2
          end

          it_behaves_like "has liberties at position", 1, 3, 3
          it_behaves_like "has liberties at position", 2, 2, 6
          it_behaves_like "has liberties at position", 4, 3, 9
        end

        describe 'capturing two distinct groups' do
          let(:board_string) do
            <<-BOARD
-----
OO-OO
XX-XX
OO-OO
-----
            BOARD
            let(:capturer) {[3, 3, :white]}

            it "makes 4 captures" do
              expect(captures[:white]).to eq 4
            end

            it "removes the captured stones" do
              [board_at(1, 3), board_at(2, 3),
              board_at(4, 3), board_at(5, 3)].each do |field|
                expect(field).to eq Board::EMPTY
              end
            end

            it_behaves_like "has liberties at position", 1, 2, 5
            it_behaves_like "has liberties at position", 3, 2, 5
            it_behaves_like "has liberties at position", 3, 3, 4
            it_behaves_like "has liberties at position", 1, 4, 5
            it_behaves_like "has liberties at position", 3, 4, 5

          end
        end
      end

      describe 'Playing moves on a board (old board move integration)' do
        let(:game) {Game.new board_size}
        let(:board) {game.board}
        let(:board_size) {19}
        let(:simple_x) {1}
        let(:simple_y) {1}
        let(:simple_color) {:black}

        describe 'A simple move' do

          before :each do
            game.play! simple_x, simple_y, simple_color
          end

          it 'lets the board retrieve the move at that position' do
            expect(board_at(simple_x, simple_y)).to eq simple_color
          end

          it 'sets the move_count to 1' do
            expect(game.move_count).to eq 1
          end

          it 'should have played moves' do
            expect(game).not_to be_no_moves_played
          end

          it 'returns a truthy value' do
            legal_move = StoneFactory.build x: simple_x + 2, color: :white
            expect(game.play(*legal_move)).to eq(true)
          end

          it "can play a pass move" do
            pass = StoneFactory.pass(:white)
            game.play *pass
            expect(game.moves.last).to eq nil
          end
        end

        describe 'A couple of moves' do
          let(:moves) do
            [ StoneFactory.build(x: 3, y: 7, color: :black),
              StoneFactory.build(x: 5, y: 7, color: :white),
              StoneFactory.build(x: 3, y: 10, color: :black)
            ]
          end

          before :each do
            moves.each {|move| game.play *move}
          end

          it 'sets the move_count to the number of moves played' do
            expect(game.move_count).to eq moves.size
          end
        end

        describe 'Illegal moves' do
          it 'is illegal to play moves with a greater x than the board size' do
            illegal_move = StoneFactory.build(x: board_size + 1)
            expect(game.play(*illegal_move)).to eq(false)
          end

          it 'is illegal to play moves with a greater y than the board size' do
            illegal_move = StoneFactory.build(y: board_size + 1)
            expect(game.play(*illegal_move)).to eq(false)
          end
        end
      end
    end

    describe '#dup' do

      let(:dupped) {game.dup}
      let(:move1) {StoneFactory.build(x: 1, y:1, color: :black)}
      let(:move2) {StoneFactory.build x: 3, y:1, color: :white}
      let(:move3) {StoneFactory.build x: 5, y:1, color: :black}
      let(:board) {game.board}

      before :each do
        dupped.play! *move1
        dupped.play! *move2
        dupped.play! *move3
      end



      describe "empty game" do
        let(:game) {Game.new 5}

        it "does not change the board" do
          expect(board.to_s).to eq <<-BOARD
-----
-----
-----
-----
-----
          BOARD
        end

        it "has zero moves played" do
          expect(game.move_count).to eq 0
        end

        it "changes the board for the copy" do
          expect(dupped.board.to_s).to eq <<-BOARD
X-O-X
-----
-----
-----
-----
          BOARD
        end

        it "has moves played for the copy" do
          expect(dupped.move_count).to eq 3
        end
      end

      describe "game with some moves" do
        let(:game) do
          Game.from board_string
        end
        let(:board_string) do
          <<-BOARD
-----
O-X-X
O-O-O
-----
-----
          BOARD
        end

        describe "not changing the original" do
          it "is still the same board" do
            expect(game.board.to_s).to eq board_string
          end

          it "still has the old move_count" do
            expect(game.move_count).to eq 6
          end

          it "does not modify the group of the stones" do
            group = board[5, 2].group
            expect(group.stones.size).to eq 1
          end

          it "stones have different identities" do
            expect(board[5,2]).not_to be dupped.board[5, 2]
          end

          it "the group points to the right liberties" do
            expect(board[3, 3].group.liberties['3-4']).not_to be dupped.board[3, 4]
            expect(board[3, 3].group.liberties['3-4']).to be board[3, 4]
          end

          it "does not register the new stones" do
            group = board[1, 2].group
            expect(group.liberties['1-1']).to be board[1, 1]
            expect(group.liberty_count).to eq 4
          end
        end

        describe "the dupped entity has the changes" do
          it "has a move count of 9" do
            expect(dupped.move_count).to eq 9
          end

          it "has the new moves" do
            expect(dupped.board.to_s).to eq <<-BOARD
X-O-X
O-X-X
O-O-O
-----
-----
            BOARD
          end

          it "handles groups" do
            group = dupped.board[5, 2].group
            expect(group.stones.size).to eq 2
          end

          it "has the right group liberties" do
            expect(dupped.board[3, 3].group.liberties['3-4']).to be dupped.board[3, 4]
            expect(dupped.board[3, 3].group.liberties['3-4']).not_to be board[3, 4]
          end

          it "registers new stones" do
            group = dupped.board[1, 2].group
            expect(group.liberties['1-1']).to be dupped.board[1, 1]
            expect(group.liberty_count).to eq 3
          end
        end

      end
    end
  end
end