# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

init_graph = (selector) ->
  $(selector).each (index, targetElement) ->
    sigInst = sigma.init(targetElement).drawingProperties(
      defaultLabelColor: '#fff'
      edgeColor: 'source'
      defaultEdgeColor: '#aaa'
      nodeHoverColor: 'node',
      defaultNodeHoverColor: '#fff',
      nodeActiveColor: 'node',
      defaultNodeActiveColor: '#fff',
      defaultLabelSize: 14
      defaultLabelBGColor: '#fff'
      defaultLabelHoverColor: '#000'
      labelThreshold: 5
      defaultEdgeType: 'curve'
    ).graphProperties(
      minNodeSize: 1
      maxNodeSize: 5
      minEdgeSize: 1
      maxEdgeSize: 1
    ).mouseProperties(
      minRatio: 0.5
      maxRatio: 32
    )

    # Parse a GEXF encoded file to fill the graph
    # (requires "sigma.parseGexf.js" to be included)
    $.ajax(
      url: $(targetElement).attr('data-href')
      success: (data) ->
        sigInst.parseGexfDocument data

        node_i = 0
        nodeCount = sigInst.getNodesCount()
        nodesToDelete = []
        # Add colour and transform square plotting to rectangle
        sigInst.iterNodes((node) ->
          type = node['attr']['attributes']['type']
          subtype = node['attr']['attributes']['subtype']
          facets = node['attr']['attributes']['facets']
          node.color =
            switch type
              when 'party'
                switch subtype
                  when 'group'
                    '#f60'
                  else
                    '#f00'
              when 'collection'
                '#0f0'
              when 'activity'
                '#44f'
              when 'service'
                '#f0f'
              else
                '#444'
          # Spiral outwards rather than random
          angle = 0.5 * node_i++
          node.x = (1 + 1 * angle) * Math.cos(angle)
          node.y = (1 + 1 * angle) * Math.sin(angle)
          # Rescale
          node.x = node.x * $(targetElement).width() / $(targetElement).height()
          if nodeCount > 1 and node.degree == 0
            # Drop unconnected
            nodesToDelete.push node.id
          node.size = node.degree
        , null)

        window.sigInst = sigInst
        window.nodesToDelete = nodesToDelete

        # Drop nodes which just clutter the display
        sigInst.dropNode(nodesToDelete)
        nodeCount = sigInst.getNodesCount()

        # Draw the graph
        sigInst.draw()

        # Start ForceAtlas2 when we're next free
        _.delay () ->
          sigInst.startForceAtlas2()
        # Stop ForceAtlas after some time
        _.delay(() ->
          # Finish calculations
          sigInst.stopForceAtlas2()
          # Zoom out and space from the border
          sigInst.position(
            0.1*$(targetElement).width(),
            0.1*$(targetElement).height(),
            0.8).draw()
        , $(targetElement).attr('data-delay') || 15000)


        sigInst.bind('upnodes', (event) ->
          # Turn node ID (key) into record ID
          id = /[a-f0-9\-]+$/i.exec(_(event.content).first())[0]
          # Open record with given ID
          window.open('/records/'+id, '_blank')
        )
    )

init_concept_filter = () ->
  set_concept_selection = (type) ->
    if type == ''
      $('#concepts p').removeClass('hidden')
    else
      $('#concepts p').addClass('hidden')
      $('#concepts p[data-type="'+type+'"]').removeClass('hidden')

  $('#concept-type-filter a').each (i, e) ->
    type = $(e).attr('href').substring(2)
    Path.map('#/'+type).to () ->
      set_concept_selection(type)
      $(e).parents('ul').find('li').removeClass('active')
      $(e).parents('li').addClass('active')
  Path.root('#/')
  Path.listen()

$(document).ready (e) ->
  init_graph('.sigma-expand')
  if $('#concept-type-filter').length
    init_concept_filter()

prettyPrint()



