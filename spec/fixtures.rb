class User
	attr_accessor :first_name, :last_name, :uid
	
	def initialize(attributes)
		@first_name = attributes[:first_name]
		@last_name = attributes[:last_name]
		@uid = attributes[:uid]
	end
end


class FooController < ActionController::Base
	attr_accessor :session, :request, :flash
end
