# Copyright (c) 2010 ThoughtWorks Inc. (http://thoughtworks.com)
# Licenced under the Apache License, Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0.txt)

module GitUtils
  module_function
  def extract_leading_rev_hash(str)
    return $1 if /^([0-9a-fA-F]{40}) / =~ str
  end
end