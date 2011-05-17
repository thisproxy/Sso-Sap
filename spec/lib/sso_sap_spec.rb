require 'spec_helper'

describe SsoSap::Authenticate do

	describe "self.initialize(options={})" do
		it "should initialize with the given options" do
		  init_hash = SsoSap::Authenticate.initialize(auth_options)
		  init_hash[:dev_mode].should == auth_options[:dev_mode]
		  init_hash[:session].should ==	auth_options[:session]
		  init_hash[:ticket].should ==	auth_options[:ticket]
		end
		
		it "should fall back to default when no options are given" do
		  init_hash = SsoSap::Authenticate.initialize({})
		  init_hash[:dev_mode].should == false
		  init_hash[:session].should ==	true
		  init_hash[:ticket].should ==	true
		end
		
		it "should take a user model as a string" do
		  init_hash = SsoSap::Authenticate.initialize(auth_options)
			init_hash[:user_model].should == "User"
		end
	
	#User.where(:uid => uid).first
	#User.find_from_hash(user_hash) || User.create_from_hash!(user_hash)
	# find_from_hash == User.where(:uid => hash['uid']).first
	
		it "should take a create from hash method" do
		  init_hash = SsoSap::Authenticate.initialize(auth_options)
			init_hash[:user_create_method].should == "create_from_hash!"
		end
		
		it "should take a find from hash method" do
		  init_hash = SsoSap::Authenticate.initialize(auth_options)
			init_hash[:user_find_method].should == "find_from_hash"
		end
	end
	
	
	describe "self.authentication_options" do
	  it "should return the initialized authentication options" do
			SsoSap::Authenticate.initialize(auth_options)
			init_hash = SsoSap::Authenticate.auth_options
			init_hash.should be_instance_of(Hash)
		  init_hash[:dev_mode].should == auth_options[:dev_mode]
		  init_hash[:session].should ==	auth_options[:session]
		  init_hash[:ticket].should ==	auth_options[:ticket]
	    
	  end
	
	end
	
	before(:each) do
		@dummy = FooController.new
		@dummy.extend(SsoSap::Authenticate::InstanceMethods)
		 
		@dummy.session = {}
		@dummy.flash = { :error => "", :warn => "", :info => ""  }
		@dummy.request = Object.new
		@fake_user = User.new(:first_name => "Ayumi", :last_name => "Hamasaki", :uid => "D1231331")
	end

	describe "current_user" do
		
		context "as a logged out user" do
			it "should login with fake with an existing user" do
				SsoSap::Authenticate.initialize({ :dev_mode => true })
				Rails.stubs(:env).returns("development")
				User.stubs(:find_from_hash).returns(@fake_user)
				@dummy.expects(:login_with_session).never
				@dummy.expects(:login_with_ticket).never
				@dummy.current_user
				@dummy.session[:uid].should == @fake_user.uid
				@dummy.logged_in?.should be_true
			end
					
			it "should login with session" do
				SsoSap::Authenticate.initialize({ :session => true })
				Rails.stubs(:env).returns("production")
				User.stubs(:where).returns([@fake_user])
				@dummy.expects(:login_with_fake).never
				@dummy.expects(:login_with_ticket).never
				@dummy.current_user
				@dummy.session[:uid].should == @fake_user.uid
				@dummy.logged_in?.should be_true
			end
			
			it "should login with ticket for an existing user" do
				Rails.stubs(:env).returns("production")
				SsoSap::Authenticate.initialize({ :ticket => true, :session => false })
				@dummy.expects(:login_with_fake).never
				@dummy.expects(:login_with_session).never
				@dummy.request.stubs(:env).returns({'HTTP_SSL_CLIENT_VERIFY' => 'SUCCESS', 'HTTP_SSL_CLIENT_S_DN' => "CN=#{@fake_user.uid}"})
				User.stubs(:where).returns([@fake_user])
				@dummy.current_user
				@dummy.session[:uid].should == @fake_user.uid
				@dummy.logged_in?.should be_true
			end
			
			it "should login with ticket for a new user" do
				fake_user = User.new(:uid => "D1312414", :first_name => "Alice", :last_name => "Cooper")
					
				Rails.stubs(:env).returns("production")
				SsoSap::Authenticate.initialize({ :ticket => true, :session => false })

				@dummy.expects(:login_with_fake).never
				@dummy.expects(:login_with_session).never
				@dummy.request.stubs(:env).returns({'HTTP_SSL_CLIENT_VERIFY' => 'SUCCESS', 'HTTP_SSL_CLIENT_S_DN' => "CN=#{@fake_user.uid}"})
				User.stubs(:where).returns([])
				User.stubs(:create_from_hash!).returns(fake_user)
				SsoSap::LdapStore.stubs(:find_user_with_ticket).returns({:uid => "D1312414", :first_name => "Alice", :last_name => "Cooper"})
				@dummy.current_user
				@dummy.session[:uid].should == fake_user.uid
				@dummy.logged_in?.should be_true
			end
			
			
			it "should return nil if everything went downhill" do
				SsoSap::Authenticate.initialize({ :ticket => false, :session => false, :dev_mode => false })
				@dummy.expects(:login_with_fake).never
				@dummy.expects(:login_with_ticket).never
				@dummy.expects(:login_with_session).never
				@dummy.current_user.should be_nil
			end
		
		end
		
		context "as a logged in user" do
		  it "should return the current_user" do
		    @dummy.current_user = @fake_user
				@dummy.current_user.should == @fake_user
		  end
		end
		
	end
  
	describe "logged_in?" do
		it "should return true if a current user exists" do
		  @dummy.stubs(:current_user).returns(@fake_user)
			@dummy.logged_in?.should be_true
		end
		
		it "should return false if the current user is nil" do
		  @dummy.stubs(:current_user).returns(nil)
			@dummy.logged_in?.should be_false
		end
	end
	
	
	describe "log_in(user)" do
	  it "should assing the current user" do
	    @dummy.log_in(@fake_user)
			@dummy.current_user.should == @fake_user
	  end
	end
	
	describe "require_login" do
	  it "should redirect_to login if not logged in" do
			pending("Refactor to actually run with an ActionController test, instead of wild stubbing")
	    @dummy.stubs(:logged_in?).returns(false)
	  	@dummy.require_login
	  	response.should redirect_to :login
	  end
	
		it "should return nil if already logged in" do
	    @dummy.stubs(:logged_in?).returns(true)
			@dummy.require_login.should == nil
	  end
	end
	
	describe "login_with_session" do
	  
	end
	
	describe "login_with_fake" do
	  it "should log in with an existing fake account" do
			User.stubs(:find_from_hash).returns(@fake_user)
			@dummy.login_with_fake
			@dummy.current_user.should == @fake_user
	  end
	
		it "should create a new account if not already existent" do
			User.stubs(:find_from_hash).returns(nil)
			User.stubs(:create_from_hash!).returns(@fake_user)
			@dummy.login_with_fake
			@dummy.current_user.should == @fake_user
		end
	end
	
	describe "login_with_credentials(uid, password)" do
	  it "should return a hash with user information" do
			SsoSap::LdapStore.stubs(:find_user_with_credentials).returns(fake_user)
			@dummy.login_with_credentials("user_uid", "secret").should == fake_user	    
	  end
	end
	
	
	describe "login_with_ticket" do
		it "should log a user on with using a ticket" do
		  fake_user = User.new(:uid => "D1312414", :first_name => "Alice", :last_name => "Cooper")					
	
			@dummy.request.stubs(:env).returns({'HTTP_SSL_CLIENT_VERIFY' => 'SUCCESS', 'HTTP_SSL_CLIENT_S_DN' => "CN=#{@fake_user.uid}"})
			User.stubs(:where).returns([])
			User.stubs(:create_from_hash!).returns(fake_user)
			SsoSap::LdapStore.stubs(:find_user_with_ticket).returns({:uid => "D1312414", :first_name => "Alice", :last_name => "Cooper"})
			@dummy.login_with_ticket
			@dummy.session[:uid].should == fake_user.uid
			@dummy.logged_in?.should be_true
		end
		
		it "should raise an exception if creat_from_hash! failed" do
		  fake_user = User.new(:uid => "D1312414", :first_name => "Alice", :last_name => "Cooper")						
	
			@dummy.request.stubs(:env).returns({'HTTP_SSL_CLIENT_VERIFY' => 'SUCCESS', 'HTTP_SSL_CLIENT_S_DN' => "CN=#{@fake_user.uid}"})
			User.stubs(:where).returns([])
			User.stubs(:create_from_hash!).returns(RuntimeError.new("User couldn't be created!"))
			SsoSap::LdapStore.stubs(:find_user_with_ticket).returns({:uid => "D1312414", :first_name => "Alice", :last_name => "Cooper"})
			@dummy.login_with_ticket.should be_false
		end
	end
	
	describe "current_user=(user)" do
	  it "should set the current_user" do
	    @dummy.current_user = @fake_user
			@dummy.session[:uid].should == @fake_user.uid
			@dummy.current_user.should == @fake_user
	  end
	end
	
end


def auth_options
	{
		:dev_mode => true,
		:session => false,
		:ticket => false,
		:user_model => "User",
		:user_create_method => "create_from_hash!"
	}
end

def fake_user
	{ :name => "Ayumi" , :uid => "D1231331", :last_name => "Hamasaki" }
end


