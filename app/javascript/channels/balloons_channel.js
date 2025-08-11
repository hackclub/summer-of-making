import consumer from "channels/consumer"

consumer.subscriptions.create("BalloonsChannel", {
  connected() {
  },

  disconnected() {
  },

  received(data) {
    console.log("ayo!", data)
    
    if (!window.flipperFlags || !window.flipperFlags.realTimeBalloons) {
      return
    }
    
    this.createFloatingBalloon(data)
  },

  createFloatingBalloon(data) {
    const exb = document.querySelectorAll('.floating-balloon-container')
    if (exb.length >= 20) { return }

    const cardWidth = window.innerWidth < 768 ? 250 : 300
    const maxLeft = Math.max(0, window.innerWidth - cardWidth - 20)
    const randomLeft = Math.random() * maxLeft

    // Create balloon container
    const balloonContainer = document.createElement('div')
    balloonContainer.className = 'floating-balloon-container'
    balloonContainer.style.cssText = `
      position: fixed;
      bottom: -200px;
      left: ${randomLeft}px;
      z-index: 10;
      pointer-events: none;
      animation: balloon-float 15s linear forwards;
    `

    // Create balloon content based on type
    if (data.type === 'Devlog') {
      balloonContainer.innerHTML = this.createDevlogBalloon(data)
    } else if (data.type === 'ShipEvent') {
      balloonContainer.innerHTML = this.createShipEventBalloon(data)
    }

    // Add hover effects to the link
    const card = balloonContainer.querySelector('.balloon-card')
    if (card) {
      card.addEventListener('mouseenter', () => {
        card.style.transform = 'scale(1.05)'
      })
      card.addEventListener('mouseleave', () => {
        card.style.transform = 'scale(1)'
      })
    }

    // Add to page
    document.body.appendChild(balloonContainer)

    // Remove after animation
    setTimeout(() => {
      if (balloonContainer.parentNode) {
        balloonContainer.parentNode.removeChild(balloonContainer)
      }
    }, 15000)
  },

  createDevlogBalloon(data) {
    const template = document.getElementById('balloon-template')
    let balloonSvg = template ? template.innerHTML : ''
    
    // Color the balloon string with user's color
    balloonSvg = balloonSvg.replace('stroke="#4A2D24"', `stroke="${data.color}"`)
    
    return `
      <div style="position: relative; display: flex; flex-direction: column; align-items: center;">
        <div class="balloon-body" style="margin-bottom: -5px; z-index: 2; color: #e2e8f0;">
          ${balloonSvg}
        </div>
        <div class="string-sway-container" style="display: flex; flex-direction: column; align-items: center;">
          <a href="${data.href}" target="_blank" class="balloon-card" style="
          display: block;
          text-decoration: none;
          border-radius: 0.5rem;
          border: 2px solid rgba(124, 74, 51, 0.1);
          background: radial-gradient(circle at 50% 50%, #F6DBBA, #E6D4BE);
          padding: 1rem;
          max-width: 20rem;
          box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
          z-index: 1;
          cursor: pointer;
          transition: transform 0.2s ease;
        ">
          <div style="margin-bottom: 0.75rem;">
            <span style="font-weight: 600; font-size: 0.875rem; color: #374151;">dev logged!</span>
          </div>
          <p style="font-size: 0.875rem; color: ${data.color}; margin: 0; font-weight: 500; line-height: 1.4;">${data.tagline}</p>
          </a>
        </div>
      </div>
    `
  },

  createShipEventBalloon(data) {
    const template = document.getElementById('balloon-template')
    let balloonSvg = template ? template.innerHTML : ''
    
    // Color the balloon string with user's color
    balloonSvg = balloonSvg.replace('stroke="#4A2D24"', `stroke="${data.color}"`)
    
    return `
      <div style="position: relative; display: flex; flex-direction: column; align-items: center;">
        <div class="balloon-body" style="margin-bottom: -10px; z-index: 2; color: ${data.color};">
          ${balloonSvg}
        </div>
        <div class="string-sway-container" style="display: flex; flex-direction: column; align-items: center;">
          <a href="${data.href}" target="_blank" class="balloon-card" style="
          display: block;
          text-decoration: none;
          border-radius: 0.5rem;
          border: 2px solid rgba(124, 74, 51, 0.1);
          background: radial-gradient(circle at 50% 50%, #F6DBBA, #E6D4BE);
          padding: 1rem;
          max-width: 20rem;
          box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
          z-index: 1;
          cursor: pointer;
          transition: transform 0.2s ease;
        ">
          <div style="margin-bottom: 0.75rem;">
            <span style="font-weight: 600; font-size: 0.875rem; color: #374151;">project shipped!
            </span>
          </div>
          <p style="font-size: 0.875rem; color: ${data.color}; margin: 0; font-weight: 500; line-height: 1.4;">${data.tagline}</p>
          </a>
        </div>
      </div>
    `
  }
});
