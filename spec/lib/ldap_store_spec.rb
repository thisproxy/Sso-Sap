require 'spec_helper'
require 'ldap_store'
require 'rails'

describe LdapStore do

	describe "self.initialize" do
		it "should initialize a new LDAP connection" do
			LdapStore.send(:initialize, ldap_options)
		end
		
		it "should return nil when the parameters are not sufficient" do
		  LdapStore.send(:initialize, {}).should be_nil
		end
	  
	end
	
	describe "self.find_user_with_credentials(uid, password)" do
	  context "provided credentials are valid" do
	    it "should return a user account hash" do
				LdapStore.send(:initialize, ldap_options)
				Net::LDAP.any_instance.stubs(:bind).returns( true )				
				Net::LDAP.any_instance.expects(:search).yields(ldap_entry)
				Net::LDAP.any_instance.expects(:search).yields(ldap_entry)				
				user_hash = LdapStore.find_user_with_credentials(credentials["uid"], credentials["password"])
				user_hash.should be_instance_of(Hash)
				user_hash["uid"].should == [ldap_user_hash["uid"]]
				user_hash["name"].should == [ldap_user_hash["name"]]
				
		  end
	  end
	
		context "provided credentials are invalid" do
		  it "should return false" do
		    LdapStore.send(:initialize, ldap_options)
				Net::LDAP.any_instance.stubs(:bind).returns( true )	
				Net::LDAP.any_instance.stubs(:bind).returns( false )				
				Net::LDAP.any_instance.expects(:search).yields(ldap_entry)		
				user_hash = LdapStore.find_user_with_credentials(credentials["uid"], credentials["password"])
				user_hash.should == false
		  end
		end
	end	
	
	describe "self.find_user_with_ticket" do
	  it "should return a user account hash" do
			LdapStore.send(:initialize, ldap_options)
			Net::LDAP.any_instance.stubs(:search).yields( ldap_entry )
			user_hash = LdapStore.find_user_with_ticket(credentials["uid"])
			user_hash.should be_instance_of(Hash)
			user_hash["uid"].should == [ldap_user_hash["uid"]]
			user_hash["name"].should == [ldap_user_hash["name"]]
	  end
	end
	
	describe "self.to_hash" do
	  it "should map the given values into a hash" do
	    user_hash = LdapStore.to_hash( ldap_entry )
			user_hash.each do |key, value|
				user_hash[key].should == [ldap_user_hash[key]]
			end
	  end
	end
	
end

def credentials
	{
		"uid" => "D007",
		"password" => "roflcopter"
	}
end

def ldap_entry
	entry = Net::LDAP::Entry.new(ldap_options["base"])
	entry[:cn] 					= ldap_user_hash['uid'] 
	entry[:displayname]	= ldap_user_hash['name'] 
	entry[:name]				= ldap_user_hash['nickname'] 
	entry[:givenname]		= ldap_user_hash['first_name'] 
	entry[:sn]					= ldap_user_hash['last_name'] 
	entry[:description]	= ldap_user_hash['department'] 
	entry[:l]						= ldap_user_hash['city'] 
	entry[:co]					= ldap_user_hash['country'] 
	entry[:company]			= ldap_user_hash['company'] 
	entry[:postalcode]	= ldap_user_hash['zip_code'] 
	entry[:mail]				= ldap_user_hash['email']
	entry[:dn]					= "dc=2342342, sap=24411111, we=asdfasf" 
	entry
end

def ldap_user_hash
	{
		'uid'     	  => "D008",
		'name'        => "bruce",
		'nickname'    => "hulk",
		'first_name'  => "bruce",
		'last_name'   => "banner",
		'department'  => "superhero",
		'city'				=> "moving around",
		'country'			=> "u.s.a.",
		'company'			=> "unemployed",
		'zip_code'		=> "none",
		'email'				=> "dont.make.me.mad@hulk.com"
	}
end

def ldap_options
	{ 
		"host" => "my.awesome.ldap.host.name",
  	"port" => 389,
  	"method" => :simple,
  	"uid" => 'fancyboy',
  	"base" => 'dc=some,dc=any',
  	"bind_dn" => 'Jim',
  	"password" => 'knopf123'
	}
end

