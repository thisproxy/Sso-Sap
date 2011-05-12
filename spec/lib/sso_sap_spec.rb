require 'spec_helper'
require 'sso_sap'
require 'rails'


describe SsoSap do

	describe "self.initialize(options={})" do
		it "should initialize with the given options" do
		  auth_hash = SsoSap.initialize(authentication_options)
		  auth_hash[:dev_mode].should == authentication_options["dev_mode"]
		  auth_hash[:session].should ==	authentication_options["session"]
		  auth_hash[:ticket].should ==	authentication_options["ticket"]
		end
		
		it "should fall back to default when no options are given" do
		  auth_hash = SsoSap.initialize({})
		  auth_hash[:dev_mode].should == false
		  auth_hash[:session].should ==	true
		  auth_hash[:ticket].should ==	true
		end

	end


	describe "self.authentication_options" do
	  it "should return the initialized authentication options" do
			SsoSap.initialize(authentication_options)
			auth_hash = SsoSap.authentication_options
			auth_hash.should be_instance_of(Hash)
		  auth_hash[:dev_mode].should == authentication_options["dev_mode"]
		  auth_hash[:session].should ==	authentication_options["session"]
		  auth_hash[:ticket].should ==	authentication_options["ticket"]
	    
	  end
	
	end

end


def authentication_options
	{
		"dev_mode" => true,
		"session" => false,
		"ticket" => false
	}
end


describe SsoSap::InstanceMethods do

	before(:each) do
	  @dummy = Class.new
		@dummy.includes(SsoSap::InstanceMethods)
	end

	describe "current_user" do
	  
	end
  
	describe "logged_in?" do
	  
	end


	describe "log_in(user)" do
	  
	end
	
	describe "require_login" do
	  
	end
	
	
	describe "login_with_session" do
	  
	end

	describe "login_with_fake" do
	  
	end

	describe "login_with_credentials(uid, password)" do
	  
	end
	
	describe "login_with_ticket" do
	  
	end
	
	describe "current_user=(user)" do
	  
	end

end






# 
# 
# 
# module SsoSap
# 	


# 	
# 	module InstanceMethods
# 		def current_user
# 			authenticate_options = SsoSap.authentication_options
# 
# 			return @current_user unless @current_user.blank?
# 			login_with_fake    if Rails.env.eql?("development") && authenticate_options[:dev_mode]
# 			login_with_session if authenticate_options[:session]
# 			login_with_ticket  if authenticate_options[:ticket]
# 			@current_user
# 		end
# 
# 		def logged_in?
# 			!!current_user
# 		end
# 
# 		def log_in(user)
# 			self.current_user = user
# 		end
# 
# 		def require_login 
# 			unless logged_in? 
# 				flash[:error] = "You must be logged in to access this section"
# 				redirect_to :login
# 			end
# 		end
# 
# 		def login_with_session
# 			Rails.logger.debug "Trying to login with session information..."
# 			user = User.where(:uid => session[:user_id]).first
# 			self.current_user = user unless user.nil?
# 			Rails.logger.debug "Login via session: #{user.nil? ? "failed" : "succeeded"}"
# 		end
# 
# 
# 		def login_with_fake
# 			Rails.logger.debug "Logging in with fake user"
# 
# 			user_hash = {
# 				"uid" => "D004711",
# 				"name" => "Peter",
# 				"email" =>  "peter.lustig@landstreicher.de",
# 				"first_name" => "Peter",
# 				"last_name" => "Lustig",
# 				"location" => "berlin",
# 				"description" => "2sfsfddsf",
# 				"phone" => "234234",
# 				"department" => "inneres"    
# 			}
# 			self.current_user = User.find_from_hash(user_hash) || User.create_from_hash!(user_hash)
# 		end
# 
# 		def login_with_credentials(uid, password)
# 			user_hash = LdapStore.find_user_with_credentials(uid, password)
# 		end
# 
# 		def login_with_ticket
# 			Rails.logger.debug "Trying to login with SSL_CLIENT_S_DN header"
# 			raise "Ticket Validation failed" unless request.env['HTTP_SSL_CLIENT_VERIFY'] == 'SUCCESS'
# 			raise "Couldn't find DN header'" unless request.env['HTTP_SSL_CLIENT_S_DN']  
# 
# 			uid = request.env['HTTP_SSL_CLIENT_S_DN'].match('CN=(.*)')[1]
# 			raise "Couldn't parse the DN header'" unless uid
# 
# 			Rails.logger.debug "Found user #{uid} in the headers. Checking if the user exists already now..."
# 			user = User.where(:uid => uid).first
# 
# 			unless user
# 				Rails.logger.info "New user. Fetching details for #{uid} from LDAP..."
# 
# 				user_hash = LdapStore.find_user_with_ticket(uid) 
# 
# 				if user_hash then
# 					Rails.logger.info "Creating user for #{user_hash['displayname']}"
# 					user = User.create_from_hash!(user_hash)
# 				end
# 			end
# 
# 			self.current_user = user unless user.nil? 
# 
# 		rescue Exception => e
# 			Rails.logger.warn e.inspect
# 			false
# 		end
# 
# 		def current_user=(user)
# 			Rails.logger.debug "Logging in as #{user.first_name} #{user.last_name}"
# 			@current_user = user
# 			session[:uid] = user.uid
# 		end
# 	end
# 	
# end