require 'erb'
require 'yaml'
require 'redcloth'

module WhyTheLuckyStiff
class Book
    attr_accessor :author, :title, :terms, :image, :teaser, :chapters
end

def Book::load( file_name )
    YAML::load( File.open( file_name ) )
end

class Section
    attr_accessor :index, :header, :content
    def initialize( i, h, c )
        @index, @header, @content = i, h, RedCloth::new( c.to_s )
    end
end

class Sidebar
    attr_accessor :title, :content
end

YAML::add_domain_type( 'whytheluckystiff.net,2003', 'sidebar' ) do |taguri, val|
    YAML::object_maker( Sidebar, 'title' => val.keys.first, 'content' => RedCloth::new( val.values.first ) )
end
class Chapter
    attr_accessor :index, :title, :sections
    def initialize( i, t, sects )
        @index = i
        @title = t
        i = 0
        @sections = sects.collect do |s|
            if s.respond_to?( :keys ) 
                i += 1
                Section.new( i, s.keys.first, s.values.first )
            else
                s
            end
        end
    end
end

YAML::add_domain_type( 'whytheluckystiff.net,2003', 'book' ) do |taguri, val|
    i = 0;
    val['chapters'].collect! do |c| 
        i += 1
        Chapter::new( i, c.keys.first, c.values.first )
    end
    val['teaser'].collect! do |t|
        Section::new( 1, t.keys.first, t.values.first )
    end
    val['terms'] = RedCloth::new( val['terms'] )
    YAML::object_maker( Book, val )
end

class Image
    attr_accessor :file_name
end

YAML::add_domain_type( 'whytheluckystiff.net,2003', 'img' ) do |taguri, val|
    YAML::object_maker( Image, 'file_name' => "i/" + val )
end
end

#
# Convert the book to HTML
#
if __FILE__ == $0
    book = WhyTheLuckyStiff::Book::load( 'poignant.yml' )
    chapter = nil

    # Write index page
    index_tpl = ERB::new( File.open( 'index.erb' ).read )
    File.open( 'index.html', 'w' ) do |out|
        out << index_tpl.result
    end

    # Write chapter pages
    chapter_tpl = ERB::new( File.open( 'chapter.erb' ).read )
    book.chapters.each do |chapter|
        File.open( "chapter-#{ chapter.index }.html", 'w' ) do |out|
            out << chapter_tpl.result
        end
    end
end
