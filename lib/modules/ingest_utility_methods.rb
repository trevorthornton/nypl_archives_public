module IngestUtilityMethods
  
  include UtilityMethods
  include ParseDateString
  
  def get_child_components(element,index=0)
    numbered_components = ['c01','c02','c03','c04','c05','c06','c07','c08','c09','c10','c11','c12']
    xpath = "./c|./#{numbered_components[index]}"
    components = element.xpath(xpath)
  end  
  
  
  def parse_all_elements_as_html(parent_element, elements, data={})
    elements.each do |element_name|
      element_set = parent_element.xpath(".//#{element_name}")
      if element_set.length > 0
        element_set.each do |e|
          data[element_name] ||= []
          data[element_name] << basic_element_parse(e)
        end
      end
    end
    return data
  end
  
  
  def basic_element_parse(element, html=true)
    edata = {}
    add_attributes_to_element_hash(element, edata)
    edata['value'] = ead_element_value_to_html(element)
    edata
  end
  
  
  def ead_element_value_to_html(element, level = 0)
    
    common_elements = ['p','blockquote','div']
    block_elements = ['note','address']
    inline_elements = ['abbr','addressline','archref','bibref','bibseries','date',
      'edition', 'emph','expan','imprint','num','subarea','persname','famname','corpname',
      'genreform','geogname','name','subject','title','occupation']
    list_elements = ['chronlist','chronitem','eventgrp','list','date','event','item','defitem']
    head_elements = ['head','head01','head02']
    table_elements = ['table','tgroup','colspec','tbody','thead','row']
    
    special_elements = list_elements.concat(head_elements).concat(table_elements)
    
    element.element_children.each do |c|
      if c.inner_text.blank?
        c.remove
      elsif special_elements.include?(c.name)
        # skip for now
      else
        if common_elements.include?(c.name)
          # leave as is
        elsif block_elements.include?(c.name)
          c.attributes.each { |k,v| c.remove_attribute(k) }
          c['class'] = c.name
          c.name = 'div'
        elsif inline_elements.include?(c.name)
          c.attributes.each { |k,v| c.remove_attribute(k) }
          c['class'] = c.name
          c.name = 'span'
        else
          c.replace(c.inner_text)
        end
      end
      ead_element_value_to_html(c, level + 1)
    end
    
    # remove <head> elements - headings should be added in views
    heads = element.xpath('.//head|.//head01|.//head02')
    if heads.length > 0
      first_head = heads.first
      div_title = first_head.inner_html
      heads.each { |h| h.remove }
    else
      div_title = nil
    end
    
    chronlist = element.xpath('.//chronlist')
    chronlist.each { |c| chronlist_to_html(c) }
    
    lists = element.xpath('.//list')
    lists.each do |l|
      list_items = element.xpath('.//list/item|.//list/defitem')
      list_items.each { |li| li.name = 'li' }
      l.name = l['type'] == 'ordered' ? 'ol' : 'ul'
      l.attributes.each { |k,a| l.remove_attribute(k) }
    end
    
    if level == 0
      html = element.inner_html
      remove_newlines(html)
      remove_blank_paragraphs(html)
    else
      remove_newlines(element.inner_html)
      remove_blank_paragraphs(element.inner_html)
      element
    end
    
  end
  
  
  def remove_blank_paragraphs(text)
    text.gsub(/\<p\>\s*\<\/p\>/,'')
  end
  
  
  def chronlist_to_html(chronlist_element)
    chronlist_element.name = 'div'
    chronlist_element['class'] = 'chronlist'
    
    chronitems = chronlist_element.xpath('./chronitem')
    chronitems.each do |ci|
      ci.name = 'li'
      ci['class'] = 'chronitem'
      ci.xpath('./date|./event|./eventgrp').each do |x|
        original_name = x.name
        x.name = 'div'
        x['class'] = original_name
      end
    end
    chronlist_element.to_html
  end

  
  def parse_date_string(string)
    parser = DateStringParser.new(string)
    dates = parser.parse
  end
  

  def skip_attributes
    ['encodinganalog','label']
  end
  
  
  
end