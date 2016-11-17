module NTHP
  # A list of people in a cast, crew or committee.
  class PersonList
    def initialize(site, source, data, reverse)
      @site = site        # The site object
      @source = source    # The source document (show, committee)
      @raw = data         # Raw array from the source file
      @reverse = reverse  # Is this a :show or a :committee
      ingest
    end

    # Take names from PL to use for placeholder generation, we do a quick 'n
    # dirty parse here to achieve this. Better parse will be done later.
    def ingest
      @site.data[:people_names] ||= Array.new
      credits = Hash.new

      @raw.each { |item|
        if (item.key?("name") and item["name"] != "unknown") and not item["person"] == false
          unless false #@site.data["people_names"].include?(item["name"])
            # add to list of people names, used for virtual people generation
            @site.data[:people_names] << item["name"].to_sym

            credit_data = {
              :role => item["role"],
              :name => item["name"],
              :note => item["note"],
              :source => @source,
            }
            unless credits.key? item["name"]
              # First credit for this item for this person
              credits[item["name"]] = Credit.new(credit_data)
            else
              # Additional credit for this item for this person, they had
              # multiple roles.
              credits[item["name"]].append(credit_data)
            end
          end
        end
      }

      @site.data[:credits] ||= Hash.new
      @site.data[:credits][@reverse] ||= Hash.new

      credits.each_value { |credit|
        # Append credits to people, creates a person's credit store if it does
        # not already exist.
        (@site.data[:credits][@reverse][credit.name.to_sym] ||= []) << credit
      }
    end

    def parse_list
      @raw.map { |item|
        if item["person"] != false and item.key?("name")
          item["person"] = @site.collections["people"].by_name(item["name"])
        end
        item
      }
    end

    def to_liquid
      @to_liquid ||= {
        "people" => parse_list,
      }
    end
  end

  # A credit is a record of a single person's involvement in a single item:
  # show or committee. A person may have many credits but only one per item.
  # Each credit can have many roles.
  class Credit
    attr_accessor :name, :roles, :note, :source
    def initialize(data)
      @name = data[:name]
      @roles = [data[:role]]
      # @note = data["note"]
      @source = data[:source]
    end

    def append(data)
      @roles << data["role"]
    end

    def to_liquid
      {
        "name" => @name,
        "roles" => @roles,
        "source" => @source,
      }
    end
  end
end
