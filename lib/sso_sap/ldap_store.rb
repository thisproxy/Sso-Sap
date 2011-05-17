module SsoSap
	class LdapStore

		# Initialize the LDAP connection
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

		# Takes a user's uid and a user password
		# After successful retrieving the dn, tries to authenticate the user with
		# a given password and retrieved dn entry
		# If successful returns a user attribute hash, otherwise false
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

		# Takes a user's uid
		# Finds a user with a valid certificate with the help of the uid
		# If successful returns a user attribute hash, otherwise false
		def self.find_user_with_ticket(uid)
			filter = Net::LDAP::Filter.eq(@uid_key, uid)		
		
			@ldap.search(:base => @base, :filter => filter, :limit => 1) do |entry|
				return to_hash(entry)           
			end
			false
		end

		private

		# assigns the returned ldap values to a predefined hash
		# Net::LDAP::Entry returns values as an array, so we have
		# to convert to a string first.
		def self.to_hash(entry)
    	Hash[*
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
			}.map{|k,v| [k,v.to_a.first]}.flatten]
		end	

	end
end
