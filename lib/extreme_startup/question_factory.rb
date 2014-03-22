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
      "Hva er #{@n1} pluss #{@n2}?"
    end
  private
    def correct_answer
      @n1 + @n2
    end
  end

  class SubtractionQuestion < BinaryMathsQuestion
    def as_text
      "Hva er #{@n1} minus #{@n2}?"
    end
  private
    def correct_answer
      @n1 - @n2
    end
  end

  class MultiplicationQuestion < BinaryMathsQuestion
    def as_text
      "Hva er #{@n1} multiplisert med #{@n2}?"
    end
  private
    def correct_answer
      @n1 * @n2
    end
  end

  class AdditionAdditionQuestion < TernaryMathsQuestion
    def as_text
      "Hva er #{@n1} pluss #{@n2} pluss #{@n3}?"
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
      "Hva er #{@n1} pluss #{@n2} multiplisert med #{@n3}?"
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
      "Hva er #{@n1} multiplisert med #{@n2} pluss #{@n3}?"
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
      "Hva er #{@n1} opphoyd i #{@n2}?"
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
      "Hvilke av de folgende tallene er både kvadrattall og kubetall: " + @numbers.join(', ')
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
      (x % (Math.sqrt(x).round(4))) == 0
    end

    def is_cube(x)
      if (x ==0)
        return true
      end
      (x % (Math.cbrt(x).round(4))) == 0
    end
  end

  class EvenQuestion < SelectFromListOfNumbersQuestion
     def as_text
       "Hvilke av de folgende tallene er partall: " + @numbers.join(', ')
     end
     def points
       60
     end
   private
     def should_be_selected(x)
       x.even?
     end

     def candidate_numbers
        (1..100).to_a
     end
   end

  class OddQuestion < SelectFromListOfNumbersQuestion
     def as_text
       "Hvilke av de folgende tallene er oddetall: " + @numbers.join(', ')
     end
     def points
       60
     end
   private
     def should_be_selected(x)
       x.odd?
     end

     def candidate_numbers
       (1..100).to_a
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
       Prime.take(10)
     end
   end

  class FibonacciQuestion < BinaryMathsQuestion
    def as_text
      n = @n1 + 4
      return "Hvilket tall er nummer #{n} i Fibonaccirekken?"  
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
          ["Hvor mange grader er det i en sirkel?", "360"],
          ["Har vi øl i kjøleskapet?", "Ja"],
          ["Hva heter organisasjonen som arrangerer pils og programmering?","Kompiler"]
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
      %Q{Hvilke av de folgende ordene er palindrom: #{@sample.join(", ")}}
    end

    def correct_answer
      @sample.select{|p|@palindromes.include?(p)}.join(", ")
    end
  end

  class ClosestQuestion<Question

    def initialize(player,*words)
      if words.any?
        @questions = {}
        @questions["question"], @questions["answer"] = words
      else
        questions = YAML.load_file(File.join(File.dirname(__FILE__), "nermestTall.yaml"))
        @question = questions.sample
      end
    end

    def points
      50
    end

    def as_text
      %Q{#{@question["question"]}}
    end

    def correct_answer
      @question["answer"]
    end

  end

  class LocationFacts<Question

    def initialize(player,*words)
      if words.any?
        @fact = {}
        @fact["fact"], @facts["truth"] = words
      else
        facts = YAML.load_file(File.join(File.dirname(__FILE__), "locationFacts.yaml"))
        @fact = facts.sample
      end
    end

    def points
      100
    end

    def as_text
      %Q{#{@fact["fact"]}}
    end

    def correct_answer
      @fact["truth"]
    end

  end

  class FamilyFacts<Question

    def initialize(player,*words)
      if words.any?
        @fact = {}
        @fact["question"], @facts["relation"] = words
      else
        facts = YAML.load_file(File.join(File.dirname(__FILE__), "FamilyFacts.yaml"))
        @fact = facts.sample
      end
    end

    def points
      100
    end

    def as_text
      %Q{#{@fact["question"]}}
    end

    def correct_answer
      @fact["relation"]
    end

  end


  class ScrabbleQuestion < Question
    def as_text
      "Hva er den engelske scrabble poengsummen for #{@word}?"
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

  class PointQuestion < Question
    def as_text
      "Hvor mange poeng har du?"
    end

    def initialize(player)
      @points = scoreboard.current_score(player)
    end

    def points
      200
    end

    def correct_answer
      @points
    end
  end

  class QuestionFactory
    attr_reader :round

    def initialize
      @round = 1
      @question_types = [
        GeneralKnowledgeQuestion,             
        AdditionQuestion,                     
        ClosestQuestion,
        AdditionQuestion,                     
        MaximumQuestion,                      
        MultiplicationQuestion,               
        PrimesQuestion,                        
        OddQuestion,                    
        EvenQuestion,                    
        PalindromeQuestion,                   
        SubtractionQuestion,                  
        FamilyFacts,                          
        FibonacciQuestion,                    
        PowerQuestion,                        
        AdditionAdditionQuestion,             
        AdditionMultiplicationQuestion,       
        MultiplicationAdditionQuestion,       
        AnagramQuestion,                      
        LocationFacts,                        
      ]
    end

    def next_question(player)
      window_end = @round
      window_start = [0, window_end - 5].max

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
