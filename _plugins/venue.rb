module NTHP
  class Venue < Jekyll::Document
    def initialize(path, relations)
      super path, relations
      merge_data!({
        "title" => relations[:title],
        "placeholder" => relations[:placeholder],
      })
    end

    def slug
      data["title"].downcase
    end

    def shows
      @site.collections["shows"].by_venue[data["title"]]
    end

    # Convert image keys into smugimages
    def smug_images
      @smug_images ||= begin
        if data.key? "images"
          data["images"].map {|key|
            SmugImage.new(key)
          }
        else
          []
        end
      end
    end

    def to_liquid
      @to_liquid ||= VenueDrop.new(self)
    end
  end

  class VenueDrop < Jekyll::Drops::DocumentDrop
    extend Forwardable
    def_delegators :@obj, :slug, :shows, :smug_images
  end

  class Venues < Jekyll::Collection

    # Monkey-patched from
    # https://github.com/jekyll/jekyll/blob/v3.3.0/lib/jekyll/collection.rb#L200
    private
    def read_document(full_path)
      doc = NTHP::Venue.new(full_path, :site => site, :collection => self)
      doc.read
      if site.publisher.publish?(doc) || !write?
        docs << doc
      else
        Jekyll.logger.debug "Skipped From Publishing:", doc.relative_path
      end
    end
  end

  class VenueGenerator < Jekyll::Generator
    priority :normal

    def generate(site)
      if site.config["skip_venues"]
        Jekyll.logger.warn "Skipping venue generation"
        return
      end

      collection = site.collections["venues"]
      venues = Array.new

      Jekyll.logger.info "Generating venues..."

      site.collections["shows"].by_venue.each_key { |venue|
        unless collection.docs.detect { |doc| doc.data["title"] == venue }
          venues << Venue.new("/venues/#{venue.downcase}/", {
            :site => site,
            :collection => collection,
            :title => venue,
            :placeholder => true,
          })
        end
      }

      collection.docs += venues
    end
  end
end
