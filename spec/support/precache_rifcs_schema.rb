require 'vcr'

VCR.use_cassette('lookup_rifcs_schema') do
  # Pre-cache so we can use later
  Miletus::NamespaceHelper.ns_by_prefix('rif').schema
end