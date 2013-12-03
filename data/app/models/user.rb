class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :role, :name_first, :name_last, :username
  # attr_accessible :title, :body
  
  has_many :user_org_unit_associations
  has_many :org_units, :through => :user_org_unit_associations, :order => 'org_units.center asc, org_units.name asc'
  
  def accessible_org_units
    if ['superadmin','admin'].include? self.role
       OrgUnit.order([:center, :name]).all
    else 
      self.org_units
    end
  end
  
  def org_unit_ids
     self.org_units.map { |o| o.id }
  end
  
  def accessible_org_unit_ids
    self.accessible_org_units.map { |o| o.id }
  end
  
  def role_level
    roles_levels[self.role]
  end
  
  def accessible_classes
    roles_class_access[self.role] || []
  end
  
  def can_access_class?(class_name)
    self.accessible_classes.include?(class_name.to_s)
  end
  
  def can_modify_user?(other_user)
    if self.role_level
      self.role_level <= other_user.role_level ? true : false
    else
      false
    end
  end
  
  def can_create?(class_name)
    self.accessible_classes.include?(class_name.to_s) ? true : false
  end
  
  def can_edit?(record)
    if !self.accessible_classes.include?(record.class.to_s)
      return false
    else
      case record
      when Collection
        return self.accessible_org_unit_ids.include?(record.org_unit_id) ? true : false
      when Component
        return self.accessible_org_unit_ids.include?(record.collection.org_unit_id) ? true : false
      when OrgUnit
        return self.accessible_org_unit_ids.include?(record.id) ? true : false
      when User
        return self.can_modify_user?(record)
      when Document
        case record.describable
        when Collection, Component
          return self.accessible_org_unit_ids.include?(record.describable.org_unit_id) ? true : false
        end
      end
    end
  end
  
  def assignable_roles
    roles = []
    roles_levels.each do |k,v|
      if v >= self.role_level
        roles << k
      end
    end
    roles
  end
  
  
  protected
  
  def roles_levels
    {
      'superadmin' => 1,
      'admin' => 2,
      'editor' => 30,
      'viewer' => 100
    }
  end
  
  def roles_class_access
    {
      'superadmin' => ['Collection','Component','Description','CollectionResponse','ComponentResponse','Document','OrgUnit','User'],
      'admin' => ['Collection','Component','Document','OrgUnit','User'],
      'editor' => ['Collection','Component','Document','OrgUnit'],
    }
  end
  
end
