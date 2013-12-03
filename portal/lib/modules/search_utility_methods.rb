module SearchUtilityMethods
  
  class SolrSanitizer
    @@boolean_operators_regex = /\b(AND)\b|\b(OR)\b|\b(NOT)\b|\B(&&)\B|\B(!)\B|\B(\|\|)\B/
    @@bracket_regex = /((\()|(\))|(\{)|(\})|(\[)|(\]))/
    @@wildcard_regex = /((\*)|(\?))/
    @@fuzzy_regex = /(~)/
    @@boost_regex = /(\^)/
    @@boolean_modifier_regex = /((\+)|(-))/
    @@misc_regex = /(\")|(:)/
    
    ####################
    #
    # All REGEXP definitions match characters or keywords that are part of the Apache Lucene Query Parser Sytntax
    #
    # @@bracket_regex => matches parentheses and brackets and braces that group search clauses or define range searches
    #
    # @@wildcard_regex => matches ? or * characters in the search that act as single or multiple character wildcards within a search term
    #
    # @@fuzzy_regex => matches the ~ character at the end of a search term or phrase
    #
    # @@boost_regex => matches the ^ character at the end of a search term or phrase
    #
    # @@boolean_modifier_regex => matches + or - characters at the start of search terms/phrases
    #
    # @@misc_regex => matches (currently) : and " characters that are used for defining phrases or field values
    #
    ####################
    
    def escape_boolean_operators(query)
      return nil unless query
      new_query = query.gsub(@@boolean_operators_regex, '&&' => '\\&\\&', '||' => '\\|\\|', '!' => '\\!', 'AND' => 'and', 'NOT' => 'not', 'OR' => 'or')
    end
    
    def remove_boolean_operators(query)
      return nil unless query
      new_query = query.gsub(@@boolean_operators_regex, '')
    end
    
    def escape_brackets(query)
      return nil unless query
      new_query = query.gsub(@@bracket_regex, '\\\\\1')
    end
    
    def remove_brackets(query)
      return nil unless query
      new_query = query.gsub(@@bracket_regex, '')
    end
    
    def escape_wildcards(query)
      return nil unless query
      new_query = query.gsub(@@wildcard_regex, '\\\\\1')
    end
    
    def remove_wildcards(query)
      return nil unless query
      new_query = query.gsub(@@wildcard_regex, '')
    end
    
    def escape_fuzzy(query)
      return nil unless query
      new_query = query.gsub(@@fuzzy_regex, '\\\\\1')
    end
    
    def remove_fuzzy(query)
      return nil unless query
      new_query = query.gsub(@@fuzzy_regex, '')
    end
    
    def escape_boost(query)
      return nil unless query
      new_query = query.gsub(@@boost_regex, '\\\\\1')
    end
    
    def remove_boost(query)
      return nil unless query
      new_query = query.gsub(@@boost_regex, '')
    end
    
    def escape_boolean_modifiers(query)
      return nil unless query
      new_query = query.gsub(@@boolean_modifier_regex, '\\\\\1')
    end
    
    def remove_boolean_modifiers(query)
      return nil unless query
      new_query = query.gsub(@@boolean_modifier_regex, '')
    end
    
    # : (colon) characters in SOLR searches are modified by acts_as_solr_reloaded
    # after they are escaped
    #
    # without sanitization, some_field:some_value => some_field_t:some_value from acts_as_solr
    # with sanitization, some_field:some_value => some_field\_t:some_value
    #
    # for this reason we simply remove the : from the search entirely since it cannot be escaped
    
    def escape_misc(query)
      return nil unless query
      # new_query = query.gsub(@@misc_regex, '"' => '\\"', ':' => '')
      # new_query = query.gsub(@@misc_regex, ':' => '')
      new_query = query.gsub(/\:/, '')
    end
    
    # def remove_misc(query)
    #   return nil unless query
    #   new_query = query.gsub(@@misc_regex, '')
    # end
    
    def sanitize(query)
      new_query = escape_boolean_operators(query)
      new_query = escape_brackets(new_query)
      new_query = escape_wildcards(new_query)
      new_query = escape_fuzzy(new_query)
      new_query = escape_boost(new_query)
      new_query = escape_boolean_modifiers(new_query)
      new_query = escape_misc(new_query)
    end
  end

end