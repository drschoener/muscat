class Ability
  include CanCan::Ability

  def initialize(user)

    if user.has_role? :admin
      can :manage, :all
      can :reindex, [Catalogue, Institution, LiturgicalFeast, Person, Place, StandardTerm, StandardTitle, Folder]
      can :publish, [Folder]

    elsif user.has_role? :guest
      can :read, :all
      can :read, ActiveAdmin::Page, :name => "Dashboard"
      can :read, User, :id => user.id

    elsif user.has_role?(:editor)
      can [:read, :create, :update], [DigitalObject, Catalogue, Institution, LiturgicalFeast, Person, Place, StandardTerm, StandardTitle, Work, Holding]
      can :destroy, [DigitalObject, Catalogue, Institution, LiturgicalFeast, Person, Place, StandardTerm, StandardTitle, Work, Holding], :wf_owner => user.id
      can [:read, :create, :update], Source
      can :destroy, Source, :wf_owner => user.id
      
      can :manage, Folder
      can [:read, :create], ActiveAdmin::Comment
      can :read, ActiveAdmin::Page, :name => "Dashboard"
      can :read, ActiveAdmin::Page, :name => "guidelines"
      can :read, ActiveAdmin::Page, :name => "doc"
      can [:read, :update], User, :id => user.id

    elsif user.has_role?(:cataloger)
      # A cataloguer can create new items but modify only the ones ho made
      can [:read, :create], [Catalogue, Institution, LiturgicalFeast, Person, Place, StandardTerm, StandardTitle, Work, Holding]
      can :update, [Catalogue, Institution, LiturgicalFeast, Person, Place, StandardTerm, StandardTitle, Work, Holding], :wf_owner => user.id
      can :create, DigitalObject
      can [:destroy, :read, :update], DigitalObject, :wf_owner => user.id
      
      can [:read, :create, :update], Folder
      can [:read, :create, :update], ActiveAdmin::Comment
      
      can [:read, :create], Source
      can :update, Source, :wf_owner => user.id
      can :update, Source do |source|
        user.can_edit? source
      end
      
      can :read, ActiveAdmin::Page, :name => "Dashboard"
      can :read, ActiveAdmin::Page, :name => "guidelines"
      can :read, ActiveAdmin::Page, :name => "doc"
      can [:read, :update], User, :id => user.id
    end

  end
  
end
