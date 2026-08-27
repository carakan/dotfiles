#!/Users/carakan/.asdf/shims/ruby
require 'irb/completion'
require 'irb/ext/save-history'

puts "Using Ruby version \e[31m#{RUBY_VERSION}\e[0m."

IRB.conf[:PROMPT_MODE] = :DEFAULT
IRB.conf[:USE_READLINE] = true
IRB.conf[:SAVE_HISTORY] = 1000
IRB.conf[:EVAL_HISTORY] = 200
IRB.conf[:HISTORY_FILE] = File.expand_path('~/.irb-history')
IRB.conf[:AUTO_INDENT] = true

def logs_on
  if defined?(Rails::Console)
    ActiveRecord::Base.logger = Logger.new(STDOUT)
  end
end

def no_logs
  if defined?(Rails::Console)
    ActiveRecord::Base.logger = nil
  end
end

IRB.conf[:PROMPT_MODE] = :SIMPLE

if defined? Rails
  project_name = File.basename(Dir.pwd)
  environment = "\e[33m#{Rails.env[0..3]}\e[0m"
  prompt = "#{project_name}[#{environment}]"
  IRB.conf[:PROMPT] ||= {}
  IRB.conf[:PROMPT][:RAILS] = {
    PROMPT_I: "#{prompt} %03n >> ",
    PROMPT_N: "#{prompt} %03n ?> ",
    PROMPT_S: "#{prompt} %03n %l ",
    PROMPT_C: "#{prompt} %03n ?> ",
    RETURN: "=> %s\n"
  }
  IRB.conf[:PROMPT_MODE] = :RAILS
end

begin
  require "awesome_print"
  AwesomePrint.irb!
rescue LoadError => err
  puts "no awesome_print :("
end

logs_on
