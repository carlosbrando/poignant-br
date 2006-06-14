# = Translation progress calculator
#
# by murphy
#
# == Usage
#
# Insert some comments into the book (using YAML comments: #...)
# that split it into parts, like this:
#
#   # {{{ Index: 97%
#   
#   image: !^img poignant.guide.png
#   ...
#   # }}}
#   
#   # {{{ Chapter 1: 30%
#   ...
# 
# Then run
# 
#   scripts/progress.rb lang
# 
# for your +lang+.
#
# == Syntax
#
# Open part:: {{{ <Description>
# Close part:: }}}
# Progress (percentage):: {{{ Chapter 5: 45%
# Don't count this:: {{{ <Description> !
#
# == Vim
#
# As you might have recognized, this is also the syntax for Vim folding.
# So if you use Vim, you win twice.

if ARGV.empty?
	puts <<-USAGE
Compute translation progress.
Usage:
	ruby progress {de|fr|...}
	USAGE
	exit
end

lang = ARGV.first
file = "#{File.dirname($0)}/../lang-#{lang}/poignant.yml"

puts
print "Scanning #{file} "
guide = File.read file
print '.'

PART = /
	\# \s* \{\{\{ \s*
		( .*? ) \n     # $1 = name, progress
		( .*? )        # $2 = content
	\# \s* \}\}\} \s*
/mx
PERCENT = / ( \d+ (?: \.\d+ )? ) % /x  # integer or decimal number
NAME = / [^:]* /x  # chars until : or end of string

parts = []
guide.scan(PART) do |desc, content|
	print '.'
	parts << {
		:progress =>
			if desc[PERCENT]
				$1.to_f / 100
			else
				0
			end,
		:name => 
			desc[NAME],
		:lines =>
			if desc['!']
				0
			else
				content.count("\n")
			end
	}
end

puts ' done'
puts

puts "Parts found: %d" % parts.size
puts

exit if parts.empty?

lines_total, lines_done = 0, 0.0
for part in parts
	lines_total += part[:lines]
	lines_done += part[:lines] * part[:progress]
end
progress = lines_done / lines_total

puts <<-RESULTS % [
	Lines in book:     %6d
	Lines translated:  %6d
	Progress:              %5.2f%% translated.
RESULTS
	lines_total,
	lines_done,
	progress * 100
]

# vim:foldmethod=manual
