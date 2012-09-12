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
      labelThreshold: 6
      defaultEdgeType: 'curve'
    ).graphProperties(
      minNodeSize: 0.5
      maxNodeSize: 5
      minEdgeSize: 1
      maxEdgeSize: 1
    ).mouseProperties(
      maxRatio: 16
    )

    # Parse a GEXF encoded file to fill the graph
    # (requires "sigma.parseGexf.js" to be included)
    sigInst.parseGexf '/records.gexf'

    # Add colour and transform square plotting to rectangle
    sigInst.iterNodes((node) ->
      type = node['attr']['attributes'][0].val
      subtype = node['attr']['attributes'][1].val
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
            '#00f'
          else
            '#f0f'
      node.x = node.x * $(targetElement).width() / $(targetElement).height()
    , null)

    # Draw the graph
    sigInst.draw()

    # Start ForceAtlas2
    sigInst.startForceAtlas2()
    _.delay(() ->
      sigInst.stopForceAtlas2()
      sigInst.position(0,0,1).draw();
    , 6000)


    sigInst.bind('upnodes', (event) ->
      console.log _(event.content).first
      window.open('/records/' + _(event.content).first(), '_blank')
    )

    window.sigInst = sigInst

if (document.addEventListener)
  document.addEventListener(
    "DOMContentLoaded", init_graph('#global-gexf-graph'), false)
else
  window.onload = init_graph('#global-gexf-graph')

prettyPrint()