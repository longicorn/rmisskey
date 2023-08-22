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
    text = ''

    # get text
    if options[:file].nil?
      if ARGV.empty?
        rs, _ = IO.select([$stdin], [], [], 0.1)
        exit if rs.nil?
        text = $stdin.gets if rs
      else
        text = ARGV.shift
      end
    else
      text = File.read(options[:file])
    end
    if text.size <= 0
      $stderr.puts opt.help
      exit 1
    end
    text = text.chomp

    ret = nil
    if options[:reply]
      ret = misskey.note_create(text, reply_id: options[:reply_id])
    else
      ret = misskey.note_create(text)
    end
    unless ret
      puts 'Post failed'
      exit 1
    end
  end
end
