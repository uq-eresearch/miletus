# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

init_graph = (selector) ->
  $(selector).each (index, targetElement) ->
    sigInst = sigma.init(targetElement).drawingProperties(
      defaultLabelColor: '#fff'
      edgeColor: 'default'
      defaultEdgeColor: '#aaa'
      nodeHoverColor: 'default',
      defaultNodeHoverColor: '#fff',
      nodeActiveColor: 'default',
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

    # Draw the graph
    sigInst.draw()

    # Start ForceAtlas2
    sigInst.startForceAtlas2()
    _.delay(() ->
      sigInst.stopForceAtlas2()
      sigInst.position(0,0,1).draw();
    , 5000)


    sigInst.bind('upnodes', (event) ->
      console.log _(event.content).first
      window.open('/records/' + _(event.content).first(), '_blank')
    )

    window.sigInst = sigInst
    sigInst.iterNodes((node) ->
      node.color = '#bfb'
    , null)

if (document.addEventListener)
  document.addEventListener(
    "DOMContentLoaded", init_graph('#global-gexf-graph'), false)
else
  window.onload = init_graph('#global-gexf-graph')

prettyPrint()