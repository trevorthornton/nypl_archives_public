module IngestUtilityMethods
  
  include GeneralUtilityMethods
  include DataImportMethods
  include EadUtilityMethods
  include ControlledVocabularyUtilityMethods
  include DateUtilityMethods


  def remove_blank_paragraphs(text)
    text.gsub(/\<p\>\s*\<\/p\>/,'')
  end

  
  # def chronlist_to_html(chronlist_element)
  #   chronlist_element.name = 'div'
  #   chronlist_element['class'] = 'chronlist'
  #   
  #   chronitems = chronlist_element.xpath('./chronitem')
  #   chronitems.each do |ci|
  #     ci.name = 'li'
  #     ci['class'] = 'chronitem'
  #     ci.xpath('./date|./event|./eventgrp').each do |x|
  #       original_name = x.name
  #       x.name = 'div'
  #       x['class'] = original_name
  #     end
  #   end
  #   chronlist_element.to_html
  # end
  
  
  def generate_extended_date_values(unitdate,level=nil)
    date_values = {}
    
    date_string = unitdate['value']
    dates = parse_date_string(date_string)
    
    if dates[:index_dates].empty? && unitdate['normal']
      dates = parse_date_string(unitdate['normal'], :force_8601 => true)
    end
    
    puts dates.inspect
    
    if unitdate['type'] == 'bulk'
      date_values['date_bulk_start'] = dates[:index_dates].first
      date_values['date_bulk_end'] = dates[:index_dates].last
    else
      date_values['date_inclusive_start'] = dates[:index_dates].first
      date_values['date_inclusive_end'] = dates[:index_dates].last
      date_values['keydate'] = dates[:keydate]
      date_values['dates_index'] = dates[:index_dates]
    end
    date_values
  end
  
  
  def parse_date_string(string,options={})
    clean_date_string(string)
    parser = ParseDateString::Parser.new(string,options)
    dates = parser.parse
  end
  
  
  
  

  # Remove full stop/period ('.') from end of field values
  def strip_stop(string)
    string.strip!
    skip = false
    exceptions = [/\sft\.?$/,/\sin\.?$/,/\s[A-Z][a-z]{0,2}\.$/,/\.{3}$/]
    exceptions.each do |e|
      if string.match(e)
        skip = true
        break
      end
    end
    if !skip
      string.gsub!(/[\.\,\;\:\s]{0,3}$/,'')
    end
    string
  end
  
end