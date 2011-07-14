# Copyright (c) 2011 ThoughtWorks Inc. (http://thoughtworks.com)
# Licenced under the Apache License, Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0.txt)

def load_all_files_in(dir)
  Dir[File.join(File.dirname(__FILE__), dir, '**', '*.rb')].each do |f|
    require f
  end
end

begin
  ['app/controllers', 'app/models', 'config'].each do |dir|
    load_all_files_in(dir)
  end
  
  MinglePlugins::Source.register(GitConfiguration)
rescue Exception => e
  ActiveRecord::Base.logger.error "Unable to register GitConfiguration. Root cause: #{e}"
end
  
if defined?(RAILS_ENV)
  GitConfiguration.class_eval do
    include ::API::XMLSerializer
    serializes_as :id, :marked_for_deletion, :project, :repository_path, :username
  end
end
