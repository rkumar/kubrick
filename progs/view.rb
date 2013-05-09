#!/usr/bin/env ruby

# DESC: View data of movies table.
#
# - edit values and save in table - currently only screen shows edit
# - reload data on some key
# - view plot and intro on some key
# - show imdbtop 100 on a key in a sepa window that can be reused.
# - when viewing wiki info be able to backtab to history
# Using tablewidget with sqlite3 resultset
# TODO : make columns hidden on key - toggle, how to get back then
# TODO : move column position
# TODO : filter column
# TODO : menu on C-x to delete a column, hide unhide expand etc, use pad menu
require 'logger'
require 'rbcurse'
require 'rbcurse/experimental/widgets/tablewidget'
require 'sqlite3'
require 'kubrick'
require 'kubrick/commons'

#
$table = "movie"

      BESTPIC = 6
      BESTFOR = 10
      CANNES = 11
def get_db
  dbname = "movie.sqlite"
  raise unless File.exists? dbname
  $db = SQLite3::Database.new(dbname)
end
get_db

def get_data
  table = $table
  #sql = "select rowid,* from #{table}"
  sql = "select rowid,title, directed_by, year, won , nom , best_pic as bp, best_director as bd, best_actor as ba, best_cinemato as bc, best_foreign as bf, palme, goldenbear as gb, goldenlion as gl from #{table} order by title"
  # i am moving away from execute2 since it returns ArraywithTypeAndFields which screws up
  # soeting and searching
  #$columns, *rows = $db.execute2(sql)
  q = $db.query(sql + " limit 1 ")
  $columns = q.columns
  content = $db.execute(sql)
  #content = rows
  return nil if content.nil? || content[0].nil?
  #$datatypes = content[0].types #if @datatypes.nil?
  return content
end
def get_full_row tw
  row = tw.current_value
  rowid = row[0]
  table = $table
  sql = "select rowid,* from #{table} where rowid = #{rowid}"
  columns, *rows = $db.execute2(sql)
  content = rows
  return nil if content.nil? || content[0].nil?
  datatypes = content[0].types #if @datatypes.nil?
  return columns, content
end
def view_row tw
  row = tw.current_value
  rowid = row[0]
  c, r = get_full_row tw
  list = []
  r[0].each_with_index do |rr, i|
    list << "%20s : %s " % [ c[i], rr ]
  end
  padview list
end
def view_wiki tw
  row = tw.current_value
  rowid = row[0]
  url = $db.get_first_value "select url from #{$table} where rowid = #{rowid}"
  wiki = $db.get_first_value "select wiki from movie_wiki where url = '#{url}'"
  File.open("tmp.html","w") { |f| f.write(wiki) }
  text = `w3m -dump -T 'text/html' tmp.html `
  padview text.split "\n"
end

def edit_row tw
  row = tw.current_value
  rowid = row[0]
  h   = %w{ title directed_by year nom won }
  c = h.join ","
  dbrow = $db.get_first_row "select #{c} from #{$table} where rowid = #{rowid}"
  buffer = []
  dbrow.each_with_index do |v, ix|
    buffer << v
  end
  _edit h, dbrow, " Edit "
  dbrow.each_with_index do |v, ix|
    oldval = buffer[ix]
    if v != oldval
      if oldval.nil? && v == ""
      else
        alert "modified #{ix} (#{buffer[ix]}) to (#{v}) "
        $db.execute("update #{$table} set #{h[ix]} = ? where rowid = ? ", [v, rowid])
      end
    end
  end

  # if we try to save back to database at this point we don't know what fields
  # were actually changed, we could replace a nil with a space since that was done
  # for populating Field
  # Also. column names have been changed, so will not be able to update
  #
  # How do i change back the original row, unless we query for it and then ...
  tw.fire_row_changed tw.current_index
end
def OLDedit_row tw
  row = tw.current_value
  h   = tw.columns
  _edit h, row, " Edit "
  # if we try to save back to database at this point we don't know what fields
  # were actually changed, we could replace a nil with a space since that was done
  # for populating Field
  # Also. column names have been changed, so will not be able to update
  tw.fire_row_changed tw.current_index
end
def insert_row tw
  h   = tw.columns
  row = []
  h.each { |e| row << "" }
  ret = _edit h, row, "Insert"
  if ret
    tw.add row
    tw.fire_dimension_changed
  end
end

# making a generic edit messagebox - quick dirty
def _edit h, row, title
  _l = longest_in_list h
  _w = _l.size
  # _w can be longer than 70, assuming that screen is 70 or more
  config = { :width => 70, :title => title }
  bw = get_color $datacolor, :black, :white
  mb = MessageBox.new config do
    txt = nil
    h.each_with_index { |f, i| 
      txt = row[i] || ""
      #add Field.new :label => "%*s:" % [_w, f], :text => txt.chomp, :name => i.to_s, 
      add Field.new :label => "%*s:" % [_w, f], :text => txt, :name => i.to_s, 
        :bgcolor => :cyan,
        :display_length => 50,
        :label_color_pair => bw
    }
    button_type :ok_cancel
  end
  index = mb.run
  return nil if index != 0
  h.each_with_index { |e, i| 
    f = mb.widget(i.to_s)
    row[i] = f.text
  }
  row
end
begin
  # Initialize curses
  VER::start_ncurses  # this is initializing colors via ColorMap.setup
  path = File.join(ENV["LOGDIR"] || "./" ,"r.log")
  logfilename   = File.open(path, File::WRONLY|File::TRUNC|File::CREAT) 
  $log = Logger.new(logfilename)
  $log.level = Logger::DEBUG


  colors = Ncurses.COLORS
  back = :black
  lineback = :blue
  back = 234 if colors >= 256
  lineback = 236 if colors >= 256

  catch(:close) do
    @window = VER::Window.root_window
    @form = Form.new @window
    @form.bind_key(KEY_F1, 'help'){ display_app_help }

    header = app_header "0.0.1", :text_center => "Movie Database", :text_right =>"" , :name => "header" , :color => :white, :bgcolor => lineback , :attr => :bold 



    _col = "#[fg=yellow]"
    $message = Variable.new
    $message.value = ""
    @status_line = status_line :row => Ncurses.LINES-1 #, :bgcolor => :red, :color => :yellow
    @status_line.command {
      "#[bg=236, fg=black]#{_col}F1#[/end] Help | #{_col}?#[/end] Keys | #{_col}M-c#[/end] Ask | #{_col}M-d#[/end] History | #{_col}M-m#[/end] Methods | %20s" % [$message.value]
    }

    h = FFI::NCurses.LINES-2
    w = FFI::NCurses.COLS
    r = 1
    #header = %w[ Pos Last Title Director Year Country Mins BW]
    #file = "movies1000.txt"

    arr = get_data
    tv = RubyCurses::TableWidget.new @form, :row => 1, :col => 0, :height => h, :width => w, :name => "tv", :suppress_borders => false do |b|

      b.resultset $columns, arr

      b.model_row 1
      b.column_width 0, 5
      #b.get_column(2).color = :red
      #b.get_column(3).color = :yellow
      #b.get_column(2).bgcolor = :blue
      #b.column_align 6, :right
      #b.column_width 2, b.calculate_column_width(2)
      b.column_width 1, 50
      b.column_width 2, 25
      b.column_width 3, 5
      b.column_width 4, 4
      #b.column_hidden 1, true
    end
    mcr = RubyCurses::DefaultTableRenderer.new tv
    mcr.header_colors :white, :red

    # override render_data so we can display certain lines in bold
    # or with a colored background
    def mcr.render_data pad, lineno, data
      text = data.join
      cp = @color_pair
      att = @attrib
      # movies that have won best picture
      if data[BESTPIC].strip() == "W"
        att = BOLD
      end
      # movies that have won best picture
      if data[BESTPIC].strip() == "W"
        cp = get_color($datacolor, :white, :blue)
      elsif data[BESTPIC].strip() == "N"
        # movies that have been nominated for best picture
        cp = get_color($datacolor, :white, 236)
      elsif data[BESTFOR].strip() == "W" || data[CANNES].strip() == "W"
        # movies that have won best foreign film or Cannes (palme d or)
        cp = get_color($datacolor, :white, 234)
      end
      FFI::NCurses.wattron(pad,FFI::NCurses.COLOR_PAIR(cp) | att)
      FFI::NCurses.mvwaddstr(pad, lineno, 0, text)
      FFI::NCurses.wattroff(pad,FFI::NCurses.COLOR_PAIR(cp) | att)
    end
    tv.renderer mcr
    mcr.column_model ( tv.column_model )
    tv.create_default_sorter
    #tv.move_column 1,-1

    # pressing ENTER on a method name will popup details for that method
    tv.bind(:PRESS) { |ev|
      if @current_index > 0
        w = ev.word_under_cursor.strip
        w = ev.text
      # the curpos does not correspond to the formatted display, this is just the array
      # without the width info XXX
        alert "#{ev.current_index}, #{ev.curpos}: #{w}"
      end
    }
    tv.bind_key(?v) { view_row(tv) }
    tv.bind_key(?x) { view_wiki(tv) }
    tv.bind_key(?e) { edit_row(tv) }
    tv.bind_key(?i) { insert_row(tv) }
    tv.bind_key(?D) { tv.delete_at tv.current_index }
    @form.bind_key(?\M-c, "Filter") {
      tv = @form.by_name["tv"]; 
      str = get_string "Enter name of director:"
      if str && str.length > 0
      m = tv.matching_indices do |ix, fields|
        fields[3] =~ /#{str}/i
      end
      else
        tv.clear_matches
      end
    }


    $message.value = "#{tv.current_index}: #{tv.lastrow}, #{tv.lastcol}"
    @form.repaint
    @window.wrefresh
    Ncurses::Panel.update_panels
    while((ch = @window.getchar()) != KEY_F10 )
      break if ch == ?q.ord || ch == ?\C-q.getbyte(0)
      @form.handle_key(ch)
      $message.value = "#{tv.current_index}: #{tv.lastrow}, #{tv.lastcol}"
      @window.wrefresh
    end
  end
rescue => ex
  textdialog ["Error in view: #{ex} ", *ex.backtrace], :title => "Exception"
  $log.debug( ex) if ex
  $log.debug(ex.backtrace.join("\n")) if ex
ensure
  @window.destroy if !@window.nil?
  VER::stop_ncurses
  p ex if ex
  p(ex.backtrace.join("\n")) if ex
end
  # a test renderer to see how things go
