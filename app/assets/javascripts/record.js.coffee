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

        nodeCount = sigInst.getNodesCount()
        nodesToDelete = []
        # Add colour and transform square plotting to rectangle
        sigInst.iterNodes((node) ->
          type = node['attr']['attributes'][0].val
          subtype = node['attr']['attributes'][1].val
          facets = node['attr']['attributes'][2].val
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
              else
                '#f0f'
          node.size = facets
          node.x = node.x * $(targetElement).width() / $(targetElement).height()
          if nodeCount > 1 and node.degree == 0
            # Drop unconnected
            nodesToDelete.push node.id
        , null)

        window.sigInst = sigInst
        window.nodesToDelete = nodesToDelete

        # Drop nodes which just clutter the display
        sigInst.dropNode(nodesToDelete)
        nodeCount = sigInst.getNodesCount()

        # Draw the graph
        sigInst.draw()

        # Start ForceAtlas2
        sigInst.startForceAtlas2()
        _.delay(() ->
          # Finish calculations
          sigInst.stopForceAtlas2()
          # Zoom out and space from the border
          sigInst.position(
            0.1*$(targetElement).width(),
            0.1*$(targetElement).height(),
            0.8).draw()
        , $(targetElement).attr('data-delay') || 30000)


        sigInst.bind('upnodes', (event) ->
          # Turn node ID (key) into record ID
          id = /\d+$/i.exec(_(event.content).first())[0]
          # Open record with given ID
          window.open('/records/'+id, '_blank')
        )
    )

if (document.addEventListener)
  document.addEventListener(
    "DOMContentLoaded", init_graph('.sigma-expand'), false)
else
  window.onload = init_graph('.sigma-expand')

prettyPrint()