module NTHP
  # Year
  class Year < Jekyll::Document
    def initialize(path, relations)
      @year = relations[:year]
      super path, relations

      merge_data!({
        "title" => "#{@year} – #{(@year+1).to_s[2..4]}",
        "yyyy" => @year,
        "yyyy_grad" => @year + 1,
        "yyy" => @year.to_s[0..2].to_i,
        "redirect_from" =>
          ["/years/#{@year.to_s[2..4]}_#{(@year+1).to_s[2..4]}/"],
      }, :source => "class")
    end

    # All shows in this year
    def shows
      @site.collections["shows"].by_yyyy(data["yyyy"])
    end

    # Committee for this year
    def committee
      @site.collections["committees"].for_yyyy(data["yyyy"])
    end

    def to_liquid
      @to_liquid ||= YearDrop.new(self)
    end
  end

  # Year liquid data 'Drop'
  class YearDrop < Jekyll::Drops::DocumentDrop
    extend Forwardable
    def_delegators :@obj, :shows, :committee#, :fellows, :commendations
  end

  # Years collection
  class Years < Jekyll::Collection
    attr_writer :year_map

    # Return a hash of years by their decade (yyy)
    def by_decade
      @by_decade ||= begin
        h = Hash.new
        @docs.each { |doc|
          (h[doc.data["yyy"].to_s] ||= []) << doc
        }
        h # return
      end
      return @by_decade
    end

    # Return a year doc from it's yyyy
    def by_yyyy(yyyy)
      @year_map[yyyy]
    end
  end

  # Spawns year documents for the prescribed range
  class YearGenerator < Jekyll::Generator
    priority :highest

    # Turns 2015 into "2015-16"
    def path(year)
      return "#{year}-#{(year+1).to_s[2..4]}"
    end

    # Called by Jekyll
    def generate(site)
      if not site.config["skip_years"]
        collection = site.collections["years"]
        Jekyll.logger.info "Generating years..."
        years = Array.new
        year_map = Hash.new
        for year in site.config["year_start"]..site.config["year_end"]
          year_doc = NTHP::Year.new(path(year), {
            :site => site,
            :collection => collection,
            :year => year,
          })
          years << year_doc
          year_map[year] = year_doc
        end
        collection.docs = years
        collection.year_map = year_map
      else
        Jekyll.logger.warn "Skipping year generation"
      end
    end
  end
end
