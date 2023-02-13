module Diakonos
  module Functions

    def open_with_file_finder(finder_executable)
      Curses::close_screen

      file = `find #{@session.dir} -type f | #{finder_executable}`
      file&.strip!

      Curses::init_screen
      refresh_all

      if file && ! file.empty?
        open_file file
        update_status_line
        update_context_line
      end
    end

  end
end
