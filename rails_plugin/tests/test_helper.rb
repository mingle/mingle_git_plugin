# Copyright (c) 2010 ThoughtWorks Inc. (http://thoughtworks.com)
# Licenced under the Apache License, Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0.txt)

require 'rubygems'

begin
  gem 'ci_reporter'
  require 'ci/reporter/rake/test_unit_loader.rb'
rescue
  puts '****** ci_reporter gem is not available. Reports will not be generated.'
end

unless RUBY_PLATFORM =~ /java/
  $LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), '../../tools/jruby-1.2.0/lib/ruby/gems/1.8/gems/rake-0.8.4/lib'))
  $LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), '../../tools/jruby-1.2.0/lib/ruby/gems/1.8/gems/activesupport-2.3.3/lib'))
  $LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), '../../tools/jruby-1.2.0/lib/ruby/gems/1.8/gems/activerecord-2.3.3/lib'))
end

$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), '../app/models')))

require 'active_support'
require 'active_record'

require 'rake'
require 'test/unit'
# require 'ostruct'
require 'md5'
require 'fileutils'

require 'pp'
include FileUtils

# don't log rake output to console, it's messes up the output
RakeFileUtils.verbose_flag = false

# load up stuff that mingle provides, but is not available in this test harness
require File.expand_path(File.join(File.dirname(__FILE__), 'mingle_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), 'patch_helper'))

# set the test env
RAILS_ENV = 'test'
TMP_DIR = File.expand_path(File.join(File.dirname(__FILE__), '../tmp/test'))
TEST_REPOS_TMP_DIR = File.expand_path(File.join(File.dirname(__FILE__), '../tmp/test/test_repositories_from_bundles'))
MINGLE_DATA_DIR = File.join(TMP_DIR, 'mingle_data_dir')
DB_PATH = File.join(TMP_DIR, 'db')

FileUtils.mkdir_p TMP_DIR
FileUtils.mkdir_p MINGLE_DATA_DIR
FileUtils.mkdir_p DB_PATH

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
  
  def self.current
    nil
  end
  
end

# PasswordEncryption is a direct copy of Mingle source that allows for the existing
# SVN and Perforce plugins to have fairly simple controllers. Mixing this module into your
# configuration allows for the password field to be automatically encrypted by the project.
#
# This code is included here because HgConfiguration mixes in this model. This
# requires that some definition of the module be present in test code in order for tests to run.
# When deployed to Mingle, Mingle will supply this code.
module PasswordEncryption
  def password=(passw)
    passw = passw.strip
    if !passw.blank?
      write_attribute(:password, project.encrypt(passw))
    else
      write_attribute(:password, passw)
    end
  end

  def password
    ps = super
    return ps if ps.blank?
    project.decrypt(ps)
  end
end

class TestRepositoryFactory
  class << self
    
    def create_client_from_bundle(bundle = nil)
      factory = TestRepositoryFactory.new(bundle)
      factory.unbundle

      GitClient.new(nil, factory.bare_repo_dir)
    end

    def create_repository_without_source_browser(bundle = nil)
      GitRepository.new(create_client_from_bundle(bundle), nil)
    end

    def create_repository_with_source_browser(bundle = nil)
      factory = TestRepositoryFactory.new(bundle)
      factory.unbundle

      git_client = GitClient.new('', factory.bare_repo_dir)

      source_browser = GitSourceBrowser.new(git_client)

      repository = GitRepository.new(git_client, source_browser)
      [repository, source_browser]
    end

  end

  def initialize(bundle)
    @bundle = bundle
  end

  def unbundle
    if @bundle
      
      FileUtils.rm_rf bare_repo_dir
      FileUtils.mkdir_p repos_path
      
      `unzip#{Config::CONFIG['EXEEXT']} -q #{bundle_zip_path} -d #{repos_path}`
    end
  end
  
  def bare_repo_dir
    File.expand_path("#{repos_path}/#{@bundle}.git")
  end
  
  def repos_path
    TEST_REPOS_TMP_DIR
  end
  
  def bundle_zip_path
    File.expand_path(File.join(File.dirname(__FILE__), "bundles/#{@bundle}.git.zip"))
  end

end

# since app/model is not on the LOAD_PATH
Dir[File.dirname(__FILE__) + '/../app/models/*.rb'].each do |lib_file|
  require File.expand_path(lib_file)
end
