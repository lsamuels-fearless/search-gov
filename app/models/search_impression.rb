class SearchImpression
  IRRELEVANT_KEYS = %w(access_key action api_key controller cx m utf8)

  def self.log(search, vertical, params, request)
    request_pairs = { clientip: request.remote_ip, request: request.url, referrer: request.referer, user_agent: request.user_agent }
    request_pairs[:diagnostics] = flatten_diagnostics_hash(search.diagnostics)
    relevant_params = params.reject { |k, v| IRRELEVANT_KEYS.include?(k.to_s) || k.to_s.include?('.') }
    hash = request_pairs.merge(time: Time.now.to_formatted_s(:db),
                               vertical: vertical,
                               modules: search.modules.join('|'),
                               params: relevant_params)
    Rails.logger.info("[Search Impression] #{hash.to_json}")
  end

  def self.flatten_diagnostics_hash(diagnostics_hash)
    diagnostics_hash.keys.sort.map { |k| diagnostics_hash[k].merge(module: k) }
  end
end
