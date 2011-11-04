require 'pathname'

# Add all external dependencies for the plugin here
require 'dm-constraints'
require 'dm-validations'
require 'dm-ar-finders'

require 'active_support/core_ext/module/delegation'

# Require plugin-files

dir = File.dirname(__FILE__) + '/dm-cti/'

require dir + 'inheritable.rb'

# Include the plugin in Resource
DataMapper::Model.append_extensions DataMapper::CTI::Inheritable
