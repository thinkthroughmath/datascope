require 'sequel'
require 'json'
DB = Sequel.connect(ENV['DATABASE_URL'], :max_connections => 10)
TARGET_DBS = Hash[ENV.select { |k, v|
  k.match(/^TARGET_/)
}.map { |k, v|
  [k, Sequel.connect(v, :max_connections => 10)]
}]

module StatCollector
  extend self

  def stats(name, target_db)
    {
      name: name,
      connections: connections(target_db)
    }
  end

  def capture_stats!
    output = ""
    TARGET_DBS.each do |name, target_db|
      s = stats(name, target_db)
      DB[:stats] << {data: s.to_json}
      output << "db=#{s[:name]} connections=#{s[:connections]}\n"
    end
    output
  end

  def reset_target_stats!
    TARGET_DBS.each do |name, target_db|
      target_db.execute "select pg_stat_statements_reset()"
    end
  end

  def connections(target_db)
    target_db[:pg_stat_activity].count
  end

  def stat_statements(target_db)
    target_db[:pg_stat_statements]
      .select(:query, :calls, :total_time)
      .exclude(query: '<insufficient privilege>')
      .all
  end

  def cache_hit(target_db)
    target_db[:pg_statio_user_tables]
      .select("(sum(heap_blks_hit) - sum(heap_blks_read)) / sum(heap_blks_hit) as ratio".lit)
      .first[:ratio]
      .to_f
  end

  def locks(target_db)
    target_db[:pg_locks].exclude(:granted).count
  end
end
