require 'net/http'
require 'uri'
require 'cgi'
require 'json'

require_relative 'mcache'

class Misskey
  def initialize(url, username, token)
    @top_url = url
    @username = username
    @token = token
  end

  def inspect
    # not show token
    "#<Misskey:0x#{object_id.to_s(16)} @top_url=\"#{@top_url}\">"
  end

  # my info
  def i
    json = Mcache.cache("user", @username, timeout: 24*60*60) do
      status, res = api('i')
      if status
        res.body
      else
        return nil
      end
    end
    JSON.load(json)
  end

  # home timeline
  def timeline(limit: 10)
    status, res = api('notes/timeline', {limit: limit.to_i})
    if status
      JSON.load(res.body)
    else
      res.code
    end
  end

  def my_notes(user_id, limit: 10)
    params = {userId: user_id, includeMyRenotes: true, limit: limit.to_i}
    status, res = api('users/notes', params)
    if status
      return JSON.load(res.body)
    else
      return false
    end
  end

  def note_create(text, reply_id: nil)
    params = {text: text}
    params = {text: text, replyId: reply_id} if reply_id
    status, res = api('notes/create', params)
    if status
      return true
    else
      $stderr.puts "Post failed: #{res.code}"
      return false
    end
  end

  def note_show(note_id)
    status, res = api('notes/show', {noteId: note_id})
    if status
      return JSON.load(res.body)
    else
      return false
    end
  end

  def api(url, params={})
    api_url = "#{@top_url}/api"
    url = "#{api_url}/#{url}"
    uri = URI.parse(url)
    uri = URI(uri)

    header = {'Content-Type': 'application/json'}
    params = {i: @token}.merge(params)

    res = Net::HTTP.post(uri,
      params.to_json,
      header
    )
    status = res.is_a?(Net::HTTPSuccess)
    raise 'Bad Gateway' if res.code == '502'
    return status, res
  end
end
