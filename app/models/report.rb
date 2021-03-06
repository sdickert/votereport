class Report < ActiveRecord::Base
  validates_presence_of :reporter_id
  validates_uniqueness_of :uniqueid, :scope => :source, :allow_blank => true, :message => 'already processed'

  belongs_to :location
  belongs_to :reporter
  has_many :report_tags, :dependent => :destroy
  has_many :tags, :through => :report_tags
  has_many :report_filters, :dependent => :destroy
  has_many :filters, :through => :report_filters

  before_validation :set_source
  before_save :detect_location, :assign_tags
  after_save  :assign_filters
  
  named_scope :with_location, :conditions => 'location_id IS NOT NULL'

  private
  def set_source
    self.source = self.reporter.source
  end
  
  def detect_location
    if self.text
      LOCATION_PATTERNS.find { |p| self.text[p] }
      self.location = Location.geocode($1) if $1
      self.zip = location.postal_code if location && location.postal_code
      self.location = reporter.location if !self.location && reporter && reporter.location
    end
    true
  end
  
  # What tags are associated with this report?
  # Find them and store for easy reference later
  def assign_tags
    if self.text
      Tag.find(:all).each do |t|
        if self.text[/#?#{t.pattern}/i]
          self.tags << t
          self.wait_time = $1 if t.pattern.starts_with?('wait')
        end
      end
      self.score = self.tags.inject(0) { |sum, t| sum+t.score }
    end
    true
  end
  
  # What location filters apply to this report?  US, MD, etc?
  def assign_filters
    if self.location_id
			values = self.location.filter_list.split(',').map { |f| "(#{f},#{self.id})" }.join(',')
      self.connection.execute("INSERT DELAYED INTO report_filters (filter_id,report_id) VALUES #{values}") if !values.blank?
		end
		true
  end
end
