import consumer from "channels/consumer"
import {Howl} from "howler"

const doink = new Howl({
  src: "/doink.ogg"
});

consumer.subscriptions.create("BalloonsChannel", {
  connected() {
	  window.balloons = this;
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
    const sidebarWidth = 220 + 32 // Sidebar width + padding
    const minLeft = sidebarWidth + 20 // Start balloons after sidebar
    const maxLeft = Math.max(minLeft, window.innerWidth - cardWidth - 20)
    const randomLeft = minLeft + Math.random() * Math.max(0, maxLeft - minLeft)

    // Create balloon container
    const balloonContainer = document.createElement('div')
    balloonContainer.className = 'floating-balloon-container'
    balloonContainer.style.cssText = `
      position: fixed;
      bottom: -200px;
      left: ${randomLeft}px;
      z-index: 10;
      pointer-events: none;
      opacity: 0;
    `

    // Create balloon content based on type
    if (data.type === 'Devlog') {
      balloonContainer.innerHTML = this.createDevlogBalloon(data)
    } else if (data.type === 'ShipEvent') {
      balloonContainer.innerHTML = this.createShipEventBalloon(data)
    }

    // Add balloon knock effect when hovering the balloon
    balloonContainer.style.pointerEvents = 'auto'
    balloonContainer.style.cursor = 'pointer'
    balloonContainer.addEventListener('mouseenter', (e) => {
      this.knockBalloon(balloonContainer)
    })

    // Add to page
    document.body.appendChild(balloonContainer)

    // Start floating animation
    this.startFloatingAnimation(balloonContainer)
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
  },

  knockBalloon(balloonContainer) {
    
    // Don't knock if already knocking
    if (balloonContainer.isKnocking) return;
    balloonContainer.isKnocking = true;
    
    // Bouncy movement with permanent drift
    const knockX = (Math.random() - 0.5) * 20; // Random between -10px and 10px (reduced)
    const knockY = Math.random() * 25 + 15; // Random between 15px and 40px down (always down)
    const knockRotation = (Math.random() - 0.5) * 12; // Random between -6deg and 6deg
    const permanentDriftX = (Math.random() - 0.5) * 8; // Small permanent drift -4px to 4px
    const duration = 1200; // Longer for bounce
    let startTime = null;
    
    // Add to existing permanent drift
    balloonContainer.permanentDriftX = (balloonContainer.permanentDriftX || 0) + permanentDriftX;
    
    // Store the knock offset to be applied in the main animation
    balloonContainer.knockOffsetX = 0;
    balloonContainer.knockOffsetY = 0;
    balloonContainer.knockRotation = 0;
    
    // Play doink sound
    this.playDoinkSound();
    
    const animate = (currentTime) => {
      if (!startTime) startTime = currentTime;
      const elapsed = currentTime - startTime;
      const progress = Math.min(elapsed / duration, 1);
      
      if (progress >= 1) {
        // Animation complete
        balloonContainer.knockOffsetX = 0;
        balloonContainer.knockOffsetY = 0;
        balloonContainer.knockRotation = 0;
        balloonContainer.isKnocking = false;
        return;
      }
      
      // Bouncy easing with multiple bounces
      const bounce = (t) => {
        if (t < 1/2.75) {
          return 7.5625 * t * t;
        } else if (t < 2/2.75) {
          return 7.5625 * (t -= 1.5/2.75) * t + 0.75;
        } else if (t < 2.5/2.75) {
          return 7.5625 * (t -= 2.25/2.75) * t + 0.9375;
        } else {
          return 7.5625 * (t -= 2.625/2.75) * t + 0.984375;
        }
      };
      
      const bounceProgress = bounce(progress);
      const intensity = 1 - progress; // Linear decay
      
      // Bouncy motions with oscillation
      balloonContainer.knockOffsetX = knockX * intensity * Math.sin(progress * Math.PI * 3) * (1 - bounceProgress * 0.3);
      
      // Y bounce with helium balloon physics - slow recovery then faster rise
      const yOscillation = Math.sin(progress * Math.PI * 3); // Basic oscillation
      // When going up (negative yOscillation), ease in slowly then accelerate
      const yBounce = yOscillation > 0 ? yOscillation : yOscillation * (1 - Math.pow(1 - (progress % (1/3)) * 3, 3));
      balloonContainer.knockOffsetY = knockY * (yBounce * 0.7 + 0.3 * intensity) * intensity;
      
      balloonContainer.knockRotation = knockRotation * intensity * Math.sin(progress * Math.PI * 4);
      
      requestAnimationFrame(animate);
    };
    
    requestAnimationFrame(animate);
  },

  startFloatingAnimation(balloonContainer) {
    const duration = 15000; // 15 seconds total
    const totalHeight = window.innerHeight + 300; // Screen height + some extra
    let startTime = null;
    
    // Wind characteristics for this balloon
    const windPhase1 = Math.random() * Math.PI * 2; // Random phase offset
    const windPhase2 = Math.random() * Math.PI * 2; // Second wind layer phase
    const windStrength = 0.7 + Math.random() * 0.6; // Random wind strength 0.7-1.3
    const windDriftRate = (Math.random() - 0.5) * 0.01; // How much wind accumulates permanent drift
    
    // Initialize permanent wind drift
    balloonContainer.windDriftX = 0;
    
    const balloonBody = balloonContainer.querySelector('.balloon-body');
    const stringContainer = balloonContainer.querySelector('.string-sway-container');
    
    const animate = (currentTime) => {
      if (!startTime) startTime = currentTime;
      const elapsed = currentTime - startTime;
      const progress = elapsed / duration;
      
      if (progress >= 1) {
        // Animation complete, remove element
        if (balloonContainer.parentNode) {
          balloonContainer.parentNode.removeChild(balloonContainer);
        }
        return;
      }
      
      // Main upward movement - ease out
      const mainY = -totalHeight * (1 - Math.pow(1 - progress, 0.7));
      
      // Multi-layered wind drift
      const windTime1 = elapsed * 0.0006 + windPhase1; // Slow base wind
      const windTime2 = elapsed * 0.0015 + windPhase2; // Faster gusts
      const windTime3 = elapsed * 0.0003; // Very slow background drift
      
      const baseWind = Math.sin(windTime1) * 18 * windStrength;
      const gustWind = Math.sin(windTime2) * 8 * windStrength;
      const backgroundWind = Math.sin(windTime3) * 25 * windStrength;
      
      // Accumulate permanent wind drift
      balloonContainer.windDriftX += windDriftRate * windStrength;
      
      const oscillatingWind = baseWind + gustWind + backgroundWind;
      const windDrift = oscillatingWind + balloonContainer.windDriftX;
      
      // Balloon bobbing
      const bobTime = elapsed * 0.002; // Bob frequency
      const bobbing = Math.sin(bobTime) * 4;
      
      // String pendulum sway
      const swayTime = elapsed * 0.0015; // Sway frequency
      const sway = Math.sin(swayTime) * 2; // degrees
      
      // Opacity fade in/out
      let opacity;
      if (progress < 0.05) {
        opacity = progress / 0.05; // Fade in first 5%
      } else if (progress > 0.95) {
        opacity = (1 - progress) / 0.05; // Fade out last 5%
      } else {
        opacity = 1;
      }
      
      // Combine knock effects with main animation and permanent drift
      const totalX = windDrift + (balloonContainer.knockOffsetX || 0) + (balloonContainer.permanentDriftX || 0);
      const totalY = mainY + (balloonContainer.knockOffsetY || 0);
      const totalRotation = (balloonContainer.knockRotation || 0);
      
      // Apply transforms
      balloonContainer.style.transform = `translateY(${totalY}px) translateX(${totalX}px) rotate(${totalRotation}deg)`;
      balloonContainer.style.opacity = opacity;
      
      if (balloonBody) {
        balloonBody.style.transform = `translateY(${bobbing}px)`;
      }
      
      if (stringContainer) {
        stringContainer.style.transform = `rotate(${sway}deg)`;
      }
      
      requestAnimationFrame(animate);
    };
    
    requestAnimationFrame(animate);
  },

  playDoinkSound() {
    doink.play();
  }
});
