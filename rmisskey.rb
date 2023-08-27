require 'optparse'
require 'time'
require_relative 'misskey'

opt = OptionParser.new
options = {}
opt.on('-i', '--info') {options[:info] = true }
opt.on('-p', '--post') {options[:post] = true }
opt.on('-s', '--secret') {options[:secret] = true }
opt.on('-r', '--reply NoteID', String) {|v| options[:reply] = true; options[:reply_id] = v }
opt.on('-f', '--file FILE', String) {|v| options[:file] = v }
opt.on('-t', '--timeline') {|v| options[:hometimeline] = true }
opt.on('-m', '--mynotes') {|v| options[:my_notes] = true }
opt.on('-n', '--num NUM', String) {|v| options[:num] = v }
opt.parse!(ARGV)

if options.empty?
  $stderr.puts opt.help
  exit 1
end

#check ENV
['MISSKEY_URL', 'MISSKEY_USERNAME', 'MISSKEY_TOKEN'].each do |env_name|
  env = ENV[env_name]
  if env.nil? || env.empty?
    $stderr.puts "#{env_name} is not set"
    exit 1
  end
end

def format_note_headder(note, include_user: false)
  id_str = "id: #{note['id']}"
  id_str += " (reply: #{note['replyId']})" if note['replyId']
  time = Time.parse(note['createdAt']).localtime

  user_str = nil
  user_str = "user: #{note.dig('user', 'name')}(id: #{note.dig('user', 'id')})" if include_user

  if note['reactions'].size > 0
    reactions = note['reactions'].map{|k,v|"#{k}(#{v})"}.join(', ')
    reactions = "reactions: #{reactions}" if reactions.size > 0
  end

  title = [id_str, "[#{time.strftime("%Y-%m-%d %H:%M:%S")}]"].join(' ')

  [title, reactions, user_str].compact.join("\n")
end

def format_note_body(note)
  if note['renote']
    hash = format_note(note['renote'])
    ary = []
    ary << "  #{hash[:headder].gsub(/\n/, "\n  ")}"
    ary << "  #{hash[:body].gsub(/\n/, "\n  ")}" if hash[:body]
    ary.join("\n")
  else
    ary = []
    ary << note['text'].gsub(/\n\n/, "\n#{[0x23CE].pack( "U*" )}\n").chomp if note['text']
    ary << note['files'].map{|v|v['thumbnailUrl']} if note['files']
    ary.flatten.join("\n")
  end
end

def format_note(note, include_user: false)
  hash = {}
  hash[:headder] = format_note_headder(note, include_user: include_user)
  hash[:body] = format_note_body(note)

  hash
end

def execute(misskey, options)
  options.each do |key, value|
    case key
    when :my_notes
      user_id = misskey.i['id']
      limit = options[:num] || 10
      notes = misskey.my_notes(user_id, limit: limit)
      notes.reverse_each do |note|
        hash = format_note(note)
        puts hash[:headder]
        puts hash[:body]
        puts ''
      end if notes.is_a?(Array)
    when :hometimeline
      limit = options[:num] || 10
      notes = misskey.timeline(limit: limit)
      notes.reverse_each do |note|
        hash = format_note(note, include_user: true)
        puts hash[:headder]
        puts hash[:body]
        puts ''
      end if notes.is_a?(Array)
    when :info
      pp misskey.i
    when :post
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
      visibility = nil
      if options[:secret]
        visible_user_ids = [misskey.i['id']]
        visibility = 'specified'
      end
      if options[:reply]
        ret = misskey.note_create(text, reply_id: options[:reply_id], visibility: visibility, visible_user_ids: visible_user_ids)
      else
        ret = misskey.note_create(text, visibility: visibility, visible_user_ids: visible_user_ids)
      end
      unless ret
        puts 'Post failed'
        exit 1
      end
    end
  end
end

misskey = Misskey.new(ENV['MISSKEY_URL'], ENV['MISSKEY_USERNAME'], ENV['MISSKEY_TOKEN'])
execute(misskey, options)
