require_relative '../spec_helper'

module MCTS::Examples
  RSpec.describe DoubleStep do
    describe "#initialize" do
      subject {DoubleStep.new}

      it "is not finished" do
        expect(subject).not_to be_finished
      end

      it "has the right position" do
        expect(subject.positions).to eq(black: 0, white: 0)
      end
    end

    describe "#all_valid_moves" do
      it "returns 1 and 2" do
        expect(subject.all_valid_moves).to contain_exactly 1, 2
      end

      context "finished game" do

      end
    end

    describe "#set_move" do
      before :each do
        subject.set_move(2)
      end

      it "sets the move for the starting color (black)" do
        expect(subject.positions[:black]).to eq 2
      end

      it "does not touch the moves of the other color" do
        expect(subject.positions[:white]).to eq 0
      end

      describe "and another move" do
        before :each do
          subject.set_move(1)
        end

        it "sets the move for white" do
          expect(subject.positions[:white]).to eq 1
        end

        it "does not touch the moves of the other color" do
          expect(subject.positions[:black]).to eq 2
        end

        it "then changes back to the original color" do
          subject.set_move(1)
          expect(subject.positions[:black]).to eq 3
          expect(subject.positions[:white]).to eq 1
        end
      end
    end

    describe "generate_move" do
      it "generates one or two" do
        expect([1, 2]).to include subject.generate_move
      end
    end

    describe "finished?" do
      it "is finished once black reaches the 6th field" do
        3.times do
          subject.set_move(2)
          subject.set_move(1)
        end
        expect(subject).to be_finished
        expect(subject).to be_won
      end

      it "is finished once black reaches the 6th field" do
        3.times do
          subject.set_move(1)
          subject.set_move(2)
        end
        expect(subject).to be_finished
        expect(subject).not_to be_won
      end
    end

    describe "#dup" do
      it "correctly dups the data and applies changes individually" do
        subject.set_move(2)
        dup = subject.dup
        subject.set_move(1)
        dup.set_move(2)
        expect(subject.positions).to eq(black: 2, white: 1)
        expect(dup.positions).to eq(black: 2, white: 2)
      end
    end

    describe "introducing a handicap" do
      it "works" do
        game = described_class.new({black: 4, white: 0})
        game.set_move(2)
        expect(game).to be_finished
        expect(game).to be_won
      end
    end
  end
end