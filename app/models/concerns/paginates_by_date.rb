# Include this module in an ActiveRecord::Base class to paginate records by a date column
module PaginatesByDate

  extend ActiveSupport::Concern

  included do

    ##
    # Monkey-Patch Kaminari's ::page() method to return records grouped by their date.
    #
    # page_no - Date offset. Some dates have records, some don't. Therefore, date 2 might
    #           not be the calendar date immediately after date 1. However, it should be
    #           the next available date with records.
    scope :page, lambda { |page_no|
      logger.tagged("Kaminari") { |l|
        l.debug("page() method is being redefined in #{__FILE__}")
      }
      PaginatesByDate::RelationDatePaginationDecorator.new(self, page_no || 1).relation
    }

  end

  # Decorator class that wraps the current ActiveRecord::Relation instance in the
  #   PaginatesByDate::InstanceMethods and configures them.
  #
  #   This basically adds some extra methods to the Relation object and then returns it
  #   via the #relation attribute.
  #
  #   See how it's used in the :page scope above.
  class RelationDatePaginationDecorator

    attr_reader :relation

    def initialize(model_context, page_no)
      @relation = model_context.instance_eval do
        # The date values for each object in the current relation
        dates       = order("#{dpcn} ASC").pluck(dpcn).map(&:to_date)
        # The total count of objects in the current relation
        total_count = dates.count
        # The uniq date values for each object in the current relation
        #   (this is what we're paginating).
        uniq_dates  = dates.uniq.sort
        # The date for the current "page"
        page_date   = uniq_dates[page_no.to_i - 1]
        # The records scoped by the current date
        scoped      = where("DATE(#{dpcn}) = DATE(:date)", date: page_date.try(:to_date))

        # Dress the ActiveRecord::Relation in a few extra methods to conform to
        #   Kaminari expectations
        scoped.extend(PaginatesByDate::InstanceMethods)
        scoped.page_no     = page_no.to_i
        scoped.dates       = uniq_dates
        scoped.page_date   = page_date
        scoped.total_count = total_count
        scoped
      end
    end

  end


  # These instance methods are bound to an ActiveRecord::Relation instance to help
  #   it comply to Kaminari expectations
  module InstanceMethods

    ##
    # The total number of records in the whole set
    attr_accessor :total_count

    ##
    # An Integer current page number
    attr_accessor :page_no

    alias_method :current_pge, :page_no

    ##
    # The Dates we can paginate records by
    attr_accessor :dates

    ##
    # The Date for the current page
    attr_accessor :page_date


    ##
    # Is this page the last in the set?
    def last_page?
      page_date == dates.last
    end

    ##
    # An Integer of the total number of pages
    def num_pages
      dates.length
    end

    alias_method :total_pages, :num_pages

    # Monkey-patch the per() method to do nothing.
    def per(*)
      Rails.logger.tagged("Kaminari") { |l| l.debug("the per() method is disabled") }
      return self
    end

  end


  # Class methods bound to the ActiveRecord::Base subclass (the model).
  module ClassMethods

    # Set the column to paginate records by. This must be the name of a datetime or date
    #   column. (defaults: "date")
    def date_pagination_column_name(col_name = nil)
      if col_name
        @@date_pagination_column_name = col_name
      else
        return @@date_pagination_column_name || "date"
      end
    end

    # A helper alias to keep the code neater. What?! Don't judge me! YOUR code smells!
    alias_method :dpcn, :date_pagination_column_name

  end

end
