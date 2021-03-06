module Mokio
  module Concerns
    module Models
      #
      # Concern for User model
      #
      module User
        extend ActiveSupport::Concern

        included do
          include Mokio::Concerns::Models::Common
          include RoleModel

          before_destroy :last_one?

          attr_accessor :only_password
          
          #
          # Table of roles for user
          #
          
          ROLES = ["admin", "content_editor", "menu_editor", "static_module_editor", "user_editor", "comment_approver", "reader"]

          devise :database_authenticatable, :rememberable, :recoverable, :trackable

          validates_presence_of   :email
          validates_uniqueness_of :email, allow_blank: true, if: :email_changed?
          validates_format_of     :email, with: email_regexp, allow_blank: true, if: :email_changed?

          validates_presence_of     :password, if: :password_required?
          validates_confirmation_of :password, if: :password_required?
          validates_length_of       :password, within: password_length, allow_blank: true



          # optionally set the integer attribute to store the roles in,
          # :roles_mask is the default

          roles_attribute :roles_mask

          # declare the valid roles -- do not change the order if you add more
          # roles later, always append them at the end!
          roles :admin, :content_editor, :menu_editor, :static_module_editor, :user_editor, :comment_approver, :reader

          # before_validation :add_default_role
          belongs_to :market

          if Mokio.solr_enabled
            searchable do
            ## Columns where Sunspot knows which data use to index
              text :email
            end
          end

          # Overwrite devise-3.4.1/lib/devise/models/recoverable.rb to force check password is filled
          def reset_password!(new_password, new_password_confirmation)
            self.only_password=true
            super
          end

        end

        module ClassMethods
          #
          # Columns for table in CommonController#index view
          #
          def columns_for_table
            ["email", "roles"]
          end
        end

        #
        # Output for <b>roles</b> parameter, used in CommonController#index
        #
        def roles_view
          self.roles.to_a.map{|m| I18n.t("users.role_name." + m.to_s)}.join(', ')
        end

        def editable #:nodoc:
          true
        end

        def deletable #:nodoc:
          true
        end

        def name #:nodoc:
          email
        end
        
        def title #:nodoc:
          email
        end

        #
        # Specify what's showed in breadcrumb
        #
        def breadcrumb_name
          email
        end

        #
        # Output for <b>email</b> parameter, used in CommonController#index
        #
        def email_view
          html = ""
          html << (ActionController::Base.helpers.link_to self[:email], ApplicationController.helpers.edit_url(self.class.base_class, self))
          html.html_safe
        end

        def password_required?
          !persisted? || !password.blank? || !password_confirmation.blank? || only_password
        end

        def email_required?
          true
        end

        module ClassMethods
          Devise::Models.config(self, :email_regexp, :password_length)
        end

        private
          def last_one?
            errors.add(:base, "Cannot delete last user") if Mokio::User.count == 1
            errors.blank? 
          end
      end
    end
  end
end