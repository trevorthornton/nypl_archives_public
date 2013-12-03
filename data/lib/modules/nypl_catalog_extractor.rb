module NyplCatalogExtractor
    
  require 'open-uri'
  require 'json'
  require 'nokogiri'

  class NyplCatalogRecord
    
    attr_accessor :bnumber, :format
    
    def initialize(params = {})
      @bnumber = params[:bnumber]
      @format = params[:format] || 'ruby'
    end
    
    def iii_xml
      if self.bnumber
        begin
          url = "http://catalog.nypl.org/xrecord=#{self.bnumber}"
          xml = open(url).read
        rescue => e
          puts e
          nil
        end
      else
        nil
      end
    end
    
    # if key_on_tag == true (default), fields will be returned in a hash, keyed on tag
    #   and each value will be an array of instances of that field
    # if key_on_tag == false, fields will be returned in an array,
    #   in the order in which they appear in the original MARC record
    #   (this is consistent with MARC-in-JSON format proposed here: http://dilettantes.code4lib.org/blog/2010/09/a-proposal-to-serialize-marc-in-json/
    #   and similar to the one proposed by OCLC - see http://www.oclc.org/developer/groups/marc-json-format-specification
    def extract(key_on_tag = true)
      xml = self.iii_xml
      if !xml
        puts "No XML returned :( Might be a bad b-number"
        nil
      else
        if !key_on_tag
          record = { :recordinfo => {}, :typeinfo => {}, :fields => [] }
        else
          record = { :recordinfo => {}, :typeinfo => {}, :fields => {} }
        end
        @doc = Nokogiri::XML(self.iii_xml)
        iii_record = @doc.root
        
        recordinfo_fields = iii_record.xpath('./RECORDINFO/*')
        recordinfo_fields.each do |f|
          record[:recordinfo][f.name.downcase.gsub(' ','').to_sym] = f.inner_text.gsub(/[\n\r\t]/,'').strip
        end
        
        typeinfo_fields = iii_record.xpath('./TYPEINFO/BIBLIOGRAPHIC/FIXFLD')
        if typeinfo_fields.length > 0
          typeinfo_fields.each do |f|
            fixlabel = f.xpath('./FIXLABEL').first.inner_text || ''
            # fixnumber = f.xpath('./FIXNUMBER').first.inner_text || ''
            fixvalue = f.xpath('./FIXVALUE').first.inner_text || ''
            record[:typeinfo][fixlabel.downcase.gsub(' ','').strip.to_sym] = fixvalue.strip
          end
        end
        
        variable_fields = iii_record.xpath('./VARFLD')
        variable_fields.each do |vf|
          # field_label = vf.xpath('./HEADER/TAG').first.inner_text.strip
          tag_element = vf.xpath('./MARCINFO/MARCTAG').first
          tag = tag_element ? tag_element.inner_text.strip : ''
        
          ind1_element = vf.xpath('./MARCINFO/INDICATOR1').first
          ind1 = ind1_element ? ind1_element.inner_text.strip : ''
        
          ind2_element = vf.xpath('./MARCINFO/INDICATOR2').first
          ind2 = ind2_element ? ind2_element.inner_text.strip : ''
          
          field_data = {}
          # field[:label] = field_label
          field_data[:ind1] = ind1.strip.length > 0 ? ind1 : nil
          field_data[:ind2] = ind2.strip.length > 0 ? ind2 : nil
          field_data[:subfields] = []
          subfields = vf.xpath('./MARCSUBFLD')
          subfields.each do |sf|
            sf_indicator = sf.xpath('./SUBFIELDINDICATOR').first.inner_text.strip
            data_element = sf.xpath('./SUBFIELDDATA').first
            data = data_element ? data_element.inner_text.strip : ''
            unescape_marc_unicode(data)
            field_data[:subfields] << { sf_indicator => data }
          end
          
          fixed_data = vf.xpath('./MARCFIXDATA').first
          if fixed_data
            field_data[:fixed_data] = fixed_data.inner_text
          end
          
          if !tag.blank?
            if !key_on_tag
              record[:fields] << { tag => field_data }
            else
              record[:fields][tag] ||= []
              record[:fields][tag] << field_data
            end
          end
          
        end
                    
        case self.format
        when 'ruby'
          record
        when 'json'
          JSON.generate(record)
        when 'marcxml'
          marc_hash_to_marcxml(record)
        end
      end
    end
    
    
    def marc_hash_to_marcxml(hash)
      doc = Nokogiri::XML('<collection xmlns="http://www.loc.gov/MARC21/slim"></collection>')
      collection = doc.root
      record = Nokogiri::XML::Node.new('record',doc)
      hash[:fields].each do |field|
        tag = field.keys.first
        datafield = Nokogiri::XML::Node.new('datafield',doc)
        datafield['tag'] = tag
        datafield['ind1'] = field[:ind1] ? field[:ind1] : ''
        datafield['ind2'] = field[:ind2] ? field[:ind2] : ''
        field[:subfields].each do |sf|
          sf_code = sf.keys.first
          sf_value = sf[sf_code]
          subfield = Nokogiri::XML::Node.new('subfield',doc)
          subfield['code'] = sf_code
          subfield << sf_value
          datafield << subfield
        end
        record << datafield
      end
      collection << record
      doc.to_s
    end
  
  
    # Convert escaped Unicode characters in element values
    #   from their exported form (eg {u00fe}) to ruby form (\u00ef)
    def unescape_marc_unicode(string)
      m = string.scan(/\{[^\}]+\}/)
      if m
        m.to_a.each do |find|
          code_raw = find.gsub(/[(\{u)\}]/,'')
          code = "0x" + code_raw.gsub(/^0+/,'')
          codepoint = UnicodeUtils::Codepoint.new(code.to_i(16))
          replace = codepoint.to_s
          string.gsub!(find,replace)
        end
      end
      string
    end
    
  end

end