import Graph from "graphology";
import Sigma from "sigma";
import { bindWebGLLayer, createContoursProgram } from "@sigma/layer-webgl";

document.addEventListener('DOMContentLoaded', () => {
    const container = document.getElementById("node-graph");
    if (!container) return;

    fetch('data/node-graph.json')
        .then(res => res.json())
        .then(data => {
            const root = document.documentElement;
            const background = getComputedStyle(root).getPropertyValue('--background').trim();
            const onSurface = getComputedStyle(root).getPropertyValue('--on-surface').trim();
            const onSurfaceDim = getComputedStyle(root).getPropertyValue('--on-surface-dim').trim();
            const accentGreen = getComputedStyle(root).getPropertyValue('--on-accent-green').trim();
            const fontAntilag = getComputedStyle(root).getPropertyValue('--font-antilag').trim();
            const textBase = getComputedStyle(root).getPropertyValue('--text-base').trim();
            
            // Create graph
            const graph = new Graph();

            data.nodes.forEach(node => {
                graph.addNode(node.id, {
                label: node.label,
                x: Math.random(),
                y: Math.random(),
                size: 10,
                color: node.id.startsWith('bit') ? onSurface : accentGreen
                });
            });

            data.edges.forEach(edge => {
                graph.addEdge(edge.source, edge.target, { size: 2, color: onSurfaceDim });
            });

            const sigmaInstance = new Sigma(graph, container, {
                stagePadding: 265,
                labelColor: { color: onSurface }, 
                labelFont: fontAntilag,
                labelSize: textBase,
                renderLabels: false,
                maxCameraRatio: 1,
                minCameraRatio: 0.25,
            });

            sigmaInstance.on("enterNode", () => {
                container.style.cursor = 'pointer';
            });
              
            sigmaInstance.on("leaveNode", () => {
                container.style.cursor = 'default';
            });   

            // Make nodes drsggable
            let draggedNode = null;
            let isDragging = false;
      
            sigmaInstance.on("downNode", ({ node }) => {
              draggedNode = node;
              isDragging = true;
              graph.setNodeAttribute(draggedNode, "highlighted", true);
            });
      
            sigmaInstance.on("moveBody", ({ event }) => {
              if (!isDragging || !draggedNode) return;
              const pos = sigmaInstance.viewportToGraph(event);
              graph.setNodeAttribute(draggedNode, "x", pos.x);
              graph.setNodeAttribute(draggedNode, "y", pos.y);
              event.preventSigmaDefault();
              event.original.preventDefault();
              event.original.stopPropagation();
            });
      
            const endDrag = () => {
              if (draggedNode) graph.removeNodeAttribute(draggedNode, "highlighted");
              draggedNode = null;
              isDragging = false;
            };
      
            sigmaInstance.on("upNode", endDrag);
            sigmaInstance.on("upStage", endDrag);

            bindWebGLLayer(
                "metaballs",
                sigmaInstance,
                createContoursProgram(graph.nodes(), {
                  radius: 150,
                  feather: 1,
                  border: { color: onSurfaceDim, thickness: 8 },
                  levels: [
                    { color: background, threshold: 0.1 },
                    { color: background, threshold: 0.5 },
                    { color: background, threshold: 0.9 },
                  ],
                })
              );
        });
});
