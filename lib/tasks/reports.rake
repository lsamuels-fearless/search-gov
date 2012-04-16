namespace :usasearch do
  namespace :reports do

    def establish_aws_connection
      AWS::S3::Base.establish_connection!(:access_key_id => AWS_ACCESS_KEY_ID, :secret_access_key => AWS_SECRET_ACCESS_KEY)
      AWS::S3::Bucket.find(AWS_BUCKET_NAME) rescue AWS::S3::Bucket.create(AWS_BUCKET_NAME)
    end

    def generate_report_filename(prefix, day, date_format)
      "analytics/reports/#{prefix}/#{prefix}_top_queries_#{day.strftime(date_format)}.csv"
    end

    desc "Generate Top Queries reports (daily or monthly) on S3 from CTRL-A delimited input file containing group(e.g., affiliate or locale), query, total"
    task :generate_top_queries_from_file, :file_name, :period, :max_entries_per_group, :date, :needs => :environment do |t, args|
      if args.file_name.nil? or args.period.nil? or args.max_entries_per_group.nil?
        Rails.logger.error "usage: rake usasearch:reports:generate_top_queries_from_file[file_name,monthly|daily,1000]"
      else
        day = args.date.nil? ? Date.yesterday : Date.parse(args.date)
        establish_aws_connection
        format = args.period == "monthly" ? '%Y%m' : '%Y%m%d'
        max_entries_per_group = args.max_entries_per_group.to_i
        last_group, cnt, output = nil, 0, nil
        File.open(args.file_name).each do |line|
          group, query, total = line.chomp.split(/\001/)
          if last_group.nil? || last_group != group
            AWS::S3::S3Object.store(generate_report_filename(last_group, day, format), output, AWS_BUCKET_NAME) unless output.nil?
            output = "Query,Raw Count,IP-Deduped Count\n"
            cnt = 0;
          end
          if cnt < max_entries_per_group
            query_start_date = args.period == "monthly" ? day.beginning_of_month : day
            daily_query_stats_total = DailyQueryStat.sum(:times, :conditions => ['affiliate=? AND query=? AND day BETWEEN ? AND ?', group, query, query_start_date, day])
            output << "#{query},#{total},#{daily_query_stats_total}\n"
            cnt += 1
          end
          last_group = group
        end
        AWS::S3::S3Object.store(generate_report_filename(last_group, day, format), output, AWS_BUCKET_NAME) unless output.nil?
      end
    end
  end
end