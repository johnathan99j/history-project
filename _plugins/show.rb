require_relative 'smugmug/smugmug_album'

module NTHP
  # A single show
  class Show < Jekyll::Document
    def initialize(path, relations)
      super path, relations
      merge_data!({
        "yyyy" => yyyy,
        "yyy" => yyy,
        # "redirect_from" => TODO
        #   ["/years/#{@year.to_s[2..4]}_#{(@year+1).to_s[2..4]}/"],
        }, :source => "class")
    end

    # Latch onto this method to access frontmatter data
    def read_post_data
      super
      if data.key?("cast")
        @cast_list = PersonList.new(@site, self, data["cast"], :show)
      end
      if data.key?("crew")
        @crew_list = PersonList.new(@site, self, data["crew"], :show)
      end
    end

    attr_reader :cast_list, :crew_list


    def assets
      @assets ||= begin
        data["assets"] ||= []
        data["assets"].map { |asset|
          if asset.key? "image"
            asset["image"] = SmugImage.new(asset["image"])
          end
          asset
        }
      end
    end

    def assets_by_type(type)
      assets.select { |i|
        # Skip non images
        unless i.key? "image" then next end
        i["type"] == type
      }
    end

    # Return the best asset for graphically representing this show
    def display_image
      return nil unless assets
      override = assets.select { |i| i["display_image"] == true }
      if override.size > 0
        return override[0]
      elsif assets_by_type("poster").size > 0
        return assets_by_type("poster")[0]
      elsif assets_by_type("flyer").size > 0
        return assets_by_type("flyer")[0]
      elsif assets_by_type("programme").size > 0
        return assets_by_type("programme")[0]
      end
    end

    # Prod shots smugmug album
    def smugmug_album
      if data.key? "pprod_shots"
        return SmugAlbum.new.get_show_photos(data["prod_shots"])
      else
        return nil
      end
    end

    # Generate the four digit 'start of academic year'. All shows in 2014-15
    # will have a yyyy of 2014. It's used to locate the correct year to match
    # the show up with.
    def yyyy
      ps = path.split("/")
      ps[ps.length - 2][0..3].to_i
    end

    # Same as yyyy but for decade, so yyy
    def yyy
      ps = path.split("/")
      ps[ps.length - 2][0..2].to_i
    end

    # Getter for year document
    def year
      @year ||= @site.collections["years"].by_yyyy(yyyy)
    end

    # TODO playwright
    #      playwright_type
    #      playwright_formatted
    #      playwright_formatted_long

    def to_liquid
      @to_liquid ||= ShowDrop.new(self)
    end
  end

  class ShowDrop < Jekyll::Drops::DocumentDrop
    extend Forwardable
    def_delegators :@obj, :cast_list, :crew_list, :smugmug_album, :yyyy, :yyy, :year, :assets, :display_image

    def poster
      display_image
    end
  end

  # The shows collection
  class Shows < Jekyll::Collection
    # Return an array of shows for a particular year. Builds the data structure
    # needed on the first call.
    def by_yyyy(year)
      @by_year ||= begin
        h = Hash.new
        @docs.each { |doc|
          (h[doc.data["yyyy"]] ||= []) << doc
        }
        h # return
      end
      return (@by_year[year] || []).sort { |x, y|
        x.data["season_sort"] <=> y.data["season_sort"] }
    end

    # Return a hash mapping season names to shows
    def by_season
      @by_season ||= begin
        mapped_hash = Hash.new
        @docs.each { |show|
          show.data["season"] == "UNCUT" ? season = "Fringe" : season = show.data["season"]
          (mapped_hash[season] ||= []) << show
        }
        mapped_hash.sort.to_h
      end
    end

    # Return a hash mapping venue names to shows
    def by_venue
      @by_venue ||= begin
        mapped_hash = Hash.new
        @docs.each { |show|
          # Group similar venues together, #457
          if show.data["venue_sort"]
            venue = show.data["venue_sort"]
          elsif show.data["venue"] and show.data["venue"].downcase != "unknown"
            venue = show.data["venue"]
          end
          # Only add to hash if we have a venue
          (mapped_hash[venue] ||= []) << show if venue
        }
        mapped_hash
      end
    end

    # Return a hash mapping play titles to shows
    def by_play
      @by_play ||= begin
        mapped_hash = Hash.new
        @docs.each { |show|
          # All shows have a title
          (mapped_hash[show.data["title"]] ||= []) << show
        }
        mapped_hash.sort.to_h
      end
    end

    # Return a hash mapping play titles to shows
    def by_playwright
      @by_playwright ||= begin
        mapped_hash = Hash.new
        @docs.each { |show|
          if show.data.key?("playwright") and show.data["playwright"] and show.data["playwright"] != "various"
            (mapped_hash[show.data["playwright"]] ||= []) << show
          end
        }
        mapped_hash.sort.to_h
      end
    end

    # Monkey-patched from
    # https://github.com/jekyll/jekyll/blob/v3.3.0/lib/jekyll/collection.rb#L200
    private
    def read_document(full_path)
      doc = NTHP::Show.new(full_path, :site => site, :collection => self)
      doc.read
      if site.publisher.publish?(doc) || !write?
        docs << doc
      else
        Jekyll.logger.debug "Skipped From Publishing:", doc.relative_path
      end
    end
  end
end
