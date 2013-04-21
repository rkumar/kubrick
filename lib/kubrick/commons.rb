# ----------------------------------------------------------------------------- #
#         File: commons.rb
#  Description: common CLI app routines that I will use
#       Author: rkumar http://github.com/rkumar/rbcurse/
#         Date: 2013-04-21 - 13:10
#  Last update: 2013-04-21 13:37
#      License: Same as Ruby's License (http://www.ruby-lang.org/LICENSE.txt)
# ----------------------------------------------------------------------------- #
#


  # pops up a list, taking a single key and returning if it is in range of 33 and 126
  # Called by menu, print_help, show_marks etc
  # You may pass valid chars or ints so it only returns on pressing those.
  #
  # @param Array of lines to print which may be formatted using :tmux format
  # @return character pressed (ch.chr)
  # @return nil if escape or C-q pressed
  #
  def padpopup list, config={}, &block
    max_visible_items = config[:max_visible_items]
    row = config[:row] || 5
    col = config[:col] || 5
    # format options are :ansi :tmux :none
    fmt = config[:format] || :tmux
    config.delete :format
    relative_to = config[:relative_to]
    if relative_to
      layout = relative_to.form.window.layout
      row += layout[:top]
      col += layout[:left]
    end
    config.delete :relative_to
    # still has the formatting in the string so length is wrong.
    #longest = list.max_by(&:length)
    width = config[:width] || 60
    if config[:title]
      width = config[:title].size + 2 if width < config[:title].size
    end
    height = config[:height]
    height ||= [max_visible_items || 25, list.length+2].min 
    #layout(1+height, width+4, row, col) 
    layout = { :height => 0+height, :width => 0+width, :top => row, :left => col } 
    window = VER::Window.new(layout)
    form = RubyCurses::Form.new window

    ## added 2013-03-13 - 18:07 so caller can be more specific on what is to be returned
    valid_keys_int = config.delete :valid_keys_int
    valid_keys_char = config.delete :valid_keys_char

    listconfig = config[:listconfig] || {}
    #listconfig[:list] = list
    listconfig[:width] = width
    listconfig[:height] = height
    #listconfig[:selection_mode] ||= :single
    listconfig.merge!(config)
    listconfig.delete(:row); 
    listconfig.delete(:col); 
    # trying to pass populists block to listbox
    lb = RubyCurses::TextPad.new form, listconfig, &block
    if fmt == :none
      lb.text(list)
    else
      lb.formatted_text(list, fmt)
    end
    #
    #window.bkgd(Ncurses.COLOR_PAIR($reversecolor));
    form.repaint
    Ncurses::Panel.update_panels
    if valid_keys_int.nil? && valid_keys_char.nil?
      # changed 32 to 33 so space can scroll list
      valid_keys_int = (33..126)
    end

    begin
      while((ch = window.getchar()) != 999 )

        # if a char range or array has been sent, check if the key is in it and send back
        # else just stay here
        if valid_keys_char
          if ch > 32 && ch < 127
            chr = ch.chr
            return chr if valid_keys_char.include? chr
          end
        end

        # if the user specified an array or range of ints check against that
        # therwise use the range of 33 .. 126
        return ch.chr if valid_keys_int.include? ch

        case ch
        when ?\C-q.getbyte(0)
          break
        else
          if ch == 13 || ch == 10
            s = lb.current_value.to_s # .strip #if lb.selection_mode != :multiple
            return s
          end
          # close if escape or double escape
          if ch == 27 || ch == 2727
            return nil
          end
          lb.handle_key ch
          form.repaint
        end
      end
    ensure
      window.destroy  
    end
    return nil
  end
  # Taken from cygnus, bin/cygnus. also see tui.rb for various other routines
  #
# Display a file using the given renderer if any, using textpad in its own window
# It traps its own keys and closes on q and C-q. It uses backspace to open files
#  from history, and C-n/p and C-kj to go to next or prev file in underlying list.
#  Thus, it has dependencies outside what is passed in ($view and $visited_files)
# A more reusable version of this, should probably take a hash with key and method
# to run.
#
#pad_display_file filename, renderer, config={}, &block
def padview what, config={}, &block
  row = config[:row] || 0
  col = config[:col] || 0
  width = config[:width] || FFI::NCurses.COLS
  height = config[:height]
  height ||= FFI::NCurses.LINES - 1
  #layout(1+height, width+4, row, col) 
  layout = { :height => 0+height, :width => 0+width, :top => row, :left => col } 
  window = VER::Window.new(layout)
  form = RubyCurses::Form.new window

  # maintain a stack of rowids so we can backspace through them
  #@file_stack << fn unless @file_stack.include? fn
  fn = rowid
  $visited_files << fn unless $visited_files.include? fn

  listconfig = config[:listconfig] || {}
  #listconfig[:list] = list
  listconfig[:width] = width
  listconfig[:height] = height
  #listconfig[:selection_mode] ||= :single
  listconfig.merge!(config)
  listconfig.delete(:row); 
  listconfig.delete(:col); 
  #listconfig[:filename] = filename
  listconfig[:title] = filename
  listconfig[:row] = 0
  listconfig[:col] = 0
  lb = RubyCurses::TextPad.new form, listconfig, &block
  #lb.renderer renderer if renderer
  #lb.filename(filename, method(:get_file_contents))
  
  #table = "movies_back"
  #columns, *rows = $db.execute "select rowid, * from #{table} where rowid = #{rowid}"
  #list = rows[0]

  lb.text(what)
  #lb.formatted_text(alist, :tmux)
  #
  #window.bkgd(Ncurses.COLOR_PAIR($reversecolor));
  form.repaint
  Ncurses::Panel.update_panels

  begin
    while((ch = window.getchar()) != 999 )

      # we need to show bindings if user does ? or M-?
      case ch

      when ?\C-j.getbyte(0), ?\C-n.getbyte(0)
        # jump to next file so user does not need to go out and in again
        $cursor += 1
        if $view[$cursor]
          _f = $view[$cursor]
          lb.text(get_file_contents(_f))
          lb.title(_f)
          form.repaint
          next
        end

      when ?\C-k.getbyte(0), ?\C-p.getbyte(0)
        # jump to previous file so user does not need to go out and in again
        $cursor -= 1
        if $view[$cursor]
          _f = $view[$cursor]
          lb.text(get_file_contents(_f))
          lb.title(_f)
          form.repaint
          next
        end
      when ?q.getbyte(0), ?\C-q.getbyte(0), 13, 10, 27, 2727
        # close window on q or enter or double escape
        break
      when 127
        # hitting backspace cycles through list of files viewed
        # FIXME first time we have to hit BS 2 times since we get same file we are viewing
        _f = $visited_files.pop
        if _f
          # push it to first
          $visited_files.insert 0, _f
          #lb.filename(_f)
          lb.text(get_file_contents(_f))
          form.repaint
          next
        else
          #alert "No file to pop"
        end

      else
        lb.handle_key ch
        form.repaint
      end
    end
  ensure
    window.destroy  
  end
  return nil
end
