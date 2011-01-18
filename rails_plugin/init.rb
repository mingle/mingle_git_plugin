# Copyright (c) 2011 ThoughtWorks Inc. (http://thoughtworks.com)
# Licenced under the Apache License, Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0.txt)

COMPATIBLE_MINGLE_VERSIONS = ['3_3', '3_2', 'unstable_3_2', 'unsupported-developer-build']


def load_all_files_in(dir)
  Dir[File.join(File.dirname(__FILE__), dir, '**', '*.rb')].each do |f|
    require f
  end
end

if COMPATIBLE_MINGLE_VERSIONS.include?(MINGLE_VERSION)

  begin
    
    ['app/controllers', 'app/models', 'config'].each do |dir|
      load_all_files_in(dir)
    end
    
    MinglePlugins::Source.register(GitConfiguration)
  rescue Exception => e
    ActiveRecord::Base.logger.error "Unable to register GitConfiguration. Root cause: #{e}"
  end
  
else
  ActiveRecord::Base.logger.warn %{
    The plugin mingle_git_plugin is not compatible with Mingle version #{MINGLE_VERSION}. 
    This plugin only works with Mingle version(s): #{COMPATIBLE_MINGLE_VERSIONS.join(', ')}.
    The plugin mingle_git_plugin will not be available.
  }
end

if defined?(RAILS_ENV)
  GitConfiguration.class_eval do
    include ::API::XMLSerializer
    serializes_as :id, :marked_for_deletion, :project, :repository_path, :username
  end
end
