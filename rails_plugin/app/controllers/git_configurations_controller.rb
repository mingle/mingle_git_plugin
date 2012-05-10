# Copyright (c) 2011 ThoughtWorks Inc. (http://thoughtworks.com)
# Licenced under the Apache License, Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0.txt)

class GitConfigurationsController < ProjectApplicationController

  verify :method => :post, :only => [ :save, :create ]
  verify :method => :put, :only => [ :update ]

  privileges UserAccess::PrivilegeLevel::PROJECT_ADMIN => ['index', 'save', 'update', 'show', 'create']

  def current_tab
    Project::ADMIN_TAB_INFO
  end

  def admin_action_name
    super.merge(:controller => 'repository')
  end

  def show
    @git_configuration = GitConfiguration.find(:first, :conditions => ["marked_for_deletion = ? AND project_id = ?", false, @project.id])
    respond_to do |format|
      format.xml do
        if @git_configuration 
          render :xml => @git_configuration.to_xml
        else
          render :xml => "No Git configuration found in project #{@project.identifier}.", :status => 404
        end
      end
    end
  end

  def update
    @git_configuration = GitConfiguration.find_by_id(params[:id])
    create_or_update if @git_configuration
    
    respond_to do |format|
      format.xml do
        if @git_configuration.nil?
          render :xml => "No Git configuration found in project #{@project.identifier} with id #{params[:id]}.", :status => 404
        elsif @git_configuration.errors.empty?
          render :xml => @git_configuration.to_xml
        else
          render :xml => @git_configuration.errors.to_xml, :status => 422
        end
      end
    end
  end

  def create
    create_or_update
    respond_to do |format|
      format.xml do
        if @git_configuration.errors.empty?
          head :created, :location => url_for(:action => :show, :format => 'xml', :id => @git_configuration.id)
        else
          render :xml => @git_configuration.errors.to_xml, :status => 422
        end
      end
    end
  end

  def create_or_update
    @git_configuration = GitConfiguration.create_or_update(@project.id, params[:id], params[:git_configuration])
  end

end