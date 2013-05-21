# encoding: UTF-8
require 'set'
require 'prime'

module ExtremeStartup
  class Question
    class << self
      def generate_uuid
        @uuid_generator ||= UUID.new
        @uuid_generator.generate.to_s[0..7]
      end
    end

    def ask(player)
      url = player.url + '?q=' + URI.escape(self.to_s)
      puts "GET: " + url
      begin
        response = get(url)
        if (response.success?) then
          self.answer = response.to_s
        else
          @problem = "error_response"
        end
      rescue => exception
        puts exception
        @problem = "no_server_response"
      end
    end

    def get(url)
      HTTParty.get(url)
    end

    def result
      if @answer && self.answered_correctly?(answer)
        "correct"
      elsif @answer
        "wrong"
      else
        @problem
      end
    end

    def delay_before_next
      case result
        when "correct"        then 5
        when "wrong"          then 10
        else 20
      end
    end
    
    def was_answered_correctly
      result == "correct"
    end
    
    def was_answered_wrongly
      result == "wrong"
    end

    def display_result
      "\tquestion: #{self.to_s}\n\tanswer: #{answer}\n\tresult: #{result}"
    end

    def id
      @id ||= Question.generate_uuid
    end

    def to_s
      "#{id}: #{as_text}"
    end

    def answer=(answer)
      @answer = answer.force_encoding("UTF-8")
    end

    def answer
      @answer && @answer.downcase.strip
    end

    def answered_correctly?(answer)
      correct_answer.to_s.downcase.strip == answer
    end

    def points
      10
    end
  end

  class BinaryMathsQuestion < Question
    def initialize(player, *numbers)
      if numbers.any?
        @n1, @n2 = *numbers
      else
        @n1, @n2 = rand(20), rand(20)
      end
    end
  end

  class TernaryMathsQuestion < Question
    def initialize(player, *numbers)
      if numbers.any?
        @n1, @n2, @n3 = *numbers
      else
        @n1, @n2, @n3 = rand(20), rand(20), rand(20)
      end
    end
  end

  class SelectFromListOfNumbersQuestion < Question
    def initialize(player, *numbers)
      if numbers.any?
        @numbers = *numbers
      else
        size = rand(2)
        @numbers = random_numbers[0..size].concat(candidate_numbers.shuffle[0..size]).shuffle
      end
    end

    def random_numbers
      randoms = Set.new
      loop do
        randoms << rand(1000)
        return randoms.to_a if randoms.size >= 5
      end
    end

    def correct_answer
       @numbers.select do |x|
         should_be_selected(x)
       end.join(', ')
     end
  end

  class MaximumQuestion < SelectFromListOfNumbersQuestion
    def as_text
      "Hvilket av de folgende tallene er storst: " + @numbers.join(', ')
    end
    def points
      40
    end
    private
      def should_be_selected(x)
        x == @numbers.max
      end

      def candidate_numbers
          (1..100).to_a
      end
    end

  class AdditionQuestion < BinaryMathsQuestion
    def as_text
      "hva er #{@n1} pluss #{@n2}"
    end
  private
    def correct_answer
      @n1 + @n2
    end
  end

  class SubtractionQuestion < BinaryMathsQuestion
    def as_text
      "hva er #{@n1} minus #{@n2}"
    end
  private
    def correct_answer
      @n1 - @n2
    end
  end

  class MultiplicationQuestion < BinaryMathsQuestion
    def as_text
      "hva er #{@n1} multiplisert med #{@n2}"
    end
  private
    def correct_answer
      @n1 * @n2
    end
  end

  class AdditionAdditionQuestion < TernaryMathsQuestion
    def as_text
      "Hva er #{@n1} pluss #{@n2} pluss #{@n3}"
    end
    def points
      30
    end
  private
    def correct_answer
      @n1 + @n2 + @n3
    end
  end

  class AdditionMultiplicationQuestion < TernaryMathsQuestion
    def as_text
      "Hva er #{@n1} pluss #{@n2} multiplisert med #{@n3}"
    end
    def points
      60
    end
  private
    def correct_answer
      @n1 + @n2 * @n3
    end
  end

  class MultiplicationAdditionQuestion < TernaryMathsQuestion
    def as_text
      "Hva er #{@n1} multiplisert med #{@n2} pluss #{@n3}"
    end
    def points
      50
    end
  private
    def correct_answer
      @n1 * @n2 + @n3
    end
  end

  class PowerQuestion < BinaryMathsQuestion
    def as_text
      "Hva er #{@n1} opphoyd i #{@n2}"
    end
    def points
      20
    end
  private
    def correct_answer
      @n1 ** @n2
    end
  end

  class SquareCubeQuestion < SelectFromListOfNumbersQuestion
    def as_text
      "Hvilke av de folgende tallene har et heltall både som kvadratrot og kubikkrot: " + @numbers.join(', ')
    end
    def points
      60
    end
  private
    def should_be_selected(x)
      is_square(x) and is_cube(x)
    end

    def candidate_numbers
        square_cubes = (1..100).map { |x| x ** 3 }.select{ |x| is_square(x) }
        squares = (1..50).map { |x| x ** 2 }
        square_cubes.concat(squares)
    end

    def is_square(x)
      if (x ==0)
        return true
      end
      (x % Math.sqrt(x)) == 0
    end

    def is_cube(x)
      if (x ==0)
        return true
      end
      (x % Math.cbrt(x)) == 0
    end
  end

  class PrimesQuestion < SelectFromListOfNumbersQuestion
     def as_text
       "Hvilke av de folgende tallene er primtall: " + @numbers.join(', ')
     end
     def points
       60
     end
   private
     def should_be_selected(x)
       Prime.prime? x
     end

     def candidate_numbers
       Prime.take(100)
     end
   end

  class FibonacciQuestion < BinaryMathsQuestion
    def as_text
      n = @n1 + 4
      return "Hvilket tall er nummer #{n} i Fibonaccirekken"  
    end
    def points
      50
    end
  private
    def correct_answer
      n = @n1 + 4
      a, b = 0, 1
      n.times { a, b = b, a + b }
      a
    end
  end

  class GeneralKnowledgeQuestion < Question
    class << self
      def question_bank
        [
          ["Hva er norges storste by?", "Oslo"],
          ["I hvilken by ble det første Mileskontoret åpnet?", "Bergen"],
          ["Hva er twitter-handlen til Bergen CodingDojo?", "BergenCodeDojo"],
          ["Hvor mange grader er det i en sirkel?", "360"],
          ["Har vi øl i kjøleskapet?", "Ja"],
          ["Hvor mange meetups har Bergen CodingDojo arrangert","10"]
        ]
      end
    end

    def initialize(player)
      question = GeneralKnowledgeQuestion.question_bank.sample
      @question = question[0]
      @correct_answer = question[1]
    end

    def as_text
      @question
    end

    def correct_answer
      @correct_answer
    end
  end

  require 'yaml'
  class AnagramQuestion < Question
    def as_text
      possible_words = [@anagram["correct"]] + @anagram["incorrect"]
      %Q{Hvilket av de folgende ordene er et anagram av "#{@anagram["anagram"]}": #{possible_words.shuffle.join(", ")}}
    end

    def initialize(player, *words)
      if words.any?
        @anagram = {}
        @anagram["anagram"], @anagram["correct"], *@anagram["incorrect"] = words
      else
        anagrams = YAML.load_file(File.join(File.dirname(__FILE__), "anagrams.yaml"))
        @anagram = anagrams.sample
      end
    end

    def points
      80
    end

    def correct_answer
      @anagram["correct"]
    end
  end

class PalindromeQuestion < Question
    def initialize(player, *words)
      if words.any?
        @sample = words
        @palindromes = @sample.select { |w| w.reverse==w }
      else
        all_words = YAML.load_file(File.join(File.dirname(__FILE__), "palindromes.yaml"))
        @non_palindromes = all_words["incorrect"].sample(rand(3..6))
        @palindromes = all_words["correct"].sample(rand(3..6))
        @sample= (@non_palindromes+@palindromes).shuffle
      end
    end

    def points
      35
    end

    def as_text
      %Q{Hvilke ord er et palindrom?: #{@sample.join(", ")}}
    end

    def correct_answer
      @sample.select{|p|@palindromes.include?(p)}.join(", ")
    end
  end


  class ClockAngleQuestion<Question

    def initialize(player, *time)
      if time.any?
        @hr, @min= time.first.split(":")
        @hr = @hr.to_i
        @min = @min.to_i
      else
        @hr = rand(0..23)
        @min = rand(0..59)
      end
    end

    def points
      200
    end

    def as_text
      "Hva er den minste vinkelen mellom timeviseren og minuttviseren ved #{'%02d' % @hr}:#{'%02d' % @min}"
    end

    def correct_answer
      @hr12= @hr % 12
      hr_angle=0.5*((60*@hr12)+@min)
      min_angle=6*@min
      angle=(min_angle - hr_angle).abs
      (angle>180) ? (360-angle).round : angle.round
    end

  end


  class ScrabbleQuestion < Question
    def as_text
      "what is the english scrabble score of #{@word}"
    end

    def initialize(player, word=nil)
      if word
        @word = word
      else
        @word = ["banana", "september", "cloud", "zoo", "ruby", "buzzword"].sample
      end
    end

    def correct_answer
      @word.chars.inject(0) do |score, letter|
        score += scrabble_scores[letter.downcase]
      end
    end

    private

    def scrabble_scores
      scores = {}
      %w{e a i o n r t l s u}.each  {|l| scores[l] = 1 }
      %w{d g}.each                  {|l| scores[l] = 2 }
      %w{b c m p}.each              {|l| scores[l] = 3 }
      %w{f h v w y}.each            {|l| scores[l] = 4 }
      %w{k}.each                    {|l| scores[l] = 5 }
      %w{j x}.each                  {|l| scores[l] = 8 }
      %w{q z}.each                  {|l| scores[l] = 10 }
      scores
    end
  end

  class QuestionFactory
    attr_reader :round

    def initialize
      @round = 1
      @question_types = [
       # GeneralKnowledgeQuestion,             #00  1
        AdditionQuestion,                     #01  1
        AdditionQuestion,                     #01  1
        MaximumQuestion,                      #02  1
        MultiplicationQuestion,               #03  2
        PrimesQuestion,                       #04  2 
        SquareCubeQuestion,                   #05  2 
        PalindromeQuestion,                   #06  3
        SubtractionQuestion,                  #07  3
        FibonacciQuestion,                    #08  3
        PowerQuestion,                        #09  4
        AdditionAdditionQuestion,             #10  4
        AdditionMultiplicationQuestion,       #11  4
        MultiplicationAdditionQuestion,       #12  5
        AnagramQuestion,                      #13  5
        ClockAngleQuestion                    #14  5
      ]
    end

    def next_question(player)
      window_end = (@round * 3 - 1)
      #window_start = [0, window_end - 4].max
      # 1 -  - 2
      # 2 -  - 5
      # 3 -  - 8
      # 4 -  - 11
      # 5 -  - 14

      window_start = 0 
      #window_end = 14
      available_question_types = @question_types[window_start..window_end]
      available_question_types.sample.new(player)
    end

    def advance_round
      @round += 1
    end

  end

  class WarmupQuestion < Question
    def initialize(player)
      @player = player
    end

    def correct_answer
      @player.name
    end

    def as_text
      "Hva heter du?"
    end
  end

  class WarmupQuestionFactory
    def next_question(player)
      WarmupQuestion.new(player)
    end

    def advance_round
      raise("please just restart the server")
    end
  end

end
