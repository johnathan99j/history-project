module NTHP
  # A single show
  class Committee < Jekyll::Document
    def initialize(path, relations)
      super path, relations
      merge_data!({
        "yyyy" => yyyy,
        # "redirect_from" => TODO
        #   ["/years/#{@year.to_s[2..4]}_#{(@year+1).to_s[2..4]}/"],
        }, :source => "class")
    end

    # Latch onto this method to access frontmatter data
    def read_post_data
      super
      if data.key?("committee")
        @committee_list = PersonList.new(@site, self, data["committee"], :committee)
      else
        # Fail build if we don't have
        Jekyll.logger.abort_with "committee #{basename} lacking committee"
      end
    end

    # Generate the four digit 'start of academic year'. All shows in 2014-15
    # will have a yyyy of 2014. It's used to locate the correct year to match
    # the show up with.
    def yyyy
      basename_without_ext[0..3].to_i
    end

    def committee_list
      @committee_list.to_liquid
    end

    def to_liquid
      @to_liquid ||= CommitteeDrop.new(self)
    end
  end

  class CommitteeDrop < Jekyll::Drops::DocumentDrop
    extend Forwardable
    def_delegator :@obj, :committee_list
  end

  # The shows collection
  class Committees < Jekyll::Collection
    # Return an committee for a year.
    def for_yyyy(year)
      @by_year ||= begin
        h = Hash.new
        @docs.each { |doc|
          h[doc.data["yyyy"]] = doc
        }
        h # return
      end
      return @by_year[year]
    end

    # Monkey-patched from
    # https://github.com/jekyll/jekyll/blob/v3.3.0/lib/jekyll/collection.rb#L200
    private
    def read_document(full_path)
      doc = NTHP::Committee.new(full_path, :site => site, :collection => self)
      doc.read
      if site.publisher.publish?(doc) || !write?
        docs << doc
      else
        Jekyll.logger.debug "Skipped From Publishing:", doc.relative_path
      end
    end
  end
end
