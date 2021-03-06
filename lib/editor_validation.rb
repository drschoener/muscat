class EditorValidation
  
  attr_accessor :name
  attr_accessor :id
  attr_accessor :validation
  attr_accessor :model
  
  # Load all the configurations, first in editor_profiles/default/configurations then ins
  # editor_profiles/#{RISM::EDITOR_PROFILE}/configurations. If two files share the same name
  # in the two directories, they will be merged together.
  def squeeze(config)
    settings = Settings.new(Hash.new())
    
    profile_name = RISM::EDITOR_PROFILE != "" ? RISM::EDITOR_PROFILE : "default"

    file = "#{Rails.root}/config/editor_profiles/#{profile_name}/configurations/#{config}.yml"
    if File.exists?(file)
      settings.squeeze(Settings.new(IO.read(file)))
    end

    return settings
  end
    
  def initialize(conf)
    @name = conf[:name]
    @id = conf[:id]
    @validation = conf[:validation]
    @model = conf[:model]
    @validation_config = squeeze(conf[:validation])
  end

  def validate_subtag?(tag, subtag)
    if @validation_config[tag]
      return true if @validation_config[tag]["tags"][subtag]
    end
      return false
  end

  def get_rules_for_tag(tag)
    return @validation_config[tag]
  end
  
  def get_subtag_class_name(tag, subtag)
    class_name = "validate_#{tag}_#{subtag}"
    unique_name = class_name + "_uniq_" + SecureRandom.hex(5)
    return class_name, unique_name
  end
  
  def rules
    return @validation_config
  end

  def self.get_default_validation(model)
    profiles = EditorValidation.profiles
    model_name = model.class.to_s.downcase
    profiles.each do |p|
      next if model_name != p.model
      return p if p.validation
    end
    return nil
  end

  def self.profiles
    unless @squeezed_profiles
      # load global configurations
      @squeezed_profiles = Array.new
    
      profile_name = RISM::EDITOR_PROFILE != "" ? RISM::EDITOR_PROFILE : "default"
    
      # Load local configurations
      file = "#{Rails.root}/config/editor_profiles/#{profile_name}/profiles.yml"

      configurations = YAML::load(IO.read(file))
      configurations.each do |conf|
        next if !conf[:validation]
        @squeezed_profiles << EditorValidation.new(conf)
      end
      
    end
    @squeezed_profiles
  end
    
end
