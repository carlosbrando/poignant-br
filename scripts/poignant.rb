require 'erb'
require 'ftools'
require 'yaml'
require 'rubygems'
require 'redcloth'
require 'syntax/convertors/html'

class Localization
    attr_accessor :locale, :version, :next_page, :previous_page, :encoding,
                  :turn_page, :header_title, :open_the_book, :written_by,
                  :sidebar, :contents, :expansion_pak, :expansion_pak_no,
                  :expansion_paks, :adverrtissements, :see_also, :english_version,
                  :header_title_emphasis
    def self.load( file_name )
        l = self.new
        YAML::load( File.open( file_name ) ).each do |k, v|
            v = RedCloth.new(v).to_html if ['written_by', 'header_title'].include? k
            l.instance_variable_set( "@#{k}", v )
        end
        l.header_title_emphasis = l.header_title.gsub /\(([^)]+)\)/, '<span class="hilite">\1</span>'
        l
    end
end

# Redefines to accomodate tests
class RedCloth
    SYNTAX_CONVERT = Syntax::Convertors::HTML.for_syntax "ruby"
    
    # Intercept some Kernel calls for the cause of testing.
    def loop
        yield
    end

    # Conversion to HTML
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
        x.gsub( /^\s*## @(\w+)\[(\d+)\]/, '' )
    end
end

module WhyTheLuckyStiff

class Book
    attr_accessor :author, :title, :terms, :image, :teaser, :chapters, :expansion_paks
    def self.load( file_name )
        YAML::load( File.open( file_name ) )
    end
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
        puts "Usage: #{$0} /path/to/save/html [en|fr|...]"
        exit
    end

    scripts = File.dirname(__FILE__)
    $:.unshift scripts

    # external libs
    Dir[File.expand_path('../lib/ext-*', scripts)].each do |path|
        $:.unshift path
    end
    locale = "en"               # default value

    if ARGV[1]
      # Localisation: fr, br ..
      locale = ARGV[1]
    end

    book = "lang-#{locale}/poignant.yml"
    loc_file = "lang-#{locale}/localization.yml"
    
    language = Localization.load( loc_file )
    raise NotImplementedError.new("Language #{locale} not yet supported") unless language

    site_path = ARGV[0]
  
    # FIXME: create given path if it does not exist.
    if File.exists?( site_path )
      if !File.directory?( site_path )
        $stderr.puts "#{site_path} is not a directory" ## FIXME: raise would be better
        exit 1
      end
    else
      File.makedirs( site_path )
    end

    book = WhyTheLuckyStiff::Book::load( book )
    chapter = nil

    # Write index page
    index_tpl = ERB::new( File.open( "#{ scripts }/layout/index.erb" ).read )
    File.open( File.join( site_path, 'index.html' ), 'w' ) do |out|
        out << index_tpl.result
    end

    # Write chapter pages
    chapter_tpl = ERB::new( File.open( "#{ scripts }/layout/chapter.erb" ).read )
    body_class = "chapter"
    url_pre = "chapter"
    collection = book.chapters
    collection.each do |chapter|
        File.open( File.join( site_path, "chapter-#{ chapter.index }.html" ), 'w' ) do |out|
            out << chapter_tpl.result( binding )
        end
    end

    # Write expansion pak pages
    expak_tpl = ERB::new( File.open( "#{ scripts }/layout/chapter.erb" ).read )
    body_class = "expansion"
    url_pre = "expansion-pak"
    collection = book.expansion_paks
    collection.each do |chapter|
        File.open( File.join( site_path, "expansion-pak-#{ chapter.index }.html" ), 'w' ) do |out|
            out << expak_tpl.result( binding )
        end
    end

    # Write printable version
    print_tpl = ERB::new( File.open( "#{ scripts }/layout/print.erb" ).read )
    File.open( File.join( site_path, "print.html" ), 'w' ) do |out|
        out << print_tpl.result
    end

    # Copy css + images into site

    File.makedirs( File.join( site_path, "i" ) )
    File.copy( "#{ scripts }/layout/guide.css", "#{ site_path }/guide.css" )
    Dir["#{ scripts }/images/*"].each do |copy_file|
        next if File.directory? copy_file
        File.copy( copy_file, File.join( site_path, "i", File.basename( copy_file ) ) )
    end
end

