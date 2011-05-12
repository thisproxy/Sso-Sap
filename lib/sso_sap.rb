require "ldap_store"
require "rails"

module SsoSap
	
	def self.initialize(options={})
		@authenticate_options = {
			:dev_mode => options["dev_mode"] || false,
			:session => options["session"] || true,
			:ticket => options["ticket"] || true
		}
	end
	
	def self.authentication_options
		@authenticate_options
	end
	
	module InstanceMethods
		def current_user
			authenticate_options = SsoSap.authentication_options

			return @current_user unless @current_user.blank?
			login_with_fake    if Rails.env.eql?("development") && authenticate_options[:dev_mode]
			login_with_session if authenticate_options[:session]
			login_with_ticket  if authenticate_options[:ticket]
			@current_user
		end

		def logged_in?
			!!current_user
		end

		def log_in(user)
			self.current_user = user
		end

		def require_login 
			unless logged_in? 
				flash[:error] = "You must be logged in to access this section"
				redirect_to :login
			end
		end

		def login_with_session
			Rails.logger.debug "Trying to login with session information..."
			user = User.where(:uid => session[:user_id]).first
			self.current_user = user unless user.nil?
			Rails.logger.debug "Login via session: #{user.nil? ? "failed" : "succeeded"}"
		end


		def login_with_fake
			Rails.logger.debug "Logging in with fake user"

			user_hash = {
				"uid" => "D004711",
				"name" => "Peter",
				"email" =>  "peter.lustig@landstreicher.de",
				"first_name" => "Peter",
				"last_name" => "Lustig",
				"location" => "berlin",
				"description" => "2sfsfddsf",
				"phone" => "234234",
				"department" => "inneres"    
			}
			self.current_user = User.find_from_hash(user_hash) || User.create_from_hash!(user_hash)
		end

		def login_with_credentials(uid, password)
			user_hash = LdapStore.find_user_with_credentials(uid, password)
		end

		def login_with_ticket
			Rails.logger.debug "Trying to login with SSL_CLIENT_S_DN header"
			raise "Ticket Validation failed" unless request.env['HTTP_SSL_CLIENT_VERIFY'] == 'SUCCESS'
			raise "Couldn't find DN header'" unless request.env['HTTP_SSL_CLIENT_S_DN']  

			uid = request.env['HTTP_SSL_CLIENT_S_DN'].match('CN=(.*)')[1]
			raise "Couldn't parse the DN header'" unless uid

			Rails.logger.debug "Found user #{uid} in the headers. Checking if the user exists already now..."
			user = User.where(:uid => uid).first

			unless user
				Rails.logger.info "New user. Fetching details for #{uid} from LDAP..."

				user_hash = LdapStore.find_user_with_ticket(uid) 

				if user_hash then
					Rails.logger.info "Creating user for #{user_hash['displayname']}"
					user = User.create_from_hash!(user_hash)
				end
			end

			self.current_user = user unless user.nil? 

		rescue Exception => e
			Rails.logger.warn e.inspect
			false
		end

		def current_user=(user)
			Rails.logger.debug "Logging in as #{user.first_name} #{user.last_name}"
			@current_user = user
			session[:uid] = user.uid
		end
	end
	
end

class ActionController::Base
  include SsoSap::InstanceMethods
end

