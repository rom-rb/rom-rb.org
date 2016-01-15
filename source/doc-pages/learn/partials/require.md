Call `require` for `rom-repository` and each adapter you want to use in your project:

```ruby 
require 'rom-repository'  # repository makes simple operations easy 

# ... and don't forget adapters
require 'rom-sql'         # use this if you installed sql adapter
require 'rom-http'        # and this for http
require 'rom-couchdb'     # ... etc 

```