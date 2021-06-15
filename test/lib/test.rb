require_relative '../../lib/tile'
require 'colorize'
require 'set'
require 'pry-byebug'
require 'awesome_print'

class Test


  private

  def initialize
    stats_to_zero!
  end

  def stats_to_zero!
    @assertions = 0
    @passed = 0
    @failed = 0
    @pending = 0
  end

  def assert(description, expected, &block)
    @assertions += 1
    print timestamp + " [Assertion #{@assertions}] ".red + description.cyan + " \t".cyan
    begin
      result = block.call
      if result == expected
        @passed += 1
        puts 'PASS'.green
      else
        @failed += 1
        puts "FAIL.".red
        puts "Expected: \t#{expected}".red
        puts "Actual: \t#{result}".red
      end
    rescue Exception => e
      @failed += 1
      puts "FAIL. An exception was raised.".red
      puts e.message.red
      e.backtrace.each do |line|
        puts line.red
      end
    end
  end

  def pending(description = nil, expected = nil, &block)
    @assertions += 1
    @pending += 1
    print timestamp + " [Assertion #{@assertions}] ".red + description.cyan + " \t".cyan
    puts 'PENDING'.yellow
  end

  def timestamp
    "[#{Time.now.strftime('%H:%M:%S.%7N')}]".magenta
  end

  def log(message)
    puts timestamp + " " +  message.green
  end
  def error(message)
    puts timestamp + " " +  message.red
  end
  def info(message)
    puts timestamp + " " +  message.cyan
  end

end
