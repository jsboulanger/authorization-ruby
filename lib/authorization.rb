#
# Here are a few example for Rails
#
# Activate authorization in your application controller.
#
# class ApplicationController < ActionController::Base
#   include Authorization
#   before_filter :ensure_authorization!
# 
#   ...
# end
#
# Authorize the admin for all actions:
#
# class FooController < ApplicationController
#   authorize :admin
#
#   ...
# end
#
# Authorize only specific actions:
#
# class FooController < ApplicationController
#   authorize :manager, :only => [:index, :show]
#
#   ...
# end
#
# Authorize all actions except specified ones:
#
# class FooController < ApplicationController
#   authorize :manager, :except => [:new, :create]
#
#   ...
# end#
#
# You can also specify multiple roles:
#
# class FooController < ApplicationController
#   authorize [:admin, :manager]
#
#   ...
# end
#
# To authorize a controller's actions for all user included not logged in
#
# class FooController < ApplicationController
#   authorize :public
#
#   ...
# end
#
# You can combine authorization rules
# class FooController < ApplicationController
#   authorize :admin
#   authorize :public, :except => [:new, :create, :edit, :update, :destroy]
#
#   ...
# end
#
#

module Authorization
  
  
  class Unauthorized < RuntimeError
    def initialize
      super("401 Unauthorized!")
    end
  end

  def self.included(klass)
    klass.send :include, AuthorizationInstanceMethods
    klass.send :extend, AuthorizationClassMethods
  end

  module AuthorizationInstanceMethods
    def ensure_authorized!
      raise Unauthorized.new unless self.class.authorized?(current_user, params[:action])
      true
    end
  end


  module AuthorizationClassMethods
    def authorize(roles, options = {})

      roles = [roles] unless Array===roles

      for key in [:only, :except]
        if options.has_key?(key)
          options[key] = [options[key]] unless Array === options[key]
          options[key] = options[key].compact.collect{|v| v.to_sym}
        end
      end

      self.authorizations << {:roles => roles, :options => options }
    end

    def reset_authorizations!
      authorizations.clear
    end

    def authorizations
      @authorizations ||= []
    end

    def authorized?(user, action = :index)

      return false unless self.authorizations.size > 0

      self.authorizations.each do |authorization|
        
        roles = authorization[:roles]
        options = authorization[:options]

        if options.has_key?(:only)
          next unless options[:only].include?(action.to_sym)
        end

        if options.has_key?(:except)
          next if options[:except].include?(action.to_sym)
        end

        roles.each do |role|
          return true if (user.respond_to?(:has_role?) && user.has_role?(role)) || role == :public
        end
        
      end # self.authorizations.each

      return false
      
    end # authorized?
  end # AuthorizationClassMethods

end