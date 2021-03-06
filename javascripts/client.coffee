context = cubism.context()
    .step(1e4)
    .size(960)

getThing = (database_name, display_name, selector) ->
  context.metric( (start,stop,step,callback)->
    url = "/metric?database=#{database_name}&selector=#{selector}&start=#{start.toISOString()}&stop=#{stop.toISOString()}&step=#{step}"
    d3.json url, (data) ->
      return callback(new Error('could not load data')) unless data
      callback(null, data)

  , display_name)

$ ->
  d3.select("#cubism").selectAll(".axis")
      .data(["top", "bottom"])
      .enter().append("div")
      .attr("class", (d)-> return d + " axis" )
      .each((d) -> d3.select(this).call(context.axis().ticks(12).orient(d)))

  d3.select("#cubism").append("div")
      .attr("class", "rule")
      .call(context.rule())

  collected_data = []
  $.each(database_names, (i, name) ->
    name_parts = name.split('_')
    order = parseInt(name_parts[1])
    display_name = "#{name_parts[name_parts.length - 1]} conn count"
    collected_data[order] = getThing(name, display_name, 'connections')
    return true
  )

  d3.select("#cubism").selectAll(".horizon")
      .data(collected_data)
      .enter().insert("div", ".bottom")
      .attr("class", "horizon")
      .call(context.horizon().height(60)) #.extent([0, 15]))

  context.on("focus", (i) ->
    d3.selectAll(".value").style("right", i == null ? null : context.size() - i + "px")
  )




