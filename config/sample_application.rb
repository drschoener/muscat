require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module Muscat
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    
    config.autoload_paths << "#{Rails.root}/lib"
  end
end

module RISM
end

#####################################################################################################################
# Globals used for Digital Object displaying
# Tile size to be served from the iip backend - used the Digital Objects (Do*)
VIPS_TILESIZE = '256x256'
# Address of the iip server - used the Digital Objects (Do*)
TILE_SERVER = 'http://localhost/cgi-bin/iipsrv.fcgi'
# This is the backend from where to get the image information (should be same host of the webapp)
DO_HOST = 'http://localhost:3000'
# Path to where the images are stores - used the Digital Objects (Do*)
PATH_TO_PYR_IMAGES = '/path_to_pyr_images'
# Path to the vips image convertor - used the Digital Objects (Do*)
PATH_TO_VIPS = '/opt/local/bin/vips'
# Path to where retreive the ZIP files with the images to import - used the Digital Objects (Do*)
PATH_TO_UPLOADED_IMAGES = '/Users/laurent/data/in_upload'


#Globals used for incipits
# Path to the directory where the PAE -> ABC -> PNG convertors are installed (if selected by RISM::USE_VEROVIO=false)
INCIPIT_BINARIES = "/path_to_incipit_binaries"
# The pae2kern binary (see http://museinfo.sapp.org)
PAE2KERN = "#{INCIPIT_BINARIES}/pae2kern"
# The hum2abc binary (see http://museinfo.sapp.org)
HUM2ABC = "#{INCIPIT_BINARIES}/hum2abc"
# The abcm2ps binary (see http://moinejf.free.fr/)
ABCM2PS = "#{INCIPIT_BINARIES}/abcm2ps"
# The eps2png script (see http://search.cpan.org/dist/eps2png/)
EPS2PNG = "#{INCIPIT_BINARIES}/eps2png"
# The eps2pdf binary -  the shebang for perl needs to be added in the script and it can be tested with irb (see http://www.ctan.org/pkg/epstopdf)
EPS2PDF = "#{INCIPIT_BINARIES}/epstopdf" 
# The krn2json binary (undocumented)
KRN2JSON = "#{INCIPIT_BINARIES}/krn2json"

# Path to the Verovio binary, if used to generate incipits by RISM::USE_VEROVIO=true
VEROVIO = "/usr/local/bin/verovio"
# Path do the Aruspix helper data
VEROVIO_DATA = "/usr/local/share/verovio"
# Path to rsvg for converting verovio svn in png
RSVG="/usr/local/bin/rsvg"

# Path to tindex, used to index for musical incipits with Themefinder (see http://www.themefinder.org)
TINDEX = "#{INCIPIT_BINARIES}/tindex"
# Path to themax, used to search for musical incipits with Themefinder (see http://www.themefinder.org)
THEMAX = "#{INCIPIT_BINARIES}/themax"

# Path to Xalan, used for transforming a RISM MarcXML record in MEI or TEI
XALAN = "path_to"
# Path to the stylesheets used for the transformation to MEI
XSL_MEI = "#{Rails.root}/public/xsl/rism2mei-2012.xsl"
# Path to the stylesheets used for the transformation to TEI
XSL_TEI = "#{Rails.root}/public/xsl/rism2tei-2012.xsl"
# Path to the temp path used to store the incipit search queries
TINDEX_TMP_PATH = "#{Rails.root}/tmp/tindex_queries/"
# Path to the incipit query DB generated by tindex
TINDEX_PATH = "#{Rails.root}/tindex.idx"
#####################################################################################################################

# Mime types for MEI files
Mime::Type.register "application/xml", :mei
# Mime types for TEI files
Mime::Type.register "application/xml", :tei
# Mime types for download of MARC records.
Mime::Type.register "application/marc", :marc
# Same as above but with txt extension.
Mime::Type.register "application/txt", :txt

