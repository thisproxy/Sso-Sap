module SsoSap
	module Authenticate
		
		def self.initialize(options={})
			logger = Logger.new(STDOUT)
			logger.level = Logger::INFO
			@auth_options = {
				:dev_mode => false,
				:session => true,
				:ticket => true,
				:user_model => "User",
				:user_create_method => "create_from_hash!",
				:user_find_method => "find_from_hash",
				:logger => logger
			}.update(options)
		end

		def self.auth_options
			@auth_options
		end

		module InstanceMethods
			def current_user
				auth_options = SsoSap::Authenticate.auth_options
				return @current_user unless @current_user.blank?
		
				login_with_fake    if Rails.env.eql?("development") && auth_options[:dev_mode]
				login_with_session if auth_options[:session] && @current_user.blank?
				login_with_ticket  if auth_options[:ticket] && @current_user.blank?
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
				auth_options = SsoSap::Authenticate.auth_options
				auth_options[:logger].info "Trying to login with session information..."
				user = User.where(:uid => session[:user_id]).first
				self.current_user = user unless user.nil?
				auth_options[:logger].info "Login via session: #{user.nil? ? "failed" : "succeeded"}"
			end


			def login_with_fake
				auth_options = SsoSap::Authenticate.auth_options
				auth_options[:logger].info "Logging in with fake user"

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
				#self.current_user = User.find_from_hash(user_hash) || User.create_from_hash!(user_hash)
				self.current_user =  eval(auth_options[:user_model]).send(auth_options[:user_find_method], user_hash) || eval(auth_options[:user_model]).send(auth_options[:user_create_method], user_hash)
			end

			def login_with_credentials(uid, password)
				user_hash = SsoSap::LdapStore.find_user_with_credentials(uid, password)
			end

			def login_with_ticket
				auth_options = SsoSap::Authenticate.auth_options
				auth_options[:logger].info "Trying to login with SSL_CLIENT_S_DN header"
				raise "Ticket Validation failed" unless request.env['HTTP_SSL_CLIENT_VERIFY'] == 'SUCCESS'
				raise "Couldn't find DN header'" unless request.env['HTTP_SSL_CLIENT_S_DN']  
				uid = request.env['HTTP_SSL_CLIENT_S_DN'].match('CN=(.*)')[1]
				raise "Couldn't parse the DN header'" unless uid

				auth_options[:logger].info "Found user #{uid} in the headers. Checking if the user exists already now..."
				user = User.where(:uid => uid).first

				unless user
					auth_options[:logger].info "New user. Fetching details for #{uid} from LDAP..."

					user_hash = SsoSap::LdapStore.find_user_with_ticket(uid) 

					if user_hash
						auth_options[:logger].info "Creating user for #{user_hash['displayname']}"
						user = User.create_from_hash!(user_hash)
					end
				end

				self.current_user = user unless user.nil? 

			rescue Exception => e
				auth_options[:logger].info e.inspect
				false
			end

			def current_user=(user)
				auth_options = SsoSap::Authenticate.auth_options
				auth_options[:logger].info "Logging in as #{user.first_name} #{user.last_name}"
				@current_user = user
				session[:uid] = user.uid
			end
		end

	end
end