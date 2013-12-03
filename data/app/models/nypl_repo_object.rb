class NyplRepoObject < ActiveRecord::Base
  attr_accessible :uuid, :object_type, :total_captures, :capture_ids, :describable_type, :describable_id
  belongs_to :describable, :polymorphic => true
  
  after_create :update_sib_seq
  
  after_save do
    self.describable.touch
  end
  
  # finds duplicate nypl_repo_object records and deletes all but the most recent
  # if you're using this, something went wrong somewhere else :(
  def self.remove_duplicates
    duplicates_removed = 0
    find_each do |r|
      duplicates = where(:describable_type => r.describable_type, :describable_id => r.describable_id).order('updated_at ASC')
      if duplicates.length > 1
        # only keep most recent
        dup_array = duplicates.clone.to_a
        dup_array.pop
        dup_array.each { |d| d.destroy; duplicates_removed += 1 }
      end
    end
    puts "#{duplicates_removed} duplicate records destroyed"
  end
  
  # sets sib_seq value for all nypl_reo_objects based on either existing values or creation date
  def self.update_sib_seq
    Component.find_each do |c|
      objects = c.nypl_repo_objects
      sib_seq_vals = (1..objects.length).to_a
      objects.each do |o|
        o.update_attribute(:sib_seq, sib_seq_vals[objects.index(o)])
      end
    end
  end
  
  
  def update_sib_seq
    siblings = NyplRepoObject.where(:describable_id => self.describable_id, :describable_type => self.describable_type).order(:sib_seq, :created_at)
    sib_seq_vals = (1..siblings.length).to_a
    siblings.each do |s|
      s.update_attribute(:sib_seq, sib_seq_vals[siblings.index(s)])
    end
  end
  
  
  
  def update_captures
    per_page = 100
    api_url_base = "#{NYPL_REPO_API_URL}/items/#{self.uuid}"
    api_url = "#{api_url_base}?per_page=#{per_page.to_s}"
    nypl_api = JSON.load(open(api_url, 'Authorization' => NYPL_REPO_API_AUTH_HEADER))
    response = nypl_api["nyplAPI"]["response"]
    
    puts response.inspect
    
    num_results = response["numResults"].to_i
    if num_results > 0
      capture_ids = []
      # If more than 100 results, make another call to get them all
      if num_results > per_page
        api_url = "#{api_url_base}&per_page=#{num_results}"
        nypl_api = JSON.load(open(api_url, 'Authorization' => NYPL_REPO_API_AUTH_HEADER))
        response = nypl_api['nyplAPI']['response']
      end
      captures = response['capture']
              
      if captures
        case captures
        # Need to do this because of a bug/feature in the Repo API
        when Hash
          capture_ids << { 'uuid' => captures['uuid'], 'image_id' => captures['imageID'] }
        when Array
          captures.each do |c|
            capture_ids << { 'uuid' => c['uuid'], 'image_id' => c['imageID'] }
          end
        end
        self.capture_ids = JSON.generate(capture_ids)
        self.total_captures = capture_ids.length
      end
      self.save 
    end
  end
  
  
  
  def update_total_captures
    if !self.capture_ids.blank?
      capture_ids = JSON.parse(self.capture_ids)
      total = capture_ids.length
    else
      total = 0
    end
    self.update_attributes(:total_captures => total)
  end
  
end
