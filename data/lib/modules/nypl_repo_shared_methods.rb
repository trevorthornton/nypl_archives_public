module NyplRepoSharedMethods
  
  require 'open-uri'
  
  
  #############################################################
  # Retrieval & calculation methods
  #############################################################
  
  
  def capture_ids
    capture_ids = []
    self.nypl_repo_objects.each do |o|
      ids = JSON.parse(o.capture_ids)
      capture_ids.concat(ids)
    end
    capture_ids
  end
  
  
  def total_captures
    total_captures = 0
    self.nypl_repo_objects.each do |o|
      total_captures += o.total_captures ? o.total_captures : 0
    end
    total_captures
  end
    
  
  #############################################################
  # Update methods
  #############################################################
  
  
  def update_nypl_repo_uuid
    previous_objects = self.nypl_repo_objects
    api_url =  "#{NYPL_REPO_API_URL}/items/#{self.identifier_type}/#{self.identifier_value}"
    
    puts api_url
    
    nypl_api = JSON.load(open(api_url, 'Authorization' => NYPL_REPO_API_AUTH_HEADER))
    response = nypl_api['nyplAPI']['response']
    
    puts response.inspect
    
    uuids = []
    if response["uuid"].class == String
      uuids << response["uuid"]
    elsif response["uuid"].class == Array
      response["uuid"].each { |u| uuids << u }
    end
    
    # cycle through response uuids
    uuids.each do |u|
      # check for existing object with that uuid, skip or add
      existing_object = NyplRepoObject.where(:uuid => u, :describable_type => self.class.to_s, :describable_id => self.id).first
      if !existing_object
        NyplRepoObject.create(:uuid => u, :describable_type => self.class.to_s, :describable_id => self.id)
      end
    end
    
    #cycle through previous_objects
    previous_objects.each do |o|
      # delete if uuid not in new_uuids
      if !uuids.include?(o.uuid)
        o.destroy
      end
    end
  end
  
  
  def update_nypl_repo_captures
    self.nypl_repo_objects.each do |o|      
      o.update_captures
    end
  end
  
  
  # updates uuid and captures for record and all descendants
  def update_nypl_repo_objects
    repo_update = Proc.new do |c|
      c.update_nypl_repo_uuid
      c.reload
      c.update_nypl_repo_captures
      if c.children
        c.children.each { |cc| repo_update.call(cc) }
      end
    end
    self.children.each { |c| repo_update.call(c) }
  end
  
  
  def update_total_captures
    self.nypl_repo_objects.each do |o|
      o.update_total_captures
    end
  end

  
end