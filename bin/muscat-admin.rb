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
      
      old_auth = model.singularize.classify.constantize.find("103857")
      references =  old_auth.send(link_model.pluralize.underscore)
      
      references.each do |ref|
        
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
          
          marc.each_by_tag(rtag) do |marctag|
            # Get the remote tags
            
            # Substitute them
            
          end
          
        end
        
      end
      
      #ap old_auth.sources
      
    end
          
  end
  
end