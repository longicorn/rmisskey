require 'net/http'
require 'uri'
require 'cgi'
require 'json'
require 'optparse'

class Misskey
  def initialize(url, token)
    @top_url = url
    @token = token
  end

  def post(text)
    api_url = "#{@top_url}/api"
    url = "#{api_url}/notes/create"
    uri = URI.parse(url)
    uri = URI(uri)

    header = {'Content-Type': 'application/json'}
    params = {i: @token, text: text}

    res = Net::HTTP.post(uri,
      params.to_json,
      header
    )
    if res.is_a?(Net::HTTPSuccess)
      return true
    else
      $stderr.puts "Post failed: #{res.code}"
      return false
    end
  end
end

opt = OptionParser.new
options = {}
opt.on('-f', '--file FILE', String) {|v| options[:file] = v }
opt.parse!(ARGV)
unless options.dig(:file)
  $stderr.puts opt.help
  exit 1
end


url = ENV['MISSKEY_URL']
if url.nil? || url.empty?
  $stderr.puts 'MISSKEY_URL is not set'
  exit 1
end
token = ENV['MISSKEY_TOKEN']
if token.nil? || token.empty?
  $stderr.puts 'MISSKEY_TOKEN is not set'
  exit 1
end

misskey = Misskey.new(url, token)
text = File.read(options[:file]).chomp
misskey.post(text)
