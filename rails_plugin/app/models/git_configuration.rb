require 'uri'
class GitConfiguration < ActiveRecord::Base

  # supplies create_or_update method that keeps controller simple
  # supplies mark_for_deletion method used by mingle to manage config lifecycle
  include RepositoryModelHelper
  
  # mingle model utility that will strip leading and trailing whitespace from all attributes
  strip_on_write
  # configuration must belong to a project
  belongs_to :project
  validates_presence_of :repository_path
  before_save :encrypt_password
  after_create :remove_cache_dirs
  after_destroy :remove_cache_dirs

  class << self
    # *returns*: Human-readable name of SCM type, used in source config droplist
    def display_name
      "Git"
    end
  end

  # *returns*: git-specific terms for mingle display
  def vocabulary
    {
      'revision' => 'commit',
      'committed' => 'author',
      'repository' => 'repository',
      'head' => 'master',
      'short_identifier_length' => 12
    }
  end

  # *returns*: table header and row partials to be used in source directory browser
  def view_partials
    {:node_table_header => 'git_source/node_table_header', 
     :node_table_row => 'git_source/node_table_row' }
  end

  
  # *returns* whether or not the repository content is ready to be browsed on the source tab
  def source_browsing_ready?
    initialized?
  end

  # prevent user from storing any userinfo in repostory path
  def validate
    super
    
    begin
      uri = URI.parse(repository_path)
    rescue
      errors.add_to_base(%{
        The repository path appears to be of invalid URI format.
        Please check your repository path.
      })
    end

    if uri && !uri.password.blank?
      errors.add_to_base(%{
        Do not store repository password as part of the URL. 
        Please use the supplied form field.
      }) 
    end
  end
  
  # *returns*: an instance of GitRepository for Mercurial repository sepcified by this configuration
  def repository
    # the local path where the repo is cloned
    clone_path = File.expand_path(File.join(MINGLE_DATA_DIR, "git", id.to_s, 'repository'))
    # the location for templates that renders the repo in mingle
    style_dir = File.expand_path("#{File.dirname(__FILE__)}/../templates")
    
    source_browser_cache_path = File.expand_path(File.join(MINGLE_DATA_DIR, 'git', id.to_s, 'source_browser_cache'))
    mingle_rev_repos = GitMingleRevisionRepository.new(project)
    
    scm_client = GitClient.new(repository_path_with_userinfo, clone_path, style_dir)
    
    source_browser = GitSourceBrowser.new(scm_client, source_browser_cache_path, mingle_rev_repos)
    
    repository = HgRepository.new(scm_client, source_browser)
    GitRepositoryClone.new(GitSourceBrowserSynch.new(repository, source_browser))
  end

  # Constructs a url with the auth info. 
  # This is useful in case a user provides just a url and the user/pass is stored in the db.
  def repository_path_with_userinfo
    uri = URI.parse(repository_path)
    return repository_path if uri.scheme.blank?

    if !username.blank? && !password.blank?
      "#{uri.scheme}://#{username}:#{password}@#{host_port_path_from(uri)}"
    elsif !username.blank?
      "#{uri.scheme}://#{username}@#{host_port_path_from(uri)}"
    elsif !uri.user.blank? && password.blank?
      "#{uri.scheme}://#{uri.user}@#{host_port_path_from(uri)}"
    elsif !uri.user.blank? && !password.blank?
      "#{uri.scheme}://#{uri.user}:#{password}@#{host_port_path_from(uri)}"
    else
      repository_path
    end
  end
  
  def host_port_path_from(uri)
    result = "#{uri.host}"
    result << ":#{uri.port}" unless uri.port.blank?
    result << "#{uri.path}"
    result
  end

  private
  
  # use mingle project's encryption capability to protect password in DB
  def encrypt_password
    pwd_attr = @attributes['password']
    if !pwd_attr.blank?
      write_attribute(:password, project.encrypt(pwd_attr))
    else
      write_attribute(:password, pwd_attr)
    end
  end

  def remove_cache_dirs
    FileUtils.rm_rf(File.expand_path(File.join(MINGLE_DATA_DIR, 'git', id.to_s)))
  end
  
end
