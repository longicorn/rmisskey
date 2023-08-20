require 'optparse'
require 'time'
require_relative 'misskey'

opt = OptionParser.new
options = {}
opt.on('-i', '--info') {options[:info] = true }
opt.on('-p', '--post') {options[:post] = true }
opt.on('-r', '--reply NoteID') {|v| options[:reply] = true; options[:reply_id] = v }
opt.on('-f', '--file FILE', String) {|v| options[:file] = v }
opt.on('-t', '--timeline') {|v| options[:hometimeline] = true }
opt.on('-m', '--mynotes') {|v| options[:my_notes] = true }
opt.parse!(ARGV)

if options.empty?
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

options.each do |key, value|
  case key
  when :my_notes
    user_id = misskey.i['id']
    notes = misskey.my_notes(user_id, limit: 10)
    notes.reverse_each do |note|
      id_str = "id: #{note['id']}"
      id_str += " (reply: #{note['replyId']})" if note['replyId']
      time = Time.parse(note['createdAt'])
      title = [id_str, "[#{time.strftime("%Y-%m-%d %H:%M:%S")}]"].join(' ')
      puts title
      puts note['text']
      puts ''
    end
  when :hometimeline
    notes = misskey.timeline
    notes.reverse_each do |note|
      id_str = "id: #{note['id']}"
      id_str += " (reply: #{note['replyId']})" if note['replyId']
      time = Time.parse(note['createdAt'])
      title = [id_str, "[#{time.strftime("%Y-%m-%d %H:%M:%S")}]"].join(' ')
      puts title
      puts "user: #{note.dig('user', 'name')}(id: #{note.dig('user', 'id')})"
      puts note['text']
      puts ''
    end
  when :info
    pp misskey.i
  when :post, :reply
    if options[:file].nil?
      $stderr.puts opt.help
      exit 1
    end

    if options[:file].size <= 0
      $stderr.puts opt.help
      exit 1
    end
    text = File.read(options[:file]).chomp

    if options[:reply]
      misskey.note_create(text, reply_id: options[:reply_id])
    else
      misskey.note_create(text)
    end
  end
end
