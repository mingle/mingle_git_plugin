# Copyright (c) 2010 ThoughtWorks Inc. (http://thoughtworks.com)
# Licenced under the Apache License, Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0.txt)

ActionController::Routing::Routes.draw do |map|
  map.with_options :controller => 'changesets' do |changesets|
    changesets.changeset 'projects/:project_id/changesets/:rev', :action => 'show'
  end
  
  map.with_options :controller => 'git_source' do |controller|
    controller.connect 'projects/:project_id/git_source/load_latest_info', :action => 'load_latest_info'
  end
  
  map.with_options :controller => 'repository' do |git_configuration|
    git_configuration.git_configurations_show 'projects/:project_id/git_configurations', :action => 'index', :conditions => {:method => :get}, :repository_type => "GitConfiguration", :api_version => "v2"
    
    git_configuration.rest_git_configurations_index 'api/v2/projects/:project_id/git_configurations.xml', :action => 'index', :conditions => {:method => :get}, :format => 'xml', :repository_type => "GitConfiguration", :api_version => "v2"
    git_configuration.rest_git_configurations_show 'api/v2/projects/:project_id/git_configurations/:id.xml', :action => 'show', :conditions => {:method => :get}, :format => 'xml', :repository_type => "GitConfiguration", :api_version => "v2"
    git_configuration.rest_git_configurations_create_or_update 'api/v2/projects/:project_id/git_configurations.xml', :action => 'save', :conditions => {:method => [:put, :post]}, :format => 'xml', :repository_type => "GitConfiguration", :api_version => "v2"
    git_configuration.rest_git_configurations_update 'api/v2/projects/:project_id/git_configurations/:id.xml', :action => 'save', :conditions => {:method => :put}, :format => 'xml', :repository_type => "GitConfiguration", :api_version => "v2"
    git_configuration.map 'projects/:project_id/git_configurations.xml', :action => 'unsupported_api_call'
    git_configuration.map 'projects/:project_id/git_configurations/:id.xml', :action => 'unsupported_api_call'
  end

end