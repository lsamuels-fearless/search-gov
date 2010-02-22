class SearchesController < ApplicationController
  before_filter :set_search_options
  has_mobile_fu

  def index
    @search = Search.new(@search_options)
    @search.run
    handle_affiliate_search
  end

  # TODO This could be cleaned up into search.rb
  def auto_complete_for_search_query
    render :inline => "" and return unless params['query']
    sanitized_query = params['query'].gsub('\\', '')
    pre_filters = ' AND query NOT LIKE "%http:%" AND query NOT LIKE "%intitle:%" AND query NOT LIKE "%site:%" AND query NOT REGEXP "[()\/\"]"'
    conditions = ['query LIKE ? '+pre_filters, sanitized_query + '%' ]
    results = DailyQueryStat.find(:all, :conditions => conditions, :order => 'query ASC', :limit => 15, :select=>"distinct(query) as query")
    @auto_complete_options = BlockWord.filter(results, "query")
    render :inline => "<%= auto_complete_result(@auto_complete_options, 'query', '#{sanitized_query.gsub("'", "\\\\'")}') %>"
  end

  private

  def handle_affiliate_search
    if @search_options[:affiliate]
      @affiliate = @search_options[:affiliate]
      @page_title = "#{t :search_results_for} #{@affiliate.name}: #{@search.query}"
      render :action => "affiliate_index", :layout => "affiliate"
    end
  end

  # TODO This could be cleaned up into search.rb
  def set_search_options
    affiliate = params["affiliate"] ? Affiliate.find_by_name(params["affiliate"]) : nil
    if affiliate && params["staged"]
      affiliate.domains = affiliate.staged_domains
      affiliate.header = affiliate.staged_header
      affiliate.footer = affiliate.staged_footer
    end
    @search_options = {
      :page => (params[:page].to_i - 1),
      :query => params["query"],
      :query_limit => params["query-limit"],
      :query_quote => params["query-quote"],
      :query_quote_limit => params["query-quote-limit"],
      :query_or => params["query-or"],
      :query_or_limit => params["query-or-limit"],
      :query_not => params["query-not"],
      :query_not_limit => params["query-not-limit"],
      :file_type => params["filetype"],
      :site_limits => params["sitelimit"],
      :site_excludes => params["siteexclude"],
      :filter => params["filter"],
      :affiliate => affiliate,
      :results_per_page => in_mobile_view? ? (is_device?("iphone") ? 10 : 3) : (params["per-page"].nil? ? nil : (params["per-page"].empty? ? nil : params["per-page"].to_i))
    }
  end
end
