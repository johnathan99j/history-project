module NTHP
  class Season < Jekyll::Document
    def initialize(path, relations)
      super path, relations
      merge_data!({
        "title" => relations[:title],
      })
    end

    def slug
      data["title"].downcase
    end

    def shows
      @site.collections["shows"].by_season[data["title"]]
    end

    def to_liquid
      @to_liquid ||= SeasonDrop.new(self)
    end
  end

  class SeasonDrop < Jekyll::Drops::DocumentDrop
    extend Forwardable
    def_delegators :@obj, :slug, :shows
  end

  class Seasons < Jekyll::Collection

    # Monkey-patched from
    # https://github.com/jekyll/jekyll/blob/v3.3.0/lib/jekyll/collection.rb#L200
    private
    def read_document(full_path)
      doc = NTHP::Season.new(full_path, :site => site, :collection => self)
      doc.read
      if site.publisher.publish?(doc) || !write?
        docs << doc
      else
        Jekyll.logger.debug "Skipped From Publishing:", doc.relative_path
      end
    end
  end

  class SeasonGenerator < Jekyll::Generator
    priority :normal

    def generate(site)
      if site.config["skip_seasons"]
        Jekyll.logger.warn "Skipping season generation"
        return
      end

      collection = site.collections["seasons"]
      seasons = Array.new

      Jekyll.logger.info "Generating seasons..."

      site.collections["shows"].by_season.each_key { |season|
        unless collection.docs.detect { |doc| doc.data["title"] == season }
          seasons << Season.new("/seasons/#{season.downcase}/", {
            :site => site,
            :collection => collection,
            :title => season,
          })
        end
      }

      collection.docs += seasons
    end
  end
end
