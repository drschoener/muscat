# A StandardTerm is a standardized keyword, ex. "Airs (instr.)"
#
# === Fields
# * <tt>term</tt> - the keyword
# * <tt>alternate_terms</tt> - alternate spellings for this keyword
# * <tt>notes</tt>
# * <tt>src_count</tt> - keeps track of the Source models tied to this element
#
# Other standard wf_* not shown
# The other functions are standard, see Catalogue for a general description

class StandardTerm < ActiveRecord::Base
  
  has_and_belongs_to_many(:referring_sources, class_name: "Source", join_table: "sources_to_standard_terms")
  has_and_belongs_to_many(:referring_institutions, class_name: "Institution", join_table: "institutions_to_standard_terms")
  has_and_belongs_to_many(:referring_catalogues, class_name: "Catalogue", join_table: "catalogues_to_standard_terms")
  has_many :folder_items, :as => :item
  has_many :delayed_jobs, -> { where parent_type: "StandardTerm" }, class_name: Delayed::Job, foreign_key: "parent_id"
  belongs_to :user, :foreign_key => "wf_owner"
  validates_presence_of :term
  validates_uniqueness_of :term
  
  #include NewIds
  
  before_destroy :check_dependencies
  
  #before_create :generate_new_id
  after_save :reindex
  
  attr_accessor :suppress_reindex_trigger
  
  enum wf_stage: [ :inprogress, :published, :deleted ]
  enum wf_audit: [ :basic, :minimal, :full ]
  
  # Suppresses the solr reindex
  def suppress_reindex
    self.suppress_reindex_trigger = true
  end
  
  def reindex
    return if self.suppress_reindex_trigger == true
    self.index
  end

  searchable :auto_index => false do
    integer :id
    string :term_order do
      term
    end
    text :term
    
    string :alternate_terms_order do
      alternate_terms
    end
    text :alternate_terms
    
    text :notes
    
    join(:folder_id, :target => FolderItem, :type => :integer, 
              :join => { :from => :item_id, :to => :id })
    
    integer :src_count_order do 
      src_count
    end
  end
  
  def check_dependencies
    if (self.referring_sources.count > 0)
      errors.add :base, "The standard term could not be deleted because it is used"
      return false
    end
  end
  
  def name
    return term
  end

end
