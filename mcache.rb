require 'pathname'
require 'fileutils'

class Mcache
  class << self
    def cache(type, key, timeout: nil, force: false)
      return unless block_given?

      delete(path) if force

      data = read(type, key, timeout: timeout)
      return data if data

      data = yield
      write(type, key, data)

      data
    end

    def delete(path)
      File.delete(path)
    end

    def read(type, key, timeout: nil)
      path = target_path(type, key)
      return unless path && File.exist?(path)

      s = File::Stat.new(path)
      if timeout && Time.now <= s.mtime + timeout
        # delete timeout cache
        delete(path)
        return
      end
      JSON.parse(File.read(path))
    end

    def write(type, key, data)
      return if data.nil?
      path = target_path(type, key)
      File.open(path, 'w') do |f|
        data = data.to_json unless data.is_a?(String)
        f.write(data)
      end
    end

    private

    def topdir
      dir = Pathname(Dir.home).join('.cache/rmisskey')
      FileUtils.mkdir_p(dir)
      return dir
    end

    def target_path(dir, filename)
      dir = topdir.join(dir)
      FileUtils.mkdir_p(dir)
      dir.join(filename)
    end
  end
end
