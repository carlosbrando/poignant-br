#!/usr/bin/env ruby
require 'net/http'
require 'rubygems'
require 'hpricot'
require 'open-uri'


# #
# BABYLON
b = Hpricot(open("http://www.babylon.com/definition/#{ARGV[0]}/Portuguese")).at('#results-col').inner_text
puts b.gsub(/(\n\n)|(Erros Nunca Mais)|(Abaixe este dicionário)/, '')

# #
# URBAN DICTIONARY
u = Hpricot(open("http://www.urbandictionary.com/define.php?term=#{ARGV[0]}")).at('#entries').inner_text
puts u.gsub(/(\n\n)|(comments)/,'')

# #
# GOOGLE
# http://www.wagnerandrade.com/blog/2008/05/ruby-snapshot-1
html = Net::HTTP.new('translate.google.com').post('/translate_t', "langpair=en|pt&text=#{ARGV[0]}").body
puts "\n\nGoogle Translate:"
puts Hpricot(html).at('#result_box').inner_text

# #
# BABEL FISH
# TODO
