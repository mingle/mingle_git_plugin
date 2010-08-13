# Copyright (c) 2010 ThoughtWorks Inc. (http://thoughtworks.com)
# Licenced under the Apache License, Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0.txt)

require 'time'
unless RUBY_PLATFORM =~ /java/
  require 'open3'
  # this is used only in tests
  class GitClient
    
    cattr_accessor :logging_enabled

    def initialize(master_path, clone_path, style_dir)
      @master_path = master_path
      @clone_path = clone_path
      @style_dir = style_dir
    end

    def repository_empty?
      command = "cd #{@clone_path} && /opt/local/bin/git log -1"
      result = ""
      execute(command) do |stdin, stdout, stderr|
        begin
          result = stdout.readline
        rescue Exception => e
          # do nothing, maybe git barfed
        end
      end
      return !result.starts_with?('commit')
    end

    def log_for_rev(rev)
      log_for_revs(rev, rev).first
    end

    def log_for_revs(from, to)
      raise "Repository is empty!" if repository_empty?

      command = "cd #{@clone_path} && /opt/local/bin/git log #{from} #{to}"
      result = []

      error = ''
      execute(command) do |stdin, stdout, stderr|
        log_entry = {}
        error = stderr.readlines
        stdout.each_line do |line|
          line.strip!
          if line.starts_with?('commit')
            log_entry = {}
            log_entry[:commit_id] = line.sub(/commit /, '')
            log_entry[:description] = ''
            result << log_entry
          elsif line.starts_with?('Author:')
            log_entry[:author] = line.sub(/Author: /, '')
          elsif line.starts_with?('Date:')
            log_entry[:time] = Time.parse(line.sub(/Date:   /, ''))
          else
            log_entry[:description] << line
          end
        end
      end

      raise StandardError.new("Could not execute '#{command}'. The error was:\n#{error}" ) unless error.empty?

      result
    end

    def git_patch_for(commit_id, git_patch)
      command = "cd #{@clone_path} && /opt/local/bin/git log -1 -p #{commit_id} -M"

      error = ''
      execute(command) do |stdin, stdout, stderr|
        keep_globbing = true
        stdout.each_line do |line|
          # keep eating away all content until we find the actual diff
          (keep_globbing = false) if line.starts_with?('diff')
          
          git_patch.add_line(line) unless (keep_globbing || line.starts_with?('similarity index '))

        end
      end

      raise StandardError.new("Could not execute '#{command}'. The error was:\n#{error}" ) unless error.empty?

      git_patch.done_adding_lines
    end

    def binary?(path, commit_id)
      
    end
    
    private
    def execute(command, &block)
      puts "Executing command:\n#{command}\n Called from #{caller}" if GitClient.logging_enabled
      Open3.popen3(command, &block)
    end
  end

else
  raise 'you need to implement git for the jruby platform'
end
