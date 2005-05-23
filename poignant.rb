require 'erb'
require 'ftools'
require 'yaml'
require 'redcloth'
require 'syntax/convertors/html'

# Redefines to accomodate tests
class RedCloth
    SYNTAX_CONVERT = Syntax::Convertors::HTML.for_syntax "ruby"
    
    # Intercept some Kernel calls for the cause of testing.
    def loop
        yield
    end

    # Conversion to HTML
    def hard_breaks; true; end
    alias _to_html to_html
    def to_html
        @vars = {}
        txt = self.dup
        txt.gsub!( %r{<(setup|stdout)>(.+?)</\1>}m ) do |var|
                ( @vars[$1] ||= [] ) << $2
                "## @#$1[#{@vars[$1].length-1}]"
            end
        txt.gsub!( %r{<pre>(.+?)</pre>}m ) do
                "<pre>" + test_example( $1.strip ) + "</pre>"
            end
        txt._to_html.
            gsub( %r{<pre>(.+?)</pre>}m ) do
                "<div class='example'><pre><code> #{test_example $1.strip}</code></pre></div>"
            end.
            gsub( %r{<pre([^>]+)>\n*(.+?)</pre>}m ) do
                "<div class='example'><pre#{$1}>#{$2}</pre></div>"
            end.
            gsub( %r{<code>([^%].*?)</code>}m ) do
                SYNTAX_CONVERT.convert( $1.gsub( '&gt;', '>' ).gsub( '&lt;', '<' ).gsub( '&#38;', '&' ) ).
                    gsub( %r{^<pre>}, '<code>' ).gsub( %r{</pre>$}, '</code>' )
            end
    end
    def test_example( x )
        # begin
        #     eval( x.gsub( /^## @(\w+)\[(\d+)\]/ ) { @vars[$1][$2.to_i] } )
        # rescue Exception => e
        #     puts "*** Example failed ***", x, "--- Exception ---", e
        #     exit
        # end
        x.gsub( /^## @(\w+)\[(\d+)\]\n/, '' )
    end
end

module WhyTheLuckyStiff
class Book
    attr_accessor :author, :title, :terms, :image, :teaser, :chapters, :expansion_paks
end

def Book::load( file_name )
    YAML::load( File.open( file_name ) )
end

class Section
    attr_accessor :index, :header, :content
    def initialize( i, h, c )
        @index, @header, @content = i, RedCloth::new( h.to_s, [:lite_mode] ), RedCloth::new( c.to_s )
    end
end

class Sidebar
    attr_accessor :title, :content
end

YAML::add_domain_type( 'whytheluckystiff.net,2003', 'sidebar' ) do |taguri, val|
    title = val.keys.first
    YAML::object_maker( Sidebar, 'title' => ( RedCloth::new( title, [:lite_mode] ) if title ), 'content' => RedCloth::new( val.values.first ) )
end
class Chapter
    attr_accessor :index, :title, :sections
    def initialize( i, t, sects )
        @index = i
        @title = RedCloth::new( t, [:lite_mode] )
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
    ['chapters', 'expansion_paks'].each do |chaptype|
        i = 0
        val[chaptype].collect! do |c| 
            i += 1
            Chapter::new( i, c.keys.first, c.values.first )
        end
    end
    val['teaser'].collect! do |t|
        Section::new( 1, t.keys.first, t.values.first )
    end
    val['terms'] = RedCloth::new( val['terms'] )
    val['title'] = RedCloth::new( val['title'], [:lite_mode] )
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
    unless ARGV[0]
        puts "Usage: #{$0} [/path/to/save/html]"
        exit
    end

    site_path = ARGV[0]
    book = WhyTheLuckyStiff::Book::load( 'poignant.yml' )
    chapter = nil

    # Write index page
    index_tpl = ERB::new( File.open( 'index.erb' ).read )
    File.open( File.join( site_path, 'index.html' ), 'w' ) do |out|
        out << index_tpl.result
    end

    # Write chapter pages
    chapter_tpl = ERB::new( File.open( 'chapter.erb' ).read )
    book.chapters.each do |chapter|
        File.open( File.join( site_path, "chapter-#{ chapter.index }.html" ), 'w' ) do |out|
            out << chapter_tpl.result
        end
    end

    # Write expansion pak pages
    expak_tpl = ERB::new( File.open( 'expansion-pak.erb' ).read )
    book.expansion_paks.each do |pak|
        File.open( File.join( site_path, "expansion-pak-#{ pak.index }.html" ), 'w' ) do |out|
            out << expak_tpl.result( binding )
        end
    end

    # Write printable version
    print_tpl = ERB::new( File.open( 'print.erb' ).read )
    File.open( File.join( site_path, "print.html" ), 'w' ) do |out|
        out << print_tpl.result
    end

    # Copy css + images into site
    copy_list = ["guide.css"] +
                Dir["i/*"].find_all { |image| image =~ /\.(gif|jpg|png)$/ }

    File.makedirs( File.join( site_path, "i" ) )
    copy_list.each do |copy_file|
        File.copy( copy_file, File.join( site_path, copy_file ) )
    end
end

