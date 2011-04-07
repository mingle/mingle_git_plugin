# Copyright (c) 2010 ThoughtWorks Inc. (http://thoughtworks.com)
# Licenced under the Apache License, Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0.txt)

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))

class GitUtilsTest < Test::Unit::TestCase
  def test_extracting_leading_rev_hash_should_return_rev_hash_if_str_start_with_40_hash_characters_and_a_space
    assert_equal '5ddfb2b5c0e50992d005845efd3dfe944ea70ba3',
                GitUtils.extract_leading_rev_hash('5ddfb2b5c0e50992d005845efd3dfe944ea70ba3 first commit')
  end
  
  def test_extracting_leading_rev_hash_should_return_nil_if_can_not_extract_rev_hash
    assert_nil GitUtils.extract_leading_rev_hash('tools/jruby-1.2.0/COPYING')
    assert_nil GitUtils.extract_leading_rev_hash('5ddfb2b5c0e50992d005845efd3dfe944ea70ba3')
  end
  
end
