Given /^the following featured collections exist for the affiliate "([^"]*)":$/ do |affiliate_name, table|
  affiliate = Affiliate.find_by_name(affiliate_name)
  table.hashes.each_with_index do |hash, index|
    featured_collection = affiliate.featured_collections.build(:title => hash['title'],
                                                               :title_url => hash['title_url'],
                                                               :locale => hash['locale'],
                                                               :status => hash['status'],
                                                               :publish_start_on => hash['publish_start_on'],
                                                               :publish_end_on => hash['publish_end_on'])
    featured_collection.featured_collection_keywords.build(:value => "keyword value #{index + 1}")
    featured_collection.save!
  end
end

Then /^I should see "([^"]*)" featured collections$/ do |count|
  page.should have_selector(".featured-collection-list .row-item", :count => count)
end

Then /^the following featured collection keywords exist for featured collection titled "([^"]*)":$/ do |featured_collection_title, table|
  featured_collection = FeaturedCollection.find_by_title(featured_collection_title)
  featured_collection.featured_collection_keywords.delete_all
  table.hashes.each do |hash|
    featured_collection.featured_collection_keywords.create!(:value => hash['value'])
  end
end

Given /^there are (\d+) featured collections exist for the affiliate "([^"]*)":$/ do |count, affiliate_name, table|
  affiliate = Affiliate.find_by_name(affiliate_name)
  table.hashes.each do |hash|
    count.to_i.times do |i|
      featured_collection = affiliate.featured_collections.build(
          :title => hash['title'] || "random title #{i + 1}",
          :title_url => hash['title_url'] || "http://example/random_content#{i + 1}.html",
          :locale => hash['locale'],
          :status => hash['status'] || "active")
      featured_collection.featured_collection_keywords.build(:value => "keyword value #{i + 1}")
      featured_collection.save!
    end
  end
end

Given /^the following featured collection links exist for featured collection titled "([^"]*)":$/ do |featured_collection_title, table|
  featured_collection = FeaturedCollection.find_by_title(featured_collection_title)
  table.hashes.each_with_index do |hash, i|
    featured_collection.featured_collection_links.create!(:title => hash['title'], :url => hash['url'], :position => i)
  end
end
