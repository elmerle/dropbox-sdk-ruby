require_relative '../lib/dropbox/client'
require_relative '../lib/dropbox/oauth2'
require_relative '../lib/dropbox/web_auth_no_redirect'
require_relative '../lib/dropbox/oauth2/app_info'
require_relative '../lib/dropbox/client/host_info'
require_relative '../lib/dropbox/client/session'
require_relative '../lib/dropbox'
require_relative '../lib/dropbox/http'
require_relative '../lib/dropbox/error'
require_relative '../lib/dropbox/objects'
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
  LOGIN_REQUIRED = ['get', 'info',
                    'logout']

  def initialize
    begin
      @app_info = Dropbox::API::AppInfo.new('82yyfwr3bb64v0r', 'glxxoknkavqyslb')
      #@app_info = Dropbox::API::AppInfo.new('obbz2k49as22n3h', 'a0mh9hok45gi2th')
      if @app_info.key == '' || @app_info.secret == ''
        fail
      end
      @app_info.host_info = Dropbox::API::HostInfo.new('meta-dbdev.dev.corp.dropbox.com', 'meta-dbdev.dev.corp.dropbox.com', 'meta-dbdev.dev.corp.dropbox.com', 443)
    rescue Exception => e
      puts "#{ e.message }"
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

      #access_token, user_id = web_auth.finish(auth_code)
      #access_token = 'a4ayc_80_OEAAAAAAAAAWgM56GDj2_tV_3lFVGv6k-jF77kF_2yEamKOm-tLqRdb'
      access_token = 'a4ayc_80_OEAAAAAAAAAUtFOp8ApizZpUEX6nlDF3qCLX6QLAHWefqnTBoeJvryB'
      user_id = 1

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

  def get(command)
    pp @client.files.get_descendants(command[1])
  end

  def info(command)
    pp @client.files.info(command[1])
  end

  def help
    puts "commands are: login #{LOGIN_REQUIRED.join(' ')} help exit"
  end

  def clean_up(str)
    return str.gsub(/^\/+/, '') if str
    str
  end
end

cli = DropboxCLI.new
cli.command_loop
