require "sso_sap/ldap_store"
require "sso_sap/authenticate"
require "sso_sap/version"


class ActionController::Base
  include SsoSap::Authenticate::InstanceMethods
end