#!/usr/bin/env ruby
require 'net/http'
require 'rubygems'
require 'hpricot'
require 'open-uri'

puts '# #
# URBAN DICTONARY
# # # # # # # # # # # # # # # # # # # # ###'
begin
  u = Hpricot(open("http://www.urbandictionary.com/define.php?term=#{ARGV[0]}"))
  puts u.at('#entries').inner_text.gsub(/(\n\n)|(comments)/,'') 
rescue => e
  nil
end

puts '

# #
# GOOGLE
# # # # # # # # # # # # # # # # # # # # ###'
# http://www.wagnerandrade.com/blog/2008/05/ruby-snapshot-1
html = Net::HTTP.new('translate.google.com').post('/translate_t', "langpair=en|pt&text=#{ARGV[0]}").body
puts Hpricot(html).at('#result_box').inner_text

puts '

# #
# BABYLON
# # # # # # # # # # # # # # # # # # # # ###'
b = Hpricot(open("http://www.babylon.com/definition/#{ARGV[0]}/Portuguese")).at('#results-col').inner_text
puts b.gsub(/(\n\n)|(Erros Nunca Mais)|(Abaixe este dicionário)/, '')
# #
# BABEL FISH
# TODO
