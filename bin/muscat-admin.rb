#!/usr/bin/env ruby
APP_PATH = File.expand_path('../../config/application',  __FILE__)
require File.expand_path('../../config/boot',  __FILE__)
require APP_PATH
# set Rails.env here if desired
Rails.application.require_environment!

require 'rubygems'
require 'commander/import'
require 'progress_bar'

program :version, '0.0.1'
program :description, 'Muscat Administration Console'

command :publish do |c|
  c.syntax = 'muscat-admin publish [options]'
  c.summary = ''
  c.description = ''
  c.example 'description', 'ex'

  c.action do |args, options|
    if args.count > 0
      folder_name = args[0]
      folders = Folder.where(name: folder_name)
      if folders.count < 1
        puts "Folder #{folder_name} does not exist."
        return
      end
      if folders.first.folder_type != "Source"
        puts "Folder #{folder_name} does not contain Sources, it is of type #{f.first.folder_type}"
        return
      end
    else
      folders = Folder.where(folder_type: "Source").map {|r| r.name}
      folder_name = choose("Please choose a folder.", *folders)
      folder = Folder.where(name: folder_name).first
    end

    folder.folder_items.each do |fi|
      fi.item.wf_stage = "published"
      fi.item.save
    end

  end  
end

command :check do |c|
  c.syntax = 'muscat-admin check_links [options]'
  c.summary = ''
  c.description = ''
  c.example 'description', 'ex'
  
  # Check that the 772s and 773s match the cached source_id
  # if there is a 772 it means the remote source source_id points to us
  # if there is a 773 it means this source_id points to the other
  # if there is a source_id but no 773 fix it (remove source_id)
  # There should be only a 773!
  
  c.action do |args, options|
    
    id = args[0]
    
    pb = ProgressBar.new(Source.all.count)
    
    Source.all.each do |s|
      pb.increment!
      src = s#Source.find(id)
      begin
        marc = src.marc
        x = marc.to_marc
      rescue => e
        puts e.exception
        puts "Could not load MARC for #{src.id}"
        next
      end
    
      total_773 = marc.by_tags("773").count
      if total_773 > 1
        puts "#{src.id} has #{total_773} 773 fields, considering only the first"
      end
    
      t = marc.first_occurance("773", "w")
    
      if t && t.content
        if t.content != src.source_id
          puts "#{src.id} the source_id #{src.source_id} does not match the first 773 #{t.content}"
        end
      else
        if src.source_id
          puts "#{src.id} has source_id #{src.source_id} but no 773 tag"
        end
      end
    end
    
  end
end  

command :merge do |c|
  
  c.action do |args, options|
    model = args[0].classify
    auth1 = args[1]
    auth2 = args[2]
    
    klass = model.singularize.classify.constantize
    dest_auth = klass.find(auth1)
    if !dest_auth
      puts "Could not find a #{model} with id #{auth1}"
      return
    end
    
    src_auth = klass.find(auth2)
    if !src_auth
      puts "Could not find a #{model} with id #{auth2}"
      return
    end
    
    links_to = ["Source"]
    
    links_to.each do |link_model|
      
      # 1) Get the remote tags which point to this authority file model
      remote_tags = []
      model_marc_conf = MarcConfigCache.get_configuration link_model.downcase
      
      model_marc_conf.get_foreign_tag_groups.each do |foreign_tag|
        model_marc_conf.each_subtag(foreign_tag) do |subtag|
          tag_letter = subtag[0]
          if model_marc_conf.is_foreign?(foreign_tag, tag_letter)
            # Note: in the configuration only ID has the Foreign class
            # The others use ^0
            next if model_marc_conf.get_foreign_class(foreign_tag, tag_letter) != model
            remote_tags << foreign_tag if !remote_tags.include? foreign_tag
          end
        end
      end
      
      references =  src_auth.send(link_model.pluralize.underscore)
      
      if references.count == 0
        puts "#{model} #{src_auth.id} has no references to #{link_model}"
        next
      else
        puts "Processing #{references.count} #{link_model}(s) related to #{model} #{src_auth.id}"
      end
      
      pb = ProgressBar.new(references.count)
      
      references.each do |ref|
        
        pb.increment!
        
        # load the remote marc
        begin
          marc = ref.marc
          x = marc.to_marc
        rescue => e
          puts e.exception
          puts "Could not load MARC for #{ref.id}"
          next
        end
        
        # Now that we have marc let's go through the tags to update
        remote_tags.each do |rtag|
          
          master = model_marc_conf.get_master(rtag)
          
          marc.each_by_tag(rtag) do |marctag|
            # Get the remote tags
            # is this tag pointing to the id of auth2?
            marc_id = marctag.fetch_first_by_tag(master)
            if !marc_id || !marc_id.content
              puts "#{ref.id} tag #{rtag} does not have subtag #{master}"
              next
            end
            
            # Skip if this link is to another auth file
            next if marc_id.content.to_i != src_auth.id
            
            # Substitute them
            # Remove all a and d tags
            marctag.each_by_tag("a") {|t| t.destroy_yourself}
            marctag.each_by_tag("d") {|t| t.destroy_yourself}
            
            # Also remove all the old underscores, not used anymore
            marctag.each_by_tag("_") {|t| t.destroy_yourself}
            
            # Sunstitute the id in $0 with the new auth file
            # For some reason just substituting marc_id.content does not work
            # Delete it and make a new tag
            marc_id.destroy_yourself
            
            marctag.add(MarcNode.new(link_model.downcase, master, dest_auth.id, nil))
            marctag.sort_alphabetically
            
          end
          
        end
        
        # Marc remains cached even after save
        # Create a new marc class and load it
        # with the source from old marc
        # it will resolve externals
        # only then save the source
        classname = "Marc" + link_model
        dyna_marc_class = Kernel.const_get(classname)
      
        new_marc = dyna_marc_class.new(marc.to_marc)
        new_marc.load_source(true)
        
        # set marc and save
        ref.marc = new_marc
        ref.save
        
      end
      
      
    end
    
  end
  
end