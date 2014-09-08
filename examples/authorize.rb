require_relative '../lib/dropbox/client'
require_relative '../lib/dropbox/oauth2'
require_relative '../lib/dropbox/web_auth_no_redirect'
require_relative '../lib/dropbox/oauth2/app_info'
require_relative '../lib/dropbox/client/host_info'
require_relative '../lib/dropbox/client/session'
require_relative '../lib/dropbox'
require_relative '../lib/dropbox/http'
require_relative '../lib/dropbox/error'
require 'pp'
require 'shellwords'

####
# An example app using the Dropbox API Ruby Client
#   This ruby script sets up a basic command line interface (CLI)
#   that prompts a user to authenticate on the web, then
#   allows them to type commands to manipulate their dropbox.
####

# TODO take my test data out
# TODO https://www.dropbox.com/developers/core/start/ruby mirror code

# You must use your Dropbox App key and secret to use the API.
# Find this at https://www.dropbox.com/developers

class DropboxCLI
  LOGIN_REQUIRED = %w{put get cp mv rm ls mkdir info logout search thumbnail}

  def initialize
    begin
      @app_info = Dropbox::API::AppInfo.from_json_file('app_info.json')
      if @app_info.key == '' || @app_info.secret == ''
        fail
      end
    rescue
      puts "You must set your app key and app secret in app_info.json!"
      puts "Find this in your apps page at https://www.dropbox.com/developers/"
      exit
    end
    @client = nil
  end

  def login
    if not @client.nil?
      puts "already logged in!"
    else
      web_auth = Dropbox::API::WebAuthNoRedirect.new(@app_info, 'RubySDK/2.0')
      authorize_url = web_auth.start()
      puts "1. Go to: #{authorize_url}"
      puts "2. Click \"Allow\" (you might have to log in first)."
      puts "3. Copy the authorization code."

      print "Enter the authorization code here: "
      STDOUT.flush
      auth_code = STDIN.gets.strip

      access_token, user_id = web_auth.finish(auth_code)

      @client = Dropbox::API::Client.new(access_token, 'RubySDK/2.0', nil, @app_info.host_info)
      puts "You are logged in.  Your access token is #{access_token}."
    end
  end

  def command_loop
    puts "Enter a command or 'help' or 'exit'"
    command_line = ''
    while command_line.strip != 'exit'
      begin
        execute_dropbox_command(command_line)
      rescue RuntimeError => e
        puts "Command Line Error! #{e.class}: #{e}"
        puts e.backtrace
      end
      print '> '
      command_line = gets.strip
    end
    puts 'goodbye'
    exit(0)
  end

  def execute_dropbox_command(cmd_line)
    command = Shellwords.shellwords cmd_line
    method = command.first
    if LOGIN_REQUIRED.include? method
      if @client
        send(method.to_sym, command)
      else
        puts 'must be logged in; type \'login\' to get started.'
      end
    elsif ['login', 'help'].include? method
      send(method.to_sym)
    else
      if command.first && !command.first.strip.empty?
        puts 'invalid command. type \'help\' to see commands.'
      end
    end
  end

  def logout(command)
    @client = nil
    puts "You are logged out."
  end

  def files_folder_list(command)
    command[1] = '/' + clean_up(command[1] || '')
    resp = @client.files.folder_list(command[1])

    if resp['contents'].length > 0
      for item in resp['contents']
        puts item['path']
      end
    end
  end

  def files_info(command)
    if !command[1] || command[1].empty?
      puts "please specify item to get"
    else
      src = clean_up(command[1])
      metadata = @client.files.info('/' + src)
      puts "Metadata:"
      pp metadata
    end
  end

  def files_download(command)
    dest = command[2]
    if !command[1] || command[1].empty?
      puts "please specify item to get"
    elsif !dest || dest.empty?
      puts "please specify full local path to dest, i.e. the file to write to"
    elsif File.exists?(dest)
      puts "error: File #{dest} already exists."
    else
      src = clean_up(command[1])
      out, metadata = @client.files.download('/' + src)
      puts "Metadata:"
      pp metadata
      open(dest, 'w'){|f| f.puts out }
      puts "wrote file #{dest}."
    end
  end

  def files_upload(command)
    fname = command[1]

    #If the user didn't specifiy the file name, just use the name of the file on disk
    if command[2]
      new_name = command[2]
    else
      new_name = File.basename(fname)
    end

    if fname && !fname.empty? && File.exists?(fname) && (File.ftype(fname) == 'file') && File.stat(fname).readable?
      pp @client.files.upload(new_name, WriteConflictPolicy.overwrite, open(fname))
    else
      puts "couldn't find the file #{ fname }"
    end
  end

  def files_folder_create(command)
    pp @client.files.folder_create(clean_up(command[1]))
  end

  def files_preview(command)
    dest = command[2]
    command[3] ||= 'small'
    out,metadata = @client.thumbnail_and_metadata(command[1], command[3])
    puts "Metadata:"
    pp metadata
    open(dest, 'w'){|f| f.puts out }
    puts "wrote thumbnail#{dest}."
  end

  # Example:
  # > thumbnail pic1.jpg ~/pic1-local.jpg large
  def files_thumbnail(command)
    dest = command[2]
    command[3] ||= 'small'
    out,metadata = @client.thumbnail_and_metadata(command[1], command[3])
    puts "Metadata:"
    pp metadata
    open(dest, 'w'){|f| f.puts out }
    puts "wrote thumbnail#{dest}."
  end

  def files_copy(command)
    src = clean_up(command[1])
    dest = clean_up(command[2])
    pp @client.files.copy(src, dest)
  end

  def files_move(command)
    src = clean_up(command[1])
    dest = clean_up(command[2])
    pp @client.files.move(src, dest)
  end

  def files_delete(command)
    pp @client.files.delete(clean_up(command[1]))
  end

  def files_search(command)
    resp = @client.search('/', clean_up(command[1]))

    for item in resp
      puts item['path']
    end
  end

  def users_info(command)
    pp @client.users.info('me')
  end

  def help
    puts "commands are: login #{LOGIN_REQUIRED.join(' ')} help exit"
  end

  def clean_up(str)
    str ? str.gsub(/^\/+/, '') : nil
  end
end

cli = DropboxCLI.new
cli.command_loop
