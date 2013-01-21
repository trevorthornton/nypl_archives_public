module ParseDateString
  
  # Parsers ignore qualifiers (approximate, inferred, date type, etc.) represented by the use of AACR2-style formatting, e.g.:
  #    [1969], 1969, 1969?, ca. 1969, 1969, c1969  ... all convert to 1969
  
  class DateStringParser
    
    @@zulu_format = '%Y-%m-%dT12:%M:%SZ'
  
    def initialize(string)
      @string = string
      # all values in @dates should be integers EXCEPT key date,
      # which is the chronologically first date (iso 8601) as a string (avoids datefield complications)
      @dates = { :index_dates => [], :keydate => nil, :keydate_z => nil }
      @regex_tokens = regex_tokens
    end
  
    def parse
      self.match_replace
      return @dates
    end
  
    def match_replace
      match_replace_clusters.each do |c|
        if @string.match(c[:match])
          c[:proc].call(@string) if !c[:proc].nil?
          break
        end
      end
    end

    def match_replace_clusters
      r = @regex_tokens
      match_replace = []
    
      # 1969, [1969], c1969
      single_year = {
        :match => "^(#{r[:circa]})?#{r[:year]}([\,\;\s(and)]{1,3}#{r[:nd]})?$",
        :proc => proc_single_year
      }
      match_replace << single_year
    
      # 1969-1977
      year_range = {
        :match => "^[\,\s]{0,2}(#{r[:circa]})?\s?#{r[:year]}#{r[:range_delimiter]}(#{r[:circa]})?\s?#{r[:year]}([\,\;\s(and)]{0,4}#{r[:nd]})?$",
        :proc => proc_year_range
      }
      match_replace << year_range
    
      # nd, n.d., undated, Undated...
      nd = {
        :match => "^#{r[:nd]}$",
        :proc => nil
      }
      match_replace << nd
    
      # 1970's, 1970s
      decade_s = {
        :match => "^#{r[:decade_s]}$",
        :proc => proc_decade_s
      }
      match_replace << decade_s
    
      # 1969-72
      year_range_short = {
        :match => "^#{r[:year]}#{r[:range_delimiter]}[0-9]{2}$",
        :proc => proc_year_range_short
      }
      match_replace << year_range_short
    
      # 1976 July 4
      full_date_single_rev = {
        :match => "^[^\w\d]*#{r[:year]}[\s\,]*#{r[:named_month]}[\s\,]*([0-9]{1,2})?[^\w\d]{0,3}$",
        :proc => proc_full_date_single_rev
      }
      match_replace << full_date_single_rev
    
      # 1903, 1969, 1984
      year_list = {
        :match => "^#{r[:year]}#{r[:list_delimiter]}#{r[:year]}$",
        :proc => proc_year_list
      }
      match_replace << year_list
    
      # 1960-1980s
      year_range_to_decade = {
        :match => "^[\,\s]{0,2}(#{r[:circa]})?#{r[:year]}#{r[:range_delimiter]}#{r[:decade_s]}([\,\;\s(and)]{0,4}#{r[:nd]})?$",
        :proc => proc_year_range_to_decade
      }
      match_replace << year_range_to_decade
    
    
      # matches any number of 4-digit years separated by a single range or list delimiter
      # Note: this pattern will also match strings matched by year_list above, but year_list will be checked first, so if that one matches, this one won't be checked
      year_range_list_combo = {
        :match => "^#{r[:year]}((#{r[:list_delimiter]}|#{r[:range_delimiter]})#{r[:year]}){2,}$",
        :proc => proc_year_range_list_combo
      }
      match_replace << year_range_list_combo
    
    
      # Early 1960's, mid-1980s, late 1950's, etc.
      decade_s_qualified = {
        :match => "^#{r[:decade_qualifier]}\s?#{r[:decade_s]}$",
        :proc => proc_decade_s_qualified
      }
      match_replace << decade_s_qualified
    
      # December 7, 1941
      full_date_single = {
        :match => "^[^\w\d]{0,3}#{r[:named_month]}[\s\,]*([0-9]{1,2})?[\s\,]*#{r[:year]}[^\w\d]{0,3}$",
        :proc => proc_full_date_single
      }
      match_replace << full_date_single
    
      # December 7, 1941
      common_numeric_date_single = {
        :match => "^[0-1]?[0-9][\/\-][0-3]?[0-9][\/\-][0-2][0-9]{3}$",
        :proc => proc_full_date_single
      }
      match_replace << common_numeric_date_single
    
      match_replace
    end

    def proc_single_year
      proc = Proc.new do |string|
        year = string.gsub(/[^0-9]*/,'')
        @dates[:index_dates] << year.to_i
        @dates[:keydate_z] = Time.new(year).strftime(@@zulu_format)
        @dates[:keydate] = year
      end
    end
  
    def proc_year_range
      proc = Proc.new do |string|
                
        range = string.scan(/[0-2][0-9]{3}/)
        if range.length > 0
          range_start = range[0].to_i
          range_end = range[1].to_i
          (range_start..range_end).to_a.each { |d| @dates[:index_dates] << d }
          @dates[:keydate_z] = Time.new(range[0]).strftime(@@zulu_format)
          @dates[:keydate] = range[0]
        end
      end
    end
  
    def proc_year_range_to_decade
      proc = Proc.new do |string|
        range = string.scan(Regexp.new(@regex_tokens[:year]))
        range.each { |d| d.gsub!(/[^0-9]*/,'') }
        range_start = range[0].to_i
        range_end_decade = range[1].to_i
        range_end = range_end_decade + 9
        (range_start..range_end).to_a.each { |d| @dates[:index_dates] << d }
        @dates[:keydate_z] = Time.new(range[0]).strftime(@@zulu_format)
        @dates[:keydate] = range[0]
      end
    end
  
    def proc_year_range_short
      proc = Proc.new do |string|
        range = string.split('-')
        range.each { |d| d.gsub!(/[^0-9]*/,'') }
        decade_string = range[0].match(/^[0-9]{2}/).to_s
        range[1] = decade_string + range[1]
        range_start = range[0].to_i
        range_end = range[1].to_i
        (range_start..range_end).to_a.each { |d| @dates[:index_dates] << d }
        @dates[:keydate_z] = Time.new(range[0]).strftime(@@zulu_format)
        @dates[:keydate] = range[0]
      end
    end
  
    def proc_year_list
      proc = Proc.new do |string|
        list = string.scan(Regexp.new(@regex_tokens[:year]))
        list.sort!
        list.each { |d| @dates[:index_dates] << d.to_i }
        @dates[:keydate_z] = Time.new(list.first).strftime(@@zulu_format)
        @dates[:keydate] = list.first
      end
    end
  
    def proc_year_list
      proc = Proc.new do |string|
        list = string.scan(Regexp.new(@regex_tokens[:year]))
        list.sort!
        list.each { |d| @dates[:index_dates] << d.to_i }
        @dates[:keydate_z] = Time.new(list.first).strftime(@@zulu_format)
        @dates[:keydate] = list.first
      end
    end
  
    def proc_year_range_list_combo
      proc = Proc.new do |string|
        ranges = []
        list = []
        index_dates = []
        years = string.scan(/[0-2][0-9]{3}/)
        delimiters = string.scan(/\s?[\-\;\,]\s?/)
        delimiters.each { |d| d.strip! }
        i = 0
        while i < years.length
          y1 = years[i]
          d = delimiters[i]
          if d == '-'
            y2 = years[i + 1]
            ranges << [y1,y2]
            i += 2
          else
            list << y1
            i += 1
          end
        end
        ranges.each do |r|
          range_start = r[0].to_i
          range_end = r[1].to_i
          (range_start..range_end).to_a.each { |d| index_dates << d }
        end
        list.each { |y| index_dates << y.to_i }
        index_dates.sort!
        @dates[:index_dates] = index_dates
        @dates[:keydate_z] = Time.new(index_dates.first.to_s).strftime(@@zulu_format)
        @dates[:keydate] = index_dates.first.to_s
      end
    end
  
  
    def proc_decade_s
      proc = Proc.new do |string|
        decade = string.match(/[0-9]{3}0/).to_s
        @dates[:keydate_z] = Time.new(decade).strftime(@@zulu_format)
        @dates[:keydate] = decade
        decade_start = decade.to_i
        decade_end = (decade_start + 9)
        @dates[:index_dates] = (decade_start..decade_end).to_a
      end
    end
  
    def proc_decade_s_qualified
      proc = Proc.new do |string|
        decade = string.match(/[0-9]{3}0/).to_s
        @dates[:keydate_z] = Time.new(decade).strftime(@@zulu_format)
        @dates[:keydate] = decade
        decade_start = decade.to_i
        if string.match(/[Ee]arly/)
          range_start = decade_start
          range_end = decade_start + 5
        elsif string.match(/[Mm]id(dle)?/)
          range_start = decade_start + 3
          range_end = range_start + 5
        elsif string.match(/[Ll]ate/)
          range_start = decade_start + 5
          range_end = decade_start + 9
        end
        @dates[:index_dates] = (range_start..range_end).to_a
      end
    end
  
    def full_date_single_keydates(string,datetime)
      r = @regex_tokens
      day_specific_regex = "^[^\w\d]{0,3}#{r[:named_month]}[\s\,]*[0-9]{1,2}[\s\,]*#{r[:year]}[^\w\d]{0,3}$"
      month_specific_regex = "^[^\w\d]{0,3}#{r[:named_month]}[\s\,]*#{r[:year]}[^\w\d]{0,3}$"
    
      if string.match(day_specific_regex)
        @dates[:keydate] = datetime.strftime('%Y-%m-%d')
      elsif string.match(month_specific_regex)
        @dates[:keydate] = datetime.strftime('%Y-%m')
      end
    end
  
    def proc_full_date_single
      proc = Proc.new do |string|
        datetime = Chronic.parse(string)
        if datetime
          full_date_single_keydates(string,datetime)
          @dates[:keydate_z] = datetime.strftime(@@zulu_format)
          @dates[:index_dates] << datetime.strftime('%Y').to_i
        end
      end
    end
  
    def proc_full_date_single_rev
      proc = Proc.new do |string|
        new_string = string.clone
        year = new_string.match(/[0-9]{4}/).to_s
        new_string.gsub!(Regexp.new(year), '')
        new_string.gsub!(/[\.\,\s]+/,' ')
        new_string += ", #{year}"
        datetime = Chronic.parse(new_string)
        if datetime
          full_date_single_keydates(string,datetime)
          @dates[:keydate_z] = datetime.strftime(@@zulu_format)
          @dates[:index_dates] << datetime.strftime('%Y').to_i
        end
      end
    end
    
    
    def regex_tokens
      return {
        # 1969, [1969], c1969
        :year => '[\[\sc\(]{0,3}[0-2][0-9]{3}[\]\s\.\,;\?\)]{0,3}',
        # -
        :range_delimiter => '\s?\-\s?',
        # , or ;
        :list_delimiter => '\s*[\,\;]\s*',
        # n.d., undated, etc.
        :nd => '[\[\s]{0,2}\b([Uu]+ndated\.?)|([nN]\.?[dD]\.?)\b[\s\]\.]{0,3}',
        # 1960s, 1960's
        :decade_s => '[\[\s]{0,2}[0-9]{3}0\'?s[\]\s]{0,2}',
        # 196-
        :decade_aacr => '[0-9]{3}\-',
        # named months, including abbreviations - case insensitive
        :named_month => '(?i)\b((jan(uary)?)|(feb(ruary)?)|(mar(ch)?)|(apr(il)?)|(may)|(jun(e)?)|(jul(y)?)|(aug(ust)?)|(sep(t|tember)?)|(oct(ober)?)|(nov(ember)?)|(dec(ember)?))\b\.?',
        # circa, ca.
        :circa => '[Cc](irc)?a\.?',
        # early, late, mid-
        :decade_qualifier => '([Ee]arly)|([Mm]id)|([Ll]ate)\-?',
        # 06-16-1972, 6-16-1972
        :numeric_date_us => '(0?1)|(0?2)|(0?3)|(0?4)|(0?5)|(0?6)|(0?7)|(0?8)|(0?9)|1[0-2][\-\/](([0-2]?[0-9])|3[01])[\-\/])?[12][0-9]{3}'
      }
    end
  
  end

end