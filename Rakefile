LANGUAGES=   FileList['lang-*'].map do |file| 
    file.gsub(/lang-(\w+)/,'\1')
  end

desc "List all known localizations"
task :localizations do
  str = LANGUAGES.join(', ')
  puts "Available localizations: " + str
end

task :target do
  if ARGV.size <= 1  # Only tasks is given
    TARGET = './poignant-site'
    $stderr.puts "*warning* no path given on command line: using default #{TARGET}"
  else
    TARGET = ARGV[1]
  end
end

desc "Create default (english) version of the (poignant) guide"
task :default => [ :target ] do
  generate_for( 'en', TARGET )
end

desc "Create all versions of the (poignant) guide"
task :all => [ :target ] do
  LANGUAGES.each do |language|
    generate_for( language, TARGET )
  end
end

LANGUAGES.each do |lang|
  desc "Create #{lang} version of the (poignant) guide"
  task lang.intern => [ :target ] do
    generate_for( lang , TARGET )
  end

end

desc "Basic info on how to call rake with this file"
task :info do
  print "\nrake <" + LANGUAGES.join("|") + "|all|default> [path]\n\n"
  puts "Will generate the book (localized or all versions) in path."
  puts "If path is not given it will default to ./poignant-site"
  puts "Each language version will then go in a directory named "
  puts "after its name (i.e. en, fr ..)"
  puts
end

def generate_for( language , path)
    target = File.join( path, language )
    puts "About to generate for #{language} in #{target}"
    sh "ruby scripts/poignant.rb #{target} #{language}"
end

