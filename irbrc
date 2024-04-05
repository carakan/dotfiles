#!/usr/bin/ruby
require 'awesome_print'
require 'irb/completion'
require 'irb/ext/save-history'

puts "Using Ruby version \e[31m#{RUBY_VERSION}\e[0m."

IRB.conf[:PROMPT_MODE] = :DEFAULT
IRB.conf[:USE_READLINE] = true
IRB.conf[:SAVE_HISTORY] = 1000
IRB.conf[:EVAL_HISTORY] = 200
IRB.conf[:HISTORY_FILE] = File.expand_path('~/.irb-history')

if defined?(Rails::Console)
  ActiveRecord::Base.logger = Logger.new(STDOUT)
end

AwesomePrint.irb!