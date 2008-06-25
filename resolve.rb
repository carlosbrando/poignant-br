# resolve.rb = put this at the root of your Rails project
# ruby resolve.rb will search every relevant file for svn/git conflicts
def process_file(file)
  dest_file = file + ".tmp"
  File.delete(dest_file) if File.exists?(dest_file)
  File.open(file, "r") do |source|
    line_count = 0
    File.open(dest_file, "w") do |dest|
      while line = source.gets
        line_count += 1
        if line =~ /<<<<<<</
          head_buffer = ""
          master_buffer = ""
          is_head = true
          while line = source.gets
            line_count += 1
            break if line =~ />>>>>>>/
            if line =~ /=======/
              is_head = false
              next
            end
            if is_head
              head_buffer << line
            else
              master_buffer << line
            end
          end
          puts "\n\nLine: #{line_count} File: #{file}\n"
          puts "<<<<<<< HEAD \n"
          puts head_buffer
          puts "======= \n"
          puts master_buffer
          puts ">>>>>>> MASTER \n"
          puts "Choose (h)ead or (m)aster (default m)"
          choice = "x"
          while !%w(h m q).include?(choice)
            break if choice == ''
            choice = gets.strip
          end
          case choice
          when 'q': exit(1)
          when 'h': dest << head_buffer
          when '','m': dest << master_buffer
          end
        else
          dest << line
        end
      end
    end
  end
  dest_file
end

%w(rb rhtml rxml rjs js html txt rake cgi fcgi css yml).each do |format|
  Dir.glob("**/*.#{format}").each do |file|
    next if file =~ /resolve\.rb/
    puts "\n======= Processing: #{file}\n"
    tmp_file = process_file(file)
    File.delete(file)
    File.rename(tmp_file, file)
  end
end

%w(CHANGELOG LICENSE README).each do |orig|
  Dir.glob("**/#{orig}").each do |file|
    puts "\n======= Processing: #{file}\n"
    tmp_file = process_file(file)
    File.delete(file)
    File.rename(tmp_file, file)
  end
end
