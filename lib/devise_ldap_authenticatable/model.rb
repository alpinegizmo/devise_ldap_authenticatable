require 'devise_ldap_authenticatable/strategy'

module Devise
  module Models
    # LDAP Module, responsible for validating the user credentials via LDAP.
    #
    # Examples:
    #
    #    User.authenticate('email@test.com', 'password123')  # returns authenticated user or nil
    #    User.find(1).valid_password?('password123')         # returns true/false
    #
    module LdapAuthenticatable
      extend ActiveSupport::Concern

      included do
        attr_reader :current_password, :password
        attr_accessor :password_confirmation
      end

      def login_with
        read_attribute(::Devise.authentication_keys.first)
      end

      # Checks if a resource is valid upon authentication.
      def valid_ldap_authentication?(password)
        Devise::LdapAdapter.valid_credentials?(login_with, password)
      end
      
      def ldap_groups
        Devise::LdapAdapter.get_groups(login_with)
      end
      
      def ldap_dn
        Devise::LdapAdapter.get_dn(login_with)
      end

      module ClassMethods
        # Authenticate a user based on configured attribute keys. Returns the
        # authenticated user if it's valid or nil.
        def authenticate_with_ldap(attributes={}) 
          @login_with = ::Devise.authentication_keys.first
          return nil unless attributes[@login_with].present? 
          
          # resource = find_for_ldap_authentication(conditions)
          # resource = where(@login_with => attributes[@login_with]).first
          resource = find(:first, :conditions => {@login_with => attributes[@login_with]})
                    
          if (resource.blank? and ::Devise.ldap_create_user)
            resource = self.new
            resource[@login_with] = attributes[@login_with]
            resource.password = attributes[:password]
            resource.is_ldap = true
          end
                    
          if resource.try(:valid_ldap_authentication?, attributes[:password])
            resource.save! if resource.new_record?
            return resource
          else
            return nil
          end
        end
        
      end

    end
  end
end
