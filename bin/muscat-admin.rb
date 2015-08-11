#!/usr/bin/env ruby

require 'rubygems'
require 'commander/import'

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

