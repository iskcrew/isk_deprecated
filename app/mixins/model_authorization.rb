module  ModelAuthorization
  
  module ClassMethods
    def auth_roles
      @roles ||= {
        :admin => self.base_class.name.downcase + "-admin",
        :hide => self.base_class.name.downcase + "-hide",
        :create => self.base_class.name.downcase + "-create",
        :override => self.base_class.name.downcase + "-override"
      }
    end
    
    
    def can_create?(user)
      user.has_role?([self.auth_roles[:admin],self.auth_roles[:create]])
    end
    
    def can_override(user)
      if user.has_role?([self.auth_roles[:admin],self.auth_roles[:override]])
        return relation
      else
        return self.joins(:authorized_users).where(:users => {:id => user.id})
      end
    end


    def can_edit(user)
      if user.has_role?(self.auth_roles[:admin])
        return relation
      else
        self.joins(:authorized_users).where('users.id = ?', user.id)
      end
    end

    def admin?(user)
      user.has_role?(self.auth_roles[:admin])
    end
    
  end
  
  def self.included(base)
    base.extend(ClassMethods)
  end

  
  def can_edit?(user)
    user.has_role?(self.class.auth_roles[:admin]) || self.authorized_users.include?(user)
  end
  
  def can_hide?(user)
    user.has_role?(self.class.auth_roles[:hide]) || can_edit?(user)
  end
    
  def can_override?(user)
    user.has_role?([self.class.auth_roles[:admin], @base.auth_roles[:override]]) || self.authorized_users.include?(user)
  end
    
  def admin?(user)
    user.has_role?(self.class.auth_roles[:admin])
  end
  
  private
  
  
  
end 