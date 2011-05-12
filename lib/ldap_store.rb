class LdapStore

	def self.initialize(ldap_options = {})
		@ldap = Net::LDAP.new :host => ldap_options["host"],
		:port => ldap_options["port"],
		:auth => {
			:method   => ldap_options["method"], 
			:username => ldap_options["bind_dn"],
			:password => ldap_options["password"]
		}
		@base    = ldap_options["base"] 
		@uid_key = ldap_options["uid"]
	end

	def self.find_user_with_credentials(uid, password)
		filter = Net::LDAP::Filter.eq(@uid_key, uid)

		p (@ldap.bind) ? "Authorization Succeeded! 1" : "Authorization Failed: #{@ldap.get_operation_result.message}"
		new_user_base = {}
		@ldap.search :base => @base, :filter => filter, :limit => 1 do |entry|
			new_user_base = entry[:dn].to_a.first
		end

		return false unless new_user_base.present?
		@ldap.auth(new_user_base, password)

		if @ldap.bind
			puts "[LdapStore] Authorization Succeeded!"
			@ldap.search :base => @base, :filter => filter, :limit => 1 do |entry|
				return to_hash(entry)           
			end
		end
		puts "[LdapStore] Authorization Failed: #{@ldap.get_operation_result.message}"
		false
	end

	def self.find_user_with_ticket(uid)
		filter = Net::LDAP::Filter.eq(@uid_key, uid)		
		
		@ldap.search(:base => @base, :filter => filter, :limit => 1) do |entry|
			return to_hash(entry)           
		end
		false
	end

	private

	def self.to_hash(entry)
		{
			'uid'     	  => entry[:cn],
			'name'        => entry[:displayname],
			'nickname'    => entry[:name],
			'first_name'  => entry[:givenname],
			'last_name'   => entry[:sn],
			'department'  => entry[:description],
			'city'				=> entry[:l],
			'country'			=> entry[:co],
			'company'			=> entry[:company],
			'zip_code'		=> entry[:postalcode],
			'email'				=> entry[:mail]
		}
	end	

end

