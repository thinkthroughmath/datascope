require 'sinatra'
require 'sequel'
require 'json'
require 'haml'
DB = Sequel.connect(ENV['DATABASE_URL'], :max_connections => 10)

TARGET_DB_NAMES = ENV.select { |k, v|
  k.match(/^TARGET_/)
}.keys

class Datascope < Sinatra::Application
  get '/' do
    haml :index
  end

  get '/metric' do
    database = params[:database]
    selector =  params[:selector]
    start = DateTime.parse params[:start]
    stop = DateTime.parse params[:stop]
    step = params[:step].to_i

    parsed = []

    DB[:stats].select(:data).where(created_at: (start..stop)).each do |row|
      parsed << JSON.parse(row[:data])
    end

    if database
      parsed = parsed.select{ |row| row["name"] == database }
    end

    if selector == 'query_1'
      values = values_by_regex parsed, /with packed/i, :ms
    elsif selector == 'select'
      values = values_by_regex parsed, /select/i
    elsif selector == 'select_ms'
      values = values_by_regex parsed, /select/i, :ms
    elsif selector == 'update'
      values = values_by_regex parsed, /update/i
    elsif selector == 'update_ms'
      values = values_by_regex parsed, /update/i, :ms
    elsif selector == 'insert'
      values = values_by_regex parsed, /insert/i
    elsif selector == 'insert_ms'
      values = values_by_regex parsed, /insert/i, :ms
    elsif selector == 'delete'
      values = values_by_regex parsed, /delete/i
    else
      values = parsed.map{|d| d[selector] }
    end

    JSON.dump values
  end

  def values_by_regex(parsed, regex, ms=false)
    vals = parsed.map { |row|
      row['stat_statements']
        .select  {|h| h['query'] =~ regex }
        .sort_by {|h| h['total_time']}
        .inject([0,0]) { |m,h| [m.first + h['calls'].to_i, m.last + h['total_time'].to_f ] }
    }

    if ms
      vals.map {|pair| pair.first.zero? ? 0 : pair.last/pair.first}
    else
      vals.map(&:first)
    end
  end

end
