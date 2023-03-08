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
    ignores:,
    recursive:  # ignored
  )
    dirs = Array(directories)
    if dirs.empty?
      dirs << "."
    end

    ignores_ = collect_ignores(dirs: dirs, ignores: ignores)

    write_file_list(dirs: dirs, ignores: ignores_)
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

  private def collect_ignores(dirs:, ignores:)
    ignores_ = Array(ignores)

    dirs.each do |dir|
      gitignore_file = File.join(dir, ".gitignore")
      if File.exist?(gitignore_file)
        ignores_ += (
          File
          .readlines(gitignore_file)
          .map(&:strip)
        )
      end
    end

    ignores_
  end

  private def write_file_list(dirs:, ignores:)
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

        if ignores.none? { |pattern|
          File.fnmatch(pattern, path_)
        }
          f.puts path_
        end
      end
    end
  end
end
