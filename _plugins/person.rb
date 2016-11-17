module NTHP
  # A single person
  class Person < Jekyll::Document
    def initialize(path, relations)
      @placeholder = relations[:placeholder]
      super path, relations
      merge_data!({
        # "yyyy" => yyyy,
        "redirect_from" =>
        ["/people/#{basename_without_ext.sub('-','_')}/"],
        }, :source => "class")
    end

    # Latch onto this method to access frontmatter data
    def read_post_data
      super
      @collection.post_person_by_name(self, data["title"])
    end

    def headshot
      @headshot ||= begin
        if data["headshot"]
          SmugImage.new(data["headshot"])
        end
      end
    end

    def name
      return data["title"]
    end

    def last_year
      @last_year ||= begin
        credits = shows + committees
        if credits.size == 0
          nil
        else
          credit_years = credits.map { |credit| credit.source.yyyy }
          est = credit_years.max + 1 # plus one to get graduation year
          est > 1900 ? est : nil  # Sanity check
        end
      end
    end

    def graduated
      data["graduated"] || last_year
    end

    def graduated_actual
      data["graduated"] != nil
    end

    def yyy
      graduated.to_s[0..2].to_i
    end

    def shows
      @site.data[:credits][:show][name.to_sym] || []
    end

    def committees
      @site.data[:credits][:committee][name.to_sym] || []
    end

    def to_liquid
      @to_liquid ||= PersonDrop.new(self)
    end
  end

  class PersonDrop < Jekyll::Drops::DocumentDrop
    extend Forwardable
    def_delegators :@obj, :headshot, :shows, :committees, :basename_without_ext, :graduated, :graduated_actual, :yyy
  end

  # The shows collection
  class People < Jekyll::Collection
    # Store a ref of people by their names

    def post_person_by_name(person, name)
      @people_by_name ||= Hash.new
      @people_by_name[name] = person
    end

    # Get a person document from a name
    def by_name(name)
      @people_by_name[name]
    end

    # Monkey-patched from
    # https://github.com/jekyll/jekyll/blob/v3.3.0/lib/jekyll/collection.rb#L200
    private
    def read_document(full_path)
      doc = NTHP::Person.new(full_path, :site => site, :collection => self)
      doc.read
      if site.publisher.publish?(doc) || !write?
        docs << doc
      else
        Jekyll.logger.debug "Skipped From Publishing:", doc.relative_path
      end
    end
  end

  # Generates placeholder people from people_names
  class PeoplePlaceholderGenerator < Jekyll::Generator
    priority :normal

    def path(name)
      fn = name.downcase.gsub(/[^0-9a-z \-]/i, '').gsub(' ','_')
      "/people/#{fn}/"
    end

    def generate(site)
      if not (site.config["skip_virtual_people"] or site.data["people_names"].nil?)
        collection = site.collections["people"]
        Jekyll.logger.info "Generating virt people..."
        virtual_people = Array.new
        for name_sym in site.data["people_names"].uniq
          name_str = name_sym.to_s
          unless collection.docs.detect { |doc| doc.data["title"] == name_str }
            virtual_people << Person.new(path(name_str), {
              :site => site,
              :collection => collection,
              :placeholder => true,
              :name => name_str,
              })
          end
        end
        Jekyll.logger.debug "Made #{virtual_people.count} virtual people"
        collection.docs += virtual_people
      else
        Jekyll.logger.warn "Skipping virtual people generation"
      end

    end

  end
end
