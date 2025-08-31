import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["canvas", "image", "pointsContainer", "zoomInButton", "zoomOutButton", "placeableProjects", "placeableCount", "tooltipTemplate"]
    static values = {
        projects: Array,
        userId: Number,
        updateUrl: String,
        mapPointsUrl: String,
        unplaceUrl: String,
    }

    MIN_ZOOM = 1
    MAX_ZOOM = 4
    DRAG_THRESHOLD = 5

    connect() {
        this.initializeState()
        this.renderPoints()
        this.setupEventHandlers()
        this.updatePlaceableInstructions()
    }

    disconnect() {
        if (this.animationFrameId) cancelAnimationFrame(this.animationFrameId)
    }

    initializeState() {
        this.zoom = this.MIN_ZOOM
        this.isDragging = false
        this.animationFrameId = null
        this.velocity = { x: 0, y: 0 }
        this.currentTranslate = { x: 0, y: 0 }
        this.initialTranslate = { x: 0, y: 0 }
        this.startPos = { x: 0, y: 0 }
        this.draggedPoint = null
        this.selectedProjectId = null
        this.tooltipTimeout = null
        this.element.style.cursor = 'crosshair'
        this.updateButtonStates()
    }

    setupEventHandlers() {
        this.setupProjectSelection()
        this.setupMapClickHandler()
    }

    renderPoints() {
        this.pointsContainerTarget.innerHTML = ''
        this.projectsValue.forEach(project => this.createProjectPoint(project))
    }

    createProjectPoint(project) {
        const isOwner = project.user_id === this.userIdValue
        const pointWrapper = this.createPointWrapper(project)
        const point = this.createPoint(project, isOwner)
        const avatar = this.createAvatar(project)

        pointWrapper.appendChild(avatar)
        pointWrapper.appendChild(point)

        this.pointsContainerTarget.appendChild(pointWrapper)
    }

    createPointWrapper(project) {
        const wrapper = document.createElement("div")
        wrapper.className = "absolute transform -translate-x-1/2 -translate-y-1/2 group"
        wrapper.style.left = `${project.x}%`
        wrapper.style.top = `${project.y}%`
        wrapper.dataset.projectId = project.id
        wrapper.addEventListener('mouseenter', () => this.showTooltip(wrapper, project))
        wrapper.addEventListener('mouseleave', () => this.hideTooltip(wrapper))
        return wrapper
    }

    createPoint(project, isOwner) {
        const point = document.createElement("div")
        point.className = "w-3 h-3 rounded-full border-2 transition-transform duration-200 group-hover:scale-200"
        point.dataset.projectId = project.id

        if (isOwner) {
            point.classList.add("bg-green-500", "border-green-500", "cursor-grab")
            point.dataset.action = "mousedown->map#startPointDrag"
        } else {
            point.classList.add("border-white")
        }
        point.style.backgroundColor = project.user.favorite_color || "oklch(63.7% .237 25.331)"

        return point
    }

    createAvatar(project) {
        const avatar = document.createElement("img")
        avatar.src = project.user.avatar
        avatar.className = "w-8 h-8 rounded-full border-2 border-white absolute -top-10 left-1/2 transform -translate-x-1/2 transition-all opacity-0 group-hover:opacity-100 group-hover:-translate-y-2 pointer-events-none"
        return avatar
    }

    showTooltip(pointWrapper, project) {
        this.clearTooltipTimeout()
        if (pointWrapper.querySelector('.absolute.bottom-full')) return

        const tooltip = this.createTooltip(project)
        pointWrapper.appendChild(tooltip)
    }

    createTooltip(project) {
        const tooltip = this.tooltipTemplateTarget.content.cloneNode(true).firstElementChild
        tooltip.querySelector('[data-map-target="tooltipTitle"]').textContent = project.title
        tooltip.querySelector('[data-map-target="tooltipInfo"]').textContent = `${project.devlogs_count} updates • ${project.total_time_spent}`
        tooltip.querySelector('[data-map-target="tooltipLink"]').href = project.project_path

        const unplaceButton = tooltip.querySelector('[data-map-target="tooltipUnplaceButton"]')
        if (project.user_id === this.userIdValue) {
            unplaceButton.classList.remove('hidden')
            unplaceButton.addEventListener('click', (e) => {
                e.stopPropagation()
                this.unplaceProject(project.id)
            })
        }

        tooltip.addEventListener('mouseenter', () => this.clearTooltipTimeout())
        tooltip.addEventListener('mouseleave', () => this.hideTooltip(tooltip.parentElement))

        return tooltip
    }

    hideTooltip(pointWrapper) {
        this.tooltipTimeout = setTimeout(() => {
            const tooltip = pointWrapper.querySelector('.absolute.bottom-full')
            if (tooltip) tooltip.remove()
            this.tooltipTimeout = null
        }, 100)
    }

    clearTooltipTimeout() {
        if (this.tooltipTimeout) {
            clearTimeout(this.tooltipTimeout)
            this.tooltipTimeout = null
        }
    }

    startCardDrag(event) {
        event.dataTransfer.setData("text/plain", event.currentTarget.dataset.projectId)
        event.dataTransfer.effectAllowed = "move"
    }

    handleDragOver(event) {
        event.preventDefault()
        event.dataTransfer.dropEffect = "move"
    }

    handleDrop(event) {
        event.preventDefault()
        const projectId = event.dataTransfer.getData("text/plain")
        if (!projectId) return

        const coordinates = this.getCoordinatesFromEvent(event)
        if (!this.isValidCoordinate(coordinates)) return

        this.updateProjectPosition(projectId, coordinates.x, coordinates.y)
    }

    getCoordinatesFromEvent(event) {
        const imageRect = this.imageTarget.getBoundingClientRect()
        return {
            x: ((event.clientX - imageRect.left) / imageRect.width) * 100,
            y: ((event.clientY - imageRect.top) / imageRect.height) * 100
        }
    }

    isValidCoordinate(coordinates) {
        return coordinates.x >= 0 && coordinates.x <= 100 && coordinates.y >= 0 && coordinates.y <= 100
    }

    async updateProjectPosition(projectId, x, y) {
        try {
            await this.sendPositionUpdate(projectId, x, y)
            await this.fetchFreshMapData()
            this.removeFromPlaceableList(projectId)
        } catch (error) {
            console.error('Failed to update project position:', error)
            alert(`Error: ${error.message}`)
        }
    }

    async sendPositionUpdate(projectId, x, y) {
        const url = this.updateUrlValue.replace(':id', projectId)
        const response = await fetch(url, {
            method: 'PATCH',
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'X-CSRF-Token': this.getCSRFToken()
            },
            body: JSON.stringify({ project: { x, y } })
        })

        if (!response.ok) {
            const errorData = await response.json()
            throw new Error(errorData.errors ? errorData.errors.join(', ') : 'Failed to update position')
        }
    }

    async fetchFreshMapData() {
        try {
            const response = await fetch(this.mapPointsUrlValue, {
                method: 'GET',
                headers: { 'Accept': 'application/json' }
            })

            if (!response.ok) throw new Error('Failed to fetch fresh map data')

            const data = await response.json()
            this.projectsValue = data.projects
            this.renderPoints()
        } catch (error) {
            console.error('Failed to fetch fresh map data:', error)
            this.renderPoints()
        }
    }

    removeFromPlaceableList(projectId) {
        if (!this.hasPlaceableProjectsTarget) return

        const card = this.placeableProjectsTarget.querySelector(`[data-project-id="${projectId}"]`)
        if (card) {
            card.remove()
            this.updatePlaceableInstructions()
        }
    }

    getCSRFToken() {
        const meta = document.querySelector('meta[name="csrf-token"]')
        return meta ? meta.content : ''
    }

    startDrag(event) {
        if (this.draggedPoint || this.animationFrameId) return

        event.preventDefault()
        this.initializeDrag(event)
    }

    initializeDrag(event) {
        this.isDragging = true
        this.velocity = { x: 0, y: 0 }
        this.startPos = { x: event.clientX, y: event.clientY }
        this.initialTranslate = { ...this.currentTranslate }
        this.lastTimestamp = performance.now()
        this.element.style.cursor = 'grabbing'
        this.canvasTarget.style.transition = "none"
    }

    startPointDrag(event) {
        event.stopPropagation()
        event.preventDefault()

        this.draggedPoint = event.target.parentElement
        this.element.style.cursor = 'grabbing'
        this.draggedPoint.classList.add("z-20")

        this.setupPointDragHandlers()
    }

    setupPointDragHandlers() {
        const moveHandler = this.dragPoint.bind(this)
        const upHandler = () => {
            this.endPointDrag()
            document.removeEventListener('mousemove', moveHandler)
            document.removeEventListener('mouseup', upHandler)
        }
        document.addEventListener('mousemove', moveHandler)
        document.addEventListener('mouseup', upHandler)
    }

    dragPoint(event) {
        if (!this.draggedPoint) return

        const coordinates = this.getCoordinatesFromEvent(event)
        const clampedCoords = this.clampCoordinates(coordinates)

        this.draggedPoint.style.left = `${clampedCoords.x}%`
        this.draggedPoint.style.top = `${clampedCoords.y}%`
    }

    clampCoordinates(coordinates) {
        return {
            x: Math.max(0, Math.min(100, coordinates.x)),
            y: Math.max(0, Math.min(100, coordinates.y))
        }
    }

    endPointDrag() {
        if (!this.draggedPoint) return

        this.draggedPoint.classList.remove("z-20")
        const point = this.draggedPoint.querySelector('[data-project-id]')
        const x = parseFloat(this.draggedPoint.style.left)
        const y = parseFloat(this.draggedPoint.style.top)
        const projectId = point.dataset.projectId

        this.updateProjectPosition(projectId, x, y)
        this.draggedPoint = null
        this.element.style.cursor = 'crosshair'
    }

    drag(event) {
        if (this.draggedPoint) return this.dragPoint(event)
        if (!this.isDragging) return

        event.preventDefault()
        this.updateDragPosition(event)
    }

    updateDragPosition(event) {
        const dx = event.clientX - this.startPos.x
        const dy = event.clientY - this.startPos.y
        let nextTranslate = {
            x: this.initialTranslate.x + dx,
            y: this.initialTranslate.y + dy
        }

        nextTranslate = this.applyDragResistance(nextTranslate)
        this.updateVelocity(nextTranslate)
        this.updateTransform(false, nextTranslate)
        this.currentTranslate = nextTranslate
    }

    applyDragResistance(translate) {
        const clamped = this.getClampedTranslate(translate, 100)
        const overshoot = {
            x: translate.x - clamped.x,
            y: translate.y - clamped.y
        }

        const RESISTANCE = 0.6
        return {
            x: clamped.x + overshoot.x * RESISTANCE,
            y: clamped.y + overshoot.y * RESISTANCE
        }
    }

    updateVelocity(nextTranslate) {
        const now = performance.now()
        const elapsed = now - this.lastTimestamp

        if (elapsed > 1) {
            this.velocity = {
                x: (nextTranslate.x - this.currentTranslate.x) / elapsed,
                y: (nextTranslate.y - this.currentTranslate.y) / elapsed,
            }
        }
        this.lastTimestamp = now
    }

    endDrag(event) {
        if (this.draggedPoint) return this.endPointDrag()
        if (!this.isDragging) return

        this.isDragging = false
        this.element.style.cursor = 'crosshair'
        this.startInertia()
    }

    zoomIn() { this.setZoom(this.zoom + 0.5) }
    zoomOut() { this.setZoom(this.zoom - 0.5) }

    setZoom(newZoom) {
        const clampedZoom = Math.max(this.MIN_ZOOM, Math.min(newZoom, this.MAX_ZOOM))
        if (clampedZoom === this.zoom) return

        this.zoom = clampedZoom
        this.currentTranslate = this.getClampedTranslate(this.currentTranslate, 0)
        this.updateTransform(true, this.currentTranslate)
    }

    startInertia() {
        const FRICTION = 0.94
        const PULL_FACTOR = 0.35

        const inertiaLoop = () => {
            this.applyInertia(FRICTION, PULL_FACTOR)

            if (this.shouldStopInertia()) {
                this.stopInertia()
                return
            }

            this.updateTransform(false, this.currentTranslate)
            this.animationFrameId = requestAnimationFrame(inertiaLoop)
        }
        this.animationFrameId = requestAnimationFrame(inertiaLoop)
    }

    applyInertia(friction, pullFactor) {
        this.currentTranslate.x += this.velocity.x * 16
        this.currentTranslate.y += this.velocity.y * 16
        this.velocity.x *= friction
        this.velocity.y *= friction

        const clamped = this.getClampedTranslate(this.currentTranslate, 0)
        const overshoot = {
            x: this.currentTranslate.x - clamped.x,
            y: this.currentTranslate.y - clamped.y
        }

        const isOutOfBounds = Math.abs(overshoot.x) > 0.1 || Math.abs(overshoot.y) > 0.1
        if (isOutOfBounds) {
            this.currentTranslate.x -= overshoot.x * pullFactor
            this.currentTranslate.y -= overshoot.y * pullFactor
        }
    }

    shouldStopInertia() {
        const clamped = this.getClampedTranslate(this.currentTranslate, 0)
        const isOutOfBounds = Math.abs(this.currentTranslate.x - clamped.x) > 0.1 ||
            Math.abs(this.currentTranslate.y - clamped.y) > 0.1
        const isStill = Math.hypot(this.velocity.x, this.velocity.y) < 0.05

        return isStill && !isOutOfBounds
    }

    stopInertia() {
        this.animationFrameId = null
        this.currentTranslate = this.getClampedTranslate(this.currentTranslate, 0)
        this.updateTransform(false, this.currentTranslate)
    }

    getClampedTranslate(translate, tolerance = 0) {
        const containerRect = this.element.getBoundingClientRect()
        const scaledWidth = this.canvasTarget.offsetWidth * this.zoom
        const scaledHeight = this.canvasTarget.offsetHeight * this.zoom
        const pannableX = Math.max(0, (scaledWidth - containerRect.width) / 2)
        const pannableY = Math.max(0, (scaledHeight - containerRect.height) / 2)

        return {
            x: Math.max(-pannableX - tolerance, Math.min(translate.x, pannableX + tolerance)),
            y: Math.max(-pannableY - tolerance, Math.min(translate.y, pannableY + tolerance)),
        }
    }

    updateTransform(useTransition, translate) {
        this.canvasTarget.style.transition = useTransition ? "transform 0.2s cubic-bezier(0.25, 1, 0.5, 1)" : "none"
        this.canvasTarget.style.transform = `translate(${translate.x}px, ${translate.y}px) scale(${this.zoom})`
        if (useTransition) this.updateButtonStates()
    }

    updateButtonStates() {
        this.zoomInButtonTarget.disabled = this.zoom >= this.MAX_ZOOM
        this.zoomOutButtonTarget.disabled = this.zoom <= this.MIN_ZOOM
    }

    setupProjectSelection() {
        if (!this.hasPlaceableProjectsTarget) return

        this.placeableProjectsTarget.addEventListener('click', (event) => {
            const card = event.target.closest('[data-project-id]')
            if (card) {
                event.preventDefault()
                event.stopPropagation()
                this.selectProject(card.dataset.projectId, card)
            }
        })
    }

    setupMapClickHandler() {
        this.canvasTarget.addEventListener('click', (event) => {
            if (this.selectedProjectId && !this.isDragging && !this.draggedPoint) {
                this.handleMapClick(event)
            }
        })
    }

    selectProject(projectId, cardElement) {
        this.clearProjectSelection()
        this.selectedProjectId = projectId
        cardElement.classList.add('ring-2', 'ring-blue-500', 'bg-blue-100')
        this.element.style.cursor = 'crosshair'
        this.updatePlaceableInstructions('Click anywhere on the map to place this project, or drag it directly.')
    }

    clearProjectSelection() {
        if (!this.hasPlaceableProjectsTarget) return

        const cards = this.placeableProjectsTarget.querySelectorAll('[data-project-id]')
        cards.forEach(card => {
            card.classList.remove('ring-2', 'ring-blue-500', 'bg-blue-100')
        })
        this.selectedProjectId = null
        this.element.style.cursor = 'crosshair'
        this.updatePlaceableInstructions()
    }

    handleMapClick(event) {
        if (!this.selectedProjectId || this.isDragging || this.draggedPoint) return

        event.preventDefault()
        event.stopPropagation()

        const coordinates = this.getCoordinatesFromEvent(event)
        if (!this.isValidCoordinate(coordinates)) return

        this.updateProjectPosition(this.selectedProjectId, coordinates.x, coordinates.y)
        this.clearProjectSelection()
    }

    updatePlaceableInstructions(customMessage = null) {
        if (!this.hasPlaceableCountTarget) return

        const remaining = this.hasPlaceableProjectsTarget ? this.placeableProjectsTarget.children.length : 0

        if (customMessage) {
            this.placeableCountTarget.textContent = customMessage
        } else if (remaining > 0) {
            this.placeableCountTarget.textContent = `You can place ${remaining} more ${remaining === 1 ? 'project' : 'projects'}. Click a project below to select it, then click on the map to place it, or drag it directly.`
        } else {
            this.placeableCountTarget.textContent = 'No projects available to place. Ship a project first to add it to the map.'
        }
    }

    async unplaceProject(projectId) {
        if (!confirm('Are you sure you want to remove this project from the map?')) return

        try {
            await this.sendUnplaceRequest(projectId)
            await this.fetchFreshMapData()
            await this.refreshPlaceableProjects()
        } catch (error) {
            console.error('Failed to unplace project:', error)
            alert(`Error: ${error.message}`)
        }
    }

    async sendUnplaceRequest(projectId) {
        const url = this.unplaceUrlValue.replace(':id', projectId)
        const response = await fetch(url, {
            method: 'DELETE',
            headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'X-CSRF-Token': this.getCSRFToken()
            }
        })

        if (!response.ok) {
            const errorData = await response.json()
            throw new Error(errorData.errors ? errorData.errors.join(', ') : 'Failed to unplace project')
        }
    }

    async refreshPlaceableProjects() {
        window.location.reload()
    }
}
