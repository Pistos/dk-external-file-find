require "shellwords"

# Replace Diakonos' built-in class
class FuzzyFileFinder
  LIST_FILE = File.join(
    $diakonos.diakonos_home,
    "external-file-find--files.txt"
  )
  TEMP_FILE = LIST_FILE + ".tmp"

  def initialize(
    ceiling:,  # ignored
    directories:,
    ignores:,  # TODO
    recursive:  # ignored
  )
    @ignores = Array(ignores)

    dirs = Array(directories)

    if dirs.empty?
      dirs << "."
    end

    # @files = []
    # @directories = {}  # To detect link cycles
    # @dirs_with_many = []

    write_file_list(dirs: dirs)
  end

  def find(query, max = nil)
    finder = (
      $diakonos
      .settings["extension.external_file_finder.command"]
      .gsub(
        /\$s/,
        Shellwords.escape(query)
      )
    )

    `#{finder} < #{LIST_FILE}`
    .split("\n")
    .map { |path|
      {path: path}
    }
  end

  private def write_file_list(dirs:)
    File.open(LIST_FILE, "w") do |f|
      dir_list = dirs.join(" ")
      `find #{dir_list} -type f > #{TEMP_FILE}`

      File.open(TEMP_FILE, "r").each_line do |path|
        path_ = path.strip

        dirs.each do |dir|
          if dir.end_with?("/")
            dir_ = dir
          else
            dir_ = dir + "/"
          end

          if path_.start_with?(dir_)
            path_ = path_[dir_.length..-1]
          end
        end

        if @ignores.none? { |pattern|
          File.fnmatch(pattern, path_)
        }
          f.puts path_
        end
      end
    end
  end
end
