#!/usr/bin/env ruby
APP_PATH = File.expand_path('../../config/application',  __FILE__)
require File.expand_path('../../config/boot',  __FILE__)
require APP_PATH
# set Rails.env here if desired
Rails.application.require_environment!

require 'rubygems'
require 'commander/import'
require 'progress_bar'

require 'util/marc_auth_merge'

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
    
    unreadable = {}
    
    pb = ProgressBar.new(Source.all.count)
    
    Source.all.each do |s|
      pb.increment!
      src = s#Source.find(id)
      begin
        marc = src.marc
        x = marc.to_marc
      rescue => e
        #puts e.exception
        #puts "Could not load MARC for #{src.id}"
        unreadable[src.id] = e.exception
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
    
    if unreadable.count > 0
      puts "There are some unloadable records:"
      puts unreadable
    end
    
  end
end  

class Array
    def find_dups
        uniq.map {|v| (self - [v]).size < (self.size - 1) ? v : nil}.compact
    end
end

command :link_duplicates do |c|
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
    
    unreadable = {}
    
    pb = ProgressBar.new(Source.all.count)
    
    Source.all.each do |s|
      pb.increment!
      src = s#Source.find(id)
      begin
        marc = src.marc
        x = marc.to_marc
      rescue => e
        #puts e.exception
        #puts "Could not load MARC for #{src.id}"
        unreadable[src.id] = e.exception
        next
      end
    
      ids = []
      marc.each_by_tag("772") do |tag|
        t = tag.fetch_first_by_tag("w")
        ids << t.content if t && t.content
      end
      
      if ids.find_dups.count > 0
        puts s.id
        ap ids.find_dups
      end
      
    end #source.all
    
    if unreadable.count > 0
      puts "There are some unloadable records:"
      puts unreadable
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
    
    merger = Util::MarcAuthMerge.new(model, dest_auth, src_auth)
    merger.show_progress
    merger.merge_records
    
    if merger.errors?
      puts "Unloadable records"
      puts merger.get_unloadable
      puts "Unsavable records"
      puts merger.get_unsavable
    end
    
  end
  
end