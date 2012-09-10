# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/


# Add Underscore.String to Underscore.js
_.mixin _.string.exports()

# Fetch OAI-PMH feed
$.ajax
  url:      '/oai'
  type:     'GET'
  dataType: 'text'
  data:
    verb: 'ListRecords'
    metadataPrefix: 'rif'
  success: (data) ->
    $('#oaipmh-feed').html _.escapeHTML data
    prettyPrint()
