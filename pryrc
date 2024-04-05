require 'rubygems'
require 'benchmark'

Pry.color = true
Pry.config.color = true
Pry.editor = 'vim'
Pry.config.pager = true
Pry.config.auto_indent = true
Pry.config.correct_indent = true

Pry.config.history_file = "~/.irb_history"
Pry.config.prompt = Pry::Prompt[:rails] if Pry::Prompt[:rails]

puts "Using Ruby version \e[31m#{RUBY_VERSION}\e[0m."

begin
  require "awesome_print"
  AwesomePrint.pry!
rescue LoadError => err
  puts "no awesome_print :("
end

begin
  require 'hirb'
rescue LoadError
  # Missing goodies, bummer
  puts "no hirb :("
end

if defined? Hirb
  # Slightly dirty hack to fully support in-session Hirb.disable/enable toggling
  Hirb::View.instance_eval do
    def enable_output_method
      @output_method = true
      @old_print = Pry.config.print
      Pry.config.print = proc do |output, value|
        Hirb::View.view_or_page_output(value) || @old_print.call(output, value)
      end
    end

    def disable_output_method
      Pry.config.print = @old_print
      @output_method = nil
    end
  end

  Hirb.enable
end


class Object
  def local_methods(obj = self)
    (obj.methods - obj.class.superclass.instance_methods).sort
  end

  def ri(method = nil)
    unless method && method =~ /^[A-Z]/
      klass = self.kind_of?(Class) ? name : self.class.name
      method = [klass, method].compact.join('#')
    end
    puts `ri '#{method}'`
  end
end

def reset_pry!
  exec $0
end

def quick(repetitions = 100, &block)
  require 'benchmark'
  Benchmark.bmbm {|b| b.report { repetitions.times(&block) }}
  nil
end
