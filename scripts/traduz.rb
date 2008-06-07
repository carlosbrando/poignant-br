#!/usr/bin/env ruby
require 'net/http'
require 'rubygems'
require 'hpricot'
require 'open-uri'

# #
# BABYLON
b = Hpricot(open("http://www.babylon.com/definition/#{ARGV[0]}/Portuguese")).at('#results-col').inner_text
puts b.gsub("\n\n"," ").gsub("Abaixe este dicionário", "")

# #
# GOOGLE
html = Net::HTTP.new('translate.google.com').post('/translate_t', "langpair=en|pt&text=#{ARGV[0]}").body
puts "\n\nGoogle Translate:"
puts Hpricot(html).at('#result_box').inner_text

# #
# BABEL FISH
# TODO