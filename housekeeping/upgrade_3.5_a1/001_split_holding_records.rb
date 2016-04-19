pb = ProgressBar.new(Source.all.count)

Source.all.each do |source|
  
  marc = source.marc
  marc.load_source
  
  count = 0
  
  marc.each_by_tag("852") do |t|
    
    # Make a nice new holding record
    holding = Holding.new
    new_marc = MarcHolding.new(File.read("#{Rails.root}/config/marc/#{RISM::MARC}/holding/default.marc"))
    new_marc.load_source false
    
    # Kill old 852s
    new_marc.each_by_tag("852") {|t2| t2.destroy_yourself}
    
    new_852 = t.deep_copy
    new_marc.root.children.insert(new_marc.get_insert_position("852"), new_852)
    
    new_marc.suppress_scaffold_links
    new_marc.import
    
    holding.marc = new_marc
    holding.source = source
    holding.save
    
    count += 1
  end

  if count != source.holdings.count
    puts "OH NOOOO"
    ENDMENOW
  end
  
  ts = marc.root.fetch_all_by_tag("852") 
  ts.each {|t2| t2.destroy_yourself}
  
	source.suppress_update_77x
	source.suppress_update_count
  source.suppress_reindex
  
  new_marc_txt = marc.to_marc
  new_marc = MarcSource.new(new_marc_txt, source.record_type)
  source.marc = new_marc

  source.save
  
  pb.increment!
  
end