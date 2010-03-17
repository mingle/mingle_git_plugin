require 'rubygems'

unless RUBY_PLATFORM =~ /java/
  $LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__) , '../../tools/jruby-1.2.0/lib/ruby/gems/1.8/gems/rake-0.8.4/lib'))
  $LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__) , '../../tools/jruby-1.2.0/lib/ruby/gems/1.8/gems/activesupport-2.3.3/lib'))
  $LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__) , '../../tools/jruby-1.2.0/lib/ruby/gems/1.8/gems/activerecord-2.3.3/lib'))
end

require 'active_support'
require 'active_record'

require 'rake'
require 'test/unit'
# require 'ostruct'
require 'md5'
require 'fileutils'

include FileUtils

# don't log rake output to console, it's messes up the output
RakeFileUtils.verbose_flag = false

# load up stuff that mingle provides, but is not available in this test harness
require File.expand_path(File.join(File.dirname(__FILE__) , 'mingle_helper'))

# set the test env
RAILS_ENV = 'test'
TMP_DIR = File.expand_path(File.join(File.dirname(__FILE__) , '../tmp/test'))
TEST_REPOS_TMP_DIR = File.expand_path(File.join(File.dirname(__FILE__) , '../tmp/test/test_repositories_from_bundles'))
MINGLE_DATA_DIR = File.join(TMP_DIR , 'mingle_data_dir')
DB_PATH = File.join(TMP_DIR , 'db')

FileUtils.mkdir_p TMP_DIR
FileUtils.mkdir_p MINGLE_DATA_DIR
FileUtils.mkdir_p DB_PATH

# since app/model is not on the LOAD_PATH
Dir[File.dirname(__FILE__) + '/../app/models/*.rb'].each do |lib_file|
  require File.expand_path(lib_file)
end

# setup logger
ActiveRecord::Base.logger = Logger.new($stdout)
ActiveRecord::Base.logger.level = Logger::ERROR

# setup db config and run migration (only works for sqlite3 now)
ActiveRecord::Base.configurations['test'] = {}
ActiveRecord::Base.configurations['test']['database'] = DB_PATH + '/test.db'
if RUBY_PLATFORM =~ /java/
  ActiveRecord::Base.configurations['test']['adapter'] = 'jdbcsqlite3'
else
  require 'sqlite3'
  ActiveRecord::Base.configurations['test']['adapter'] = 'sqlite3'
end
ActiveRecord::Base.establish_connection
ActiveRecord::Migrator.migrate(File.dirname(__FILE__) + '/../db/migrate')

# stub the Mingle Project
class Project
  def encrypt(text)
    "ENCRYPTED" + text
  end

  def decrypt(text)
    text.split("ENCRYPTED").last
  end

  def id
    3487
  end

  def new_record?
    false
  end

  def identifier
    "test_project"
  end
end

class TestRepositoryFactory
  class << self
    def create_repository_without_source_browser(bundle = nil, options = {})
      factory = TestRepositoryFactory.new(bundle, options)
      factory.unbundle
      style_dir = File.expand_path("#{File.dirname(__FILE__)}/../templates")
      # config = GitRepositoryConfiguration.new(nil, factory.dir, nil)
      # config = GitRepositoryConfiguration.new(nil, factory.dir, style_dir)
      hg_client = GitClient.new(nil, factory.dir, nil)
      GitRepository.new(hg_client, nil)
    end

    # def create_repository_with_source_browser(bundle = nil, options = {})
    #      factory = TestRepositoryFactory.new(bundle, options)
    #      factory.unbundle
    #      style_dir = File.expand_path("#{File.dirname(__FILE__)}/../app/templates")
    #      java_hg_client = com.thoughtworks.studios.mingle.hg.hgcmdline::HgClient.new(nil, factory.dir, style_dir)
    #      hg_client = HgClient.new(java_hg_client)
    #      source_browser = HgSourceBrowser.new(
    #        java_hg_client,
    #        factory.source_browser_cache_path,
    #        options[:stub_mingle_revision_repository] || NoOpMingleRevisionRepository.new
    #      )
    #      source_browser.instance_variable_set(:@__cache_path, factory.source_browser_cache_path)
    #      def source_browser.cache_path
    #        @__cache_path
    #      end
    #      repository = HgRepository.new(hg_client, source_browser)
    #      [repository, source_browser]
    #    end

  end

  def initialize(bundle, options)
    @bundle = bundle
    @options = options
  end

  def unbundle
    rm_rf(dir)
    mkdir_p(dir)
    if !File.exist?(File.join(dir, '.git'))
      git_init
      if @bundle
        FileUtils.cp(bundle_path, dir + '/..')
        extract_bundle("#{@bundle}.git.zip")
      end
    end
  end
  #
  #   def use_cached_source_browser_files?
  #     @options[:use_cached_source_browser_files].nil? || @options[:use_cached_source_browser_files] == true
  #   end
  #
    def dir
      @repos_dir ||= repos_path
    end
  #
    def bundle_path
      File.join(File.dirname(__FILE__), 'bundles', "#{@bundle}.git.zip")
    end
  #
  #   def source_browser_path_secret
  #     @source_browser_path_secret ||= if @use_cached_source_browser_files
  #       Digest::MD5.hexdigest(File.new(bundle_path).mtime.utc.to_s)
  #     else
  #       RandomString.size_32
  #     end
  #   end
  #
    def repos_path_secret
      @repos_path_secret ||= Digest::MD5.hexdigest(File.new(bundle_path).mtime.utc.to_s)
    end

    def git_init
      sh "cd #{dir} && git init > /dev/null 2>&1 "
    end

    def extract_bundle(zip_file)
      sh "cd #{dir} && unzip -qo ../#{zip_file}"
    end
  #
  #   def hg_exec(command_string)
  #     `hg --cwd \"#{dir}\" #{command_string}`
  #   end
  #
  #   def source_browser_cache_path
  #     if (@bundle)
  #       File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'tmp', 'test',
  #         'test_source_browser_caches_from_bundles', @bundle, source_browser_path_secret))
  #     else
  #       File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'tmp', 'test',
  #         'test_source_browser_caches_from_bundles', 'empty'))
  #     end
  #   end
  #
    def repos_path
      if (@bundle)
        File.expand_path(File.join(TEST_REPOS_TMP_DIR, @bundle, repos_path_secret))
      else
        File.expand_path(File.join(TEST_REPOS_TMP_DIR, 'empty'))
      end
    end

end