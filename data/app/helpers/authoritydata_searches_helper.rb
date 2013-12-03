module AuthoritydataSearchesHelper
  
  def name_type_select_options
    options = []
    options << ['personal','name_personal']
    options << ['corporate','name_corporate']
    options << ['conference','name_conference']
  end
  
  
  def geographic_type_select_options
    options = []
    options << [term_type_label('geographic'),'geographic']
    options << [term_type_label('subdivision_geographic'),'subdivision_geographic']
  end
  
  
  def term_type_label(term_type)
    term_labels = {
      'name_personal' => 'personal name',
      'name_corporate' => 'corporate name',
      'name_meeting' => 'conference/meeting name',
      'name_conference' => 'conference/meeting name',
      'topical' => 'topic',
      'topic' => 'topic',
      'concept' => 'concept',
      'geographic' => 'geographic name',
      'title_uniform' => 'uniform title',
      'genreform' => 'genre/form term',
      'subdivision_general' => 'general subdivision',
      'subdivision_form' => 'form term (subdivision)',
      'subdivision_chronological' => 'chronological subdivision',
      'subdivision_geographic' => 'geographic subdivision',
      'topical_children' => "children's topic",
      'title' => 'title'
    }
    return term_labels[term_type]
  end
  
  
  def authority_label(authority_code)
    authority_labels = {
      'lcsh' => "Library of Congress subject headings",
      'naf' => "LC/NACO authority file",
      'lcgft' => "Library of Congress Genre/Form Terms",
      'lctgm' => "Thesaurus for Graphic Materials",
      'aat' => "Art and Architecture Thesaurus",
      'ulan' => "Union List of Artist Names",
      'tgn' => "Getty Thesaurus of Geographic Names",
      'iso639-2' => "ISO 639-2",
      'iso639-1' => "ISO 639-1",
      'iso639-5' => "ISO 639-5",
      'marclang' => "MARC Code List for Languages",
      'aat_lang' => "AAT Language",
      'nalnaf' => 'National Agricultural Library name authority file',
      'nlmnaf' => 'National Library of Medicine name authority file',
      'abne' => 'Autoridades de la Biblioteca Nacional de Espa&ntilde;a',
      'bibalex' => 'Bibliotheca Alexandrina name and subject authority file',
      'conorsi' => 'CONOR.SI',
      'hapi' => 'HAPI thesaurus and name authority, 1970-2000',
      'hkcan' => 'Hong Kong Chinese Authority File (Name)',
      'lacnaf' => 'Library Archives Canada name authority file',
      'nznb' => 'New Zealand national bibliographic',
      'sanb' => 'South African national bibliography authority file',
      'unbisn' => 'UNBIS name authority list',
      'local' => 'Locally-established terms, NYPL'
    }
    return authority_labels[authority_code]
  end
  
  
  def name_type_label
    name_types = {
      'name_personal' => 'personal',
      'name_corporate' => 'corporate',
      'name_meeting' => 'conference',
      'name_family' => 'family'
    }
  end
  
  
  # authorities relevant for various types of elements
  def relevant_authorities(element_type)
    authorities = {
      'name' => ['naf','ulan','lcsh','local'],
      'genre' => ['lcgft','aat','lcsh','local','lctgm'],
      'form' => ['lcgft','aat','lcsh','local','lctgm'],
      'topic' => ['lcsh','aat','lcgft','local','lctgm'],
      'geographic' => ['tgn','naf','lcsh','local'],
      'temporal' => ['lcsh','aat','local','lctgm'],
      'title' => ['naf','ulan','lcsh','local'],
      'occupation' => ['lcsh','aat','local','lctgm']
    }
    return authorities[element_type]
  end
  
  
  # return options for select boxes in format expected by Action View form helpers - [[display label, value],...]
  def authority_select_options(element_type)
    relevant_authorities = relevant_authorities(element_type)
    authority_select_options = []
    relevant_authorities.each do |a|
      authority_select_options << [authority_label(a), a]
    end
    return authority_select_options
  end
  
  
  # Generate JSON string from a single result in Solr response
  def solr_result_to_json(result)
    json_parts = []
    # NOTE: values within the JSON string need to be double-quoted becuase terms may contain single quotes/apostrophes
    
    # term
    json_parts << '"term" : "' + result['term'] + '"'
    # authority
    json_parts << '"authority" : "' + result['authority_code'] + '"'
    # authorityRecordId
    json_parts << '"authorityRecordId" : "' +  result['record_id'] + '"'
    # name types
    
    # valueURI
    if result['uri']
      json_parts << '"valueUri" : "' + result['uri']  + '"'
    end
    if result['longitude']
      json_parts << '"longitude" : "' + result['longitude'].to_s  + '"'
    end
    if result['latitude']
      json_parts << '"latitude" : "' + result['latitude'].to_s  + '"'
    end
    
    json = '{'
    json += json_parts.join(',')
    json += '}'
  end
  
  
end
