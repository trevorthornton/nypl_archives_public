class Description < ActiveRecord::Base
  
  include GeneralUtilityMethods
  include IngestUtilityMethods   
    
  attr_accessible :describable_id, :describable_type, :descriptive_identity, :content_structure, :context, :acquisition_processing, :related_material, :access_use, :notes, :data
    
  belongs_to :describable, :polymorphic => true
    
  # after_save :update_response
  
  # def consolidate_data
  #   data = {}
  #   attributes = ['descriptive_identity','context','content_structure',
  #     'acquisition_processing','access_use','related_material','notes']
  #   attributes.each do |a|
  #     attribute_value = self.send(a)
  #     if attribute_value
  #       attribute_hash = JSON.parse(attribute_value)
  #       data.merge!(attribute_hash)
  #     end
  #   end
  #   compact(data)
  #   self.data = JSON.generate(data)
  #   self.save
  # end
  
  
  after_save do
    self.describable.touch
  end
  
  
  after_create do
    if !self.data
      self.update_attribute(:data, JSON.generate({}))
    end
  end
  
  
  def get_description_data_elements(element_name)
    if self.data
      desc_data = JSON.parse(self.data) || {}
      return desc_data[element_name] ? desc_data[element_name] : nil
    end
  end
  
  
  def call_number
    unitid = self.get_description_data_elements('unitid')
    call_number_value = nil
    if unitid
      unitid.each do |u|
        if u['type'] && u['type'] == 'local_call'
          call_number_value = u['value']
          break
        end
      end
    end
    call_number_value
  end
  
  
  def abstract
    abstract_value = ''
    abstracts = self.get_description_data_elements('abstract')
    if abstracts
      abstracts.each do |a|
        if a['value']
          abstract_value += abstract_value.empty? ? a['value'] : ' ' + a['value']
        end
      end
    end
    return abstract_value.empty? ? nil : abstract_value
  end
  
  
  def bulk_dates_cleanup
    if self.data
      data = JSON.parse(self.data)
      if data['unitdate']
        data['unitdate'].each do |ud|
          if ud['type'] == 'bulk'
            ud['value'].gsub!(/(bulk\s?)*/,'')
            ud['value'].gsub!(/[\[\]\(\)]/,'')
            ud['value'].strip!
          end
        end
        self.update_attribute(:data, JSON.generate(data))
      end
    end
  end
  
  
  def parse_unitdates
    if self.data
      data = JSON.parse(self.data)
      data_original = data.clone
      compact(data)
      if data['unitdate'] && data['dates_index'].blank?
        data['unitdate'].each do |u|
          if u['value']
            date_values = generate_extended_date_values(u)
            date_values.each do |k,v|
              case k
              when 'dates_index'
                data[k] ||= []
                data[k] += v
                data[k].sort!
                data[k].uniq!
              when 'date_inclusive_start','date_bulk_start','keydate'
                if !data[k] || (v && data[k] > v)
                  data[k] = v
                end
              when 'date_inclusive_end','date_bulk_end'
                if !data[k] || (v && data[k] < v)
                  data[k] = v
                end
              else
                if !v.blank?
                  if data[k].blank?
                    data[k] = v
                  end
                end
              end
            end
          end
        end
        compact(data)
        if data != data_original
          self.update_attributes(:data => JSON.generate(data))
          self.describable.update_response
        end
      end
    end
  end
  
  
  def update_data(data)
    self.update_attributes(:data => JSON.generate(data))
  end
  
  
  
  
  def parse_unitdate(options={})
    if self.data
      data = JSON.parse(self.data)
      data_original = data.clone
      
      compact(data)
      if data['unitdate'] && data['dates_index'].blank?
        data['unitdate'].each do |u|
          if u['value']
            date_values = generate_extended_date_values(u)
            date_values.each do |k,v|
              case k
              when 'dates_index'
                data[k] = v
              when 'date_inclusive_start','date_bulk_start','keydate'
                if !data[k] || (v && data[k].to_i > v.to_i)
                  data[k] = v
                end
              when 'date_inclusive_end','date_bulk_end'
                if !data[k] || (v && data[k] < v)
                  data[k] = v
                end
              else
                if !v.blank?
                  if data[k].blank?
                    data[k] = v
                  end
                end
              end
            end
          end
        end
        compact(data)
        if data != data_original
          self.update_data(data)
          self.describable.update_response(:limit => 'desc_data', :limit => 'desc_data', :skip_components => true)
        end
      end
    end
  end
  
  
  
  
  protected
    
  def update_response
    self.describable.update_response
  end


end
