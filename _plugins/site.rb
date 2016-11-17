module Jekyll
  class Site
    # Monkey-patch of collection generation
    # https://github.com/jekyll/jekyll/blob/v3.3.0/lib/jekyll/site.rb#L136
    def collections
      @collections ||= Hash[collection_names.map do |coll|
        case coll
        when "years"
          [coll, NTHP::Years.new(self, coll)]
        when "shows"
          [coll, NTHP::Shows.new(self, coll)]
        when "committees"
          [coll, NTHP::Committees.new(self, coll)]
        when "people"
          [coll, NTHP::People.new(self, coll)]
        when "seasons"
          [coll, NTHP::Seasons.new(self, coll)]
        when "venues"
          [coll, NTHP::Venues.new(self, coll)]
        else
          puts coll
          [coll, Jekyll::Collection.new(self, coll)]
        end
      end]
    end
  end
end
