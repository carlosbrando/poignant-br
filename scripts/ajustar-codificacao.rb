#! /usr/bin/env ruby
require "iconv"

if ARGV.empty?
  STDERR.puts "Uso: #{$0} <arquivo> [arquivo] [...]"
  exit 2
end

begin
  ARGV.each do |nome|
    dados = File.read(nome)
    alterado = false

    # ajustar término de linha
    if dados.gsub!("\r\n", "\n")
      alterado = true
    end

    # verificar "\n" final
    unless /\n$/ =~ dados
      dados << "\n"
      alterado = true
    end

    # verificar codificação do arquivo, testando se uma conversão
    # neutra é bem-sucedida
    begin
      utf8_valido = Iconv.conv("utf-8", "utf-8", dados) == dados
    rescue Iconv::Failure
      utf8_valido = false
    end
    # se não for válido, assumir iso-8859-1
    unless utf8_valido
      dados = Iconv.conv("utf-8", "iso-8859-1", dados)
      alterado = true
    end

    if alterado
      puts nome
      File.open(nome, "w") do |f|
        f << dados
      end
    end
  end
rescue Errno::ENOENT => err
  abort err
end
