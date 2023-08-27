require 'pathname'
require 'fileutils'

class Mcache
  class << self
    def cache(type, key, timeout: nil, force: false)
      if block_given?
        path = send("#{type}_path", key)
        File.delete(path) if force
        if path && File.exist?(path) && !force
          s = File::Stat.new(path)
          return JSON.load(File.read(path)) if Time.now <= s.mtime + timeout
          # delete timeout cache
          File.delete(path)
        end

        data = yield
        File.open(path, 'w') do |f|
          f.write(data.to_json)
        end if path && data

        return data
      end
    end

    def topdir
      dir = Pathname(Dir.home).join('.cache/rmisskey')
      FileUtils.mkdir_p(dir)
      return dir
    end

    def user_path(name = nil)
      dir = topdir.join('user')
      FileUtils.mkdir_p(dir)
      return unless name
      dir.join(name)
    end
  end
end
