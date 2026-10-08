<template>
  <div class="graph-canvas-wrap">
    <div ref="containerEl" class="graph-canvas" />

    <div class="graph-toolbar">
      <button type="button" class="toolbar-btn" :aria-label="t('graph.zoomIn')" @click="zoomBy(1.3)">+</button>
      <button type="button" class="toolbar-btn" :aria-label="t('graph.zoomOut')" @click="zoomBy(1 / 1.3)">
        &minus;
      </button>
      <select v-model="keywordFilter" class="toolbar-select" :aria-label="t('graph.filterByKeyword')">
        <option value="">{{ t('graph.allKeywords') }}</option>
        <option v-for="name in keywordNames" :key="name" :value="name">{{ name }}</option>
      </select>
    </div>

    <div v-if="tooltip" class="graph-tooltip card" :style="{ left: `${tooltip.x}px`, top: `${tooltip.y}px` }">
      <template v-if="tooltip.kind === 'post'">
        <p class="tooltip-book serif">{{ tooltip.title }}</p>
        <p class="tooltip-passage underlined">{{ tooltip.detail }}</p>
      </template>
      <template v-else>
        <p class="tooltip-keyword">{{ tooltip.title }}</p>
        <p class="tooltip-detail">{{ t('graph.postsTagged', { count: tooltip.count }) }}</p>
      </template>
    </div>
  </div>
</template>

<script setup lang="ts">
import * as d3 from 'd3'

export interface GraphPostNode {
  id: string
  type: 'post'
  post: {
    book: { title: string }
    passage: { text: string }
  }
}

export interface GraphKeywordNode {
  id: string
  type: 'keyword'
  keyword: { id: string; name: string }
}

export type GraphNodeData = GraphPostNode | GraphKeywordNode

export interface GraphEdgeData {
  id: string
  source_id: string
  target_id: string
  type: string
}

interface SimNode extends d3.SimulationNodeDatum {
  id: string
  raw: GraphNodeData
}

interface SimLink extends d3.SimulationLinkDatum<SimNode> {
  id: string
  type: string
}

const props = defineProps<{ nodes: GraphNodeData[]; edges: GraphEdgeData[] }>()
const { t } = useI18n()

const containerEl = ref<HTMLElement | null>(null)
const keywordFilter = ref('')

const keywordNames = computed(() =>
  props.nodes
    .filter((node): node is GraphKeywordNode => node.type === 'keyword')
    .map((node) => node.keyword.name)
    .sort((a, b) => a.localeCompare(b)),
)

interface Tooltip {
  x: number
  y: number
  kind: 'post' | 'keyword'
  title: string
  detail?: string
  count?: number
}

const tooltip = ref<Tooltip | null>(null)

let simulation: d3.Simulation<SimNode, SimLink> | null = null
let zoomBehavior: d3.ZoomBehavior<SVGSVGElement, unknown> | null = null
let svg: d3.Selection<SVGSVGElement, unknown, null, undefined> | null = null
let nodeSelection: d3.Selection<SVGCircleElement, SimNode, SVGGElement, unknown> | null = null
let linkSelection: d3.Selection<SVGLineElement, SimLink, SVGGElement, unknown> | null = null

function connectedNodeIds(nodeId: string, links: SimLink[]): Set<string> {
  const ids = new Set<string>([nodeId])
  for (const link of links) {
    const sourceId = typeof link.source === 'string' ? link.source : (link.source as SimNode).id
    const targetId = typeof link.target === 'string' ? link.target : (link.target as SimNode).id
    if (sourceId === nodeId) ids.add(targetId)
    if (targetId === nodeId) ids.add(sourceId)
  }
  return ids
}

function applyKeywordFilter() {
  if (!nodeSelection || !linkSelection) return

  if (!keywordFilter.value) {
    nodeSelection.attr('opacity', 1)
    linkSelection.attr('opacity', 1)
    return
  }

  const activeNode = props.nodes.find(
    (node) => node.type === 'keyword' && node.keyword.name === keywordFilter.value,
  )
  if (!activeNode) return

  const links = linkSelection.data()
  const highlighted = connectedNodeIds(activeNode.id, links)

  nodeSelection.attr('opacity', (node) => (highlighted.has(node.id) ? 1 : 0.15))
  linkSelection.attr('opacity', (link) => {
    const sourceId = typeof link.source === 'string' ? link.source : (link.source as SimNode).id
    const targetId = typeof link.target === 'string' ? link.target : (link.target as SimNode).id
    return highlighted.has(sourceId) && highlighted.has(targetId) ? 1 : 0.15
  })
}

watch(keywordFilter, applyKeywordFilter)

function buildTooltip(raw: GraphNodeData, x: number, y: number, links: SimLink[]): Tooltip {
  if (raw.type === 'post') {
    return { x, y, kind: 'post', title: raw.post.book.title, detail: raw.post.passage.text.slice(0, 140) }
  }

  const count = links.filter((link) => {
    const sourceId = typeof link.source === 'string' ? link.source : (link.source as SimNode).id
    const targetId = typeof link.target === 'string' ? link.target : (link.target as SimNode).id
    return sourceId === raw.id || targetId === raw.id
  }).length

  return { x, y, kind: 'keyword', title: raw.keyword.name, count }
}

function zoomBy(factor: number) {
  if (!svg || !zoomBehavior) return
  svg.transition().duration(150).call(zoomBehavior.scaleBy, factor)
}

function renderGraph() {
  if (!containerEl.value) return

  containerEl.value.replaceChildren()
  simulation?.stop()

  const width = containerEl.value.clientWidth
  const height = containerEl.value.clientHeight

  const simNodes: SimNode[] = props.nodes.map((node) => ({ id: node.id, raw: node }))
  const simLinks: SimLink[] = props.edges.map((edge) => ({
    id: edge.id,
    type: edge.type,
    source: edge.source_id,
    target: edge.target_id,
  }))

  svg = d3
    .select(containerEl.value)
    .append('svg')
    .attr('width', width)
    .attr('height', height)

  const root = svg.append('g')

  zoomBehavior = d3
    .zoom<SVGSVGElement, unknown>()
    .scaleExtent([0.2, 4])
    .on('zoom', (event) => root.attr('transform', event.transform))
  svg.call(zoomBehavior)

  linkSelection = root
    .append('g')
    .attr('stroke', 'var(--color-border)')
    .attr('stroke-width', 1.5)
    .selectAll<SVGLineElement, SimLink>('line')
    .data(simLinks)
    .join('line')
    .on('mouseenter', function (this: SVGLineElement) {
      d3.select(this).attr('stroke', 'var(--color-accent-secondary)').attr('stroke-width', 2.5)
    })
    .on('mouseleave', function (this: SVGLineElement) {
      d3.select(this).attr('stroke', 'var(--color-border)').attr('stroke-width', 1.5)
    })

  const nodeGroup = root.append('g')

  nodeSelection = nodeGroup
    .selectAll<SVGCircleElement, SimNode>('circle')
    .data(simNodes)
    .join('circle')
    .attr('r', (node) => (node.raw.type === 'keyword' ? 14 : 7))
    .attr('fill', (node) => (node.raw.type === 'keyword' ? 'var(--color-accent-secondary)' : 'var(--color-highlight)'))
    .style('cursor', 'pointer')
    .call(
      d3
        .drag<SVGCircleElement, SimNode>()
        .on('start', (event, node) => {
          if (!event.active) simulation?.alphaTarget(0.3).restart()
          node.fx = node.x
          node.fy = node.y
        })
        .on('drag', (event, node) => {
          node.fx = event.x
          node.fy = event.y
        })
        .on('end', (event, node) => {
          if (!event.active) simulation?.alphaTarget(0)
          node.fx = null
          node.fy = null
        }),
    )
    .on('mouseenter', (event: MouseEvent, node) => {
      if (!containerEl.value) return
      const rect = containerEl.value.getBoundingClientRect()
      tooltip.value = buildTooltip(
        node.raw,
        event.clientX - rect.left,
        event.clientY - rect.top,
        simLinks,
      )
    })
    .on('mouseleave', () => {
      tooltip.value = null
    })

  const labelSelection = nodeGroup
    .selectAll<SVGTextElement, SimNode>('text')
    .data(simNodes.filter((node) => node.raw.type === 'keyword'))
    .join('text')
    .text((node) => (node.raw as GraphKeywordNode).keyword.name)
    .attr('text-anchor', 'middle')
    .attr('font-family', 'var(--font-sans)')
    .attr('font-size', 10)
    .attr('fill', 'var(--color-ink)')
    .style('pointer-events', 'none')

  simulation = d3
    .forceSimulation(simNodes)
    .force(
      'link',
      d3
        .forceLink<SimNode, SimLink>(simLinks)
        .id((node) => node.id)
        .distance((link) => (link.type === 'keyword' ? 60 : 100)),
    )
    .force('charge', d3.forceManyBody().strength(-140).distanceMax(300))
    .force('center', d3.forceCenter(width / 2, height / 2))
    .force(
      'collide',
      d3.forceCollide<SimNode>((node) => (node.raw.type === 'keyword' ? 20 : 12)),
    )
    // Pulls every node gently toward the center, independent of its links.
    // forceCenter alone only recenters the *average* position once per
    // tick — it does nothing to stop charge (repulsion) from pushing a
    // node, or a whole disconnected component, further and further away
    // for as long as the simulation stays reheated (e.g. the entire time
    // a drag is held, via alphaTarget below). Without this, an isolated
    // node (no links at all) has literally nothing opposing that push.
    .force('x', d3.forceX<SimNode>(width / 2).strength(0.03))
    .force('y', d3.forceY<SimNode>(height / 2).strength(0.03))
    .on('tick', () => {
      linkSelection
        ?.attr('x1', (link) => (link.source as SimNode).x ?? 0)
        .attr('y1', (link) => (link.source as SimNode).y ?? 0)
        .attr('x2', (link) => (link.target as SimNode).x ?? 0)
        .attr('y2', (link) => (link.target as SimNode).y ?? 0)

      nodeSelection?.attr('cx', (node) => node.x ?? 0).attr('cy', (node) => node.y ?? 0)

      labelSelection.attr('x', (node) => node.x ?? 0).attr('y', (node) => (node.y ?? 0) + 26)
    })

  applyKeywordFilter()
}

onMounted(renderGraph)

onUnmounted(() => {
  simulation?.stop()
  simulation = null
})

watch(() => [props.nodes, props.edges], renderGraph)
</script>

<style scoped>
.graph-canvas-wrap {
  position: relative;
  width: 100%;
  height: 100%;
  background: var(--color-bg);
}

.graph-canvas {
  width: 100%;
  height: 100%;
}

.graph-toolbar {
  position: absolute;
  top: 16px;
  right: 16px;
  display: flex;
  align-items: center;
  gap: 4px;
  background: var(--color-surface);
  border-radius: var(--radius-pill);
  box-shadow: 0 2px 8px rgba(34, 37, 43, 0.1);
  padding: 6px;
}

.toolbar-btn {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  border: none;
  background: none;
  color: var(--color-ink);
  font-size: 1rem;
  line-height: 1;
  cursor: pointer;
}

.toolbar-btn:hover {
  background: var(--color-highlight-fill);
}

.toolbar-select {
  border: 1px solid var(--color-border);
  border-radius: var(--radius-pill);
  padding: 4px 10px;
  font-size: 0.8rem;
  font-family: var(--font-sans);
  background: var(--color-surface);
  color: var(--color-ink);
}

.graph-tooltip {
  position: absolute;
  transform: translate(-50%, calc(-100% - 14px));
  max-width: 220px;
  padding: 10px 14px;
  pointer-events: none;
  z-index: 10;
}

.tooltip-book {
  margin: 0 0 4px;
  font-size: 0.9rem;
}

.tooltip-passage,
.tooltip-detail {
  margin: 0;
  font-size: 0.8rem;
  color: var(--color-text-secondary);
}

.tooltip-keyword {
  margin: 0 0 2px;
  font-weight: 600;
  font-size: 0.85rem;
  color: var(--color-ink);
}
</style>
