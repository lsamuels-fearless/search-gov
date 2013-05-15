require 'spec_helper'

describe VideoNewsSearch do
  fixtures :affiliates

  let(:affiliate) { affiliates(:basic_affiliate) }

  describe "#initialize(options)" do
    it "should set the class name to 'VideoNewsSearch'" do
      VideoNewsSearch.new(:query => '   element   OR', :tbs => "w", :affiliate => affiliate).class.name.should == 'VideoNewsSearch'
    end

    it 'should initialize per_page' do
      VideoNewsSearch.new(query: 'gov', tbs: 'w', affiliate: affiliate).per_page.should == 20
    end

    it 'should not overwrite per_page option' do
      VideoNewsSearch.new(query: 'gov', tbs: 'w', affiliate: affiliate, per_page: '15').per_page.should == 15
    end
  end

  describe "#run" do
    context 'when video news items are found' do
      it "should log info about the query and module impressions" do
        search = VideoNewsSearch.new(query: 'element', affiliate: affiliate, channel: mock_model(RssFeed).id)
        response = mock('results', total: 1, facets: [], hits: [])
        NewsItem.should_receive(:search_for).and_return response
        QueryImpression.should_receive(:log).with(:news, affiliate.name, 'element', ['VIDS'])
        search.run
      end
    end

    context "when a valid active RSS feed is specified" do
      it "should only search for news items from that feed" do
        rss_feed = mock_model(RssFeed, is_managed?: true)
        affiliate.stub_chain(:rss_feeds, :managed, :find_by_id).and_return(rss_feed)
        affiliate.should_receive(:youtube_profile_ids).twice.and_return mock('youtube profile ids')
        youtube_feeds = [mock_model(RssFeed)]
        RssFeed.stub_chain(:includes, :owned_by_youtube_profile, :where).and_return youtube_feeds
        search = VideoNewsSearch.new(query: 'element', channel: '100', affiliate: affiliate)
        NewsItem.should_receive(:search_for).with('element', youtube_feeds, affiliate, { since: nil, until: nil }, 1, 20, nil, nil, nil, false)
        search.run.should be_true
      end
    end

    context "when there is only 1 navigable video rss feed" do
      it "should assign @rss_feed" do
        videos_navigable_feeds = [mock_model(RssFeed, is_managed?: true)]
        affiliate.stub_chain(:rss_feeds, :managed, :navigable_only).and_return(videos_navigable_feeds.clone)
        affiliate.should_receive(:youtube_profile_ids).twice.and_return mock('youtube profile ids')
        youtube_feeds = [mock_model(RssFeed)]
        RssFeed.stub_chain(:includes, :owned_by_youtube_profile, :where).and_return youtube_feeds
        time_range = { since: Time.current.advance(weeks: -1).beginning_of_day, until: nil }
        NewsItem.should_receive(:search_for).with('element', youtube_feeds, affiliate, time_range, 1, 20, nil, nil, nil, false)
        search = VideoNewsSearch.new(query: 'element', tbs: 'w', affiliate: affiliate)
        search.run
        search.rss_feed.should == videos_navigable_feeds.first
      end
    end
  end
end
