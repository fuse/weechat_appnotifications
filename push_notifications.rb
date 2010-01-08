require "net/https"
require "uri"

=begin
Send notifications to appnotifications (or any server specified in your
config's file).
Since API changed with Weechat 0.3 it may only work with Weechat <= 0.2.6.
=end

# Plugin initialization
def weechat_init
  Weechat.register("push_notifications", "0.1", "", "Send notifications using appnotifications REST API.")
	Weechat.add_message_handler("weechat_highlight", "highlight")
  Weechat.add_message_handler("privmsg", "pv")
  check_config ? Weechat::PLUGIN_RC_OK : Weechat::PLUGIN_RC_KO
end

# Print usage
def usage
  Weechat.print %q{
    You need the following informations in your plugins.rc:
      - ruby.push_notifications.token
  }
end

# Check that each required parameters have been found in the configuration file.
def check_config
  %w(token).each do |param|
    (usage and return false) if Weechat.get_plugin_config(param).to_s.empty?
  end
  true
end

def token
	@@token ||= Weechat.get_plugin_config("token")
end

def hostname
	hostname = Weechat.get_plugin_config("hostname")
	@@hostname = hostname.empty? ? "www.appnotifications.com" : hostname
end

def notify(message)
	begin
		http = Net::HTTP.new(hostname, 443)
		http.use_ssl = true
		response = http.post("/account/notifications.xml", "user_credentials=#{token}&notification[message]=#{message}")
		response.is_a?(Net::HTTPOK)
	rescue
		Weechat.print("An exception occured: #{$!}")
		false
	end
end

# From args contains useless information like ip address…
def extract_nickname(from)
	from =~ /^:([^!]+)/
	$1
end

def extract_args(args)
	args = args.split(/\s+/, 4)
	# remove the ':'
	args.last.slice!(0)
	args
end

# Highlight callback
def highlight(server, args)
	from, action, to, message = extract_args(args)
  notify("HL on server #{server}. From #{extract_nickname(from)}: #{message}") ?
		Weechat::PLUGIN_RC_OK :
		Weechat::PLUGIN_RC_KO
end

# Private message callback
def pv(server, args)
	from, action, to, message = extract_args(args)
  notify("PV on server #{server}. From #{extract_nickname(from)}: #{message}") ?
		Weechat::PLUGIN_RC_OK :
		Weechat::PLUGIN_RC_KO
end
