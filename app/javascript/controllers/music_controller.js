import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle", "speechBubble", "audioTracks"]
  
  connect() {
    this.tracks = this.audioTracksTarget.querySelectorAll('audio.music-track')
    this.currentTrack = null
    this.isPlaying = false
    this.musicHasPlayed = false

    const storedPref = localStorage.getItem('summerofmakingmusic')
    const shouldAutoPlay = storedPref !== 'false'
    if (shouldAutoPlay) {
      const savedTrackName = localStorage.getItem('summerofmakingmusicTrack')
      let startIndex = null
      if (savedTrackName) {
        const arr = Array.from(this.tracks)
        startIndex = arr.findIndex(t => t.dataset.trackName === savedTrackName)
        if (startIndex < 0) startIndex = null
      }
      try {
        this.playMusic(startIndex)
      } catch (_) {
        this._setupInteractionAutoplay(startIndex)
      }
      if (this.currentTrack && this.currentTrack.play) {
        const p = this.currentTrack.play()
        if (p && typeof p.catch === 'function') {
          p.catch(() => this._setupInteractionAutoplay(startIndex))
        }
      }
    }
  }
  
  toggleMusic() {
    if (this.hasSpeechBubbleTarget) {
      this.speechBubbleTarget.classList.add('hidden')
    }
    
    if (this.isPlaying) {
      this.pauseMusic()
    } else {
      this.playMusic()
    }
  }
  
  playMusic(trackIndex = null) {
    if (!this.musicHasPlayed) {
      this.dispatch("played", { bubbles: true })
      this.musicHasPlayed = true;
    }
    
    if (this.currentTrack) {
      this.currentTrack.pause()
      this.currentTrack.removeEventListener('ended', this.handleTrackEnded)
    }
    
    const index = trackIndex !== null ? trackIndex : Math.floor(Math.random() * this.tracks.length)
    this.currentTrack = this.tracks[index]
    
    this.currentTrack.loop = false
    
    this.handleTrackEnded = () => this.playNextTrack()
    this.currentTrack.addEventListener('ended', this.handleTrackEnded)
    
    this.currentTrack.play()
    this.isPlaying = true
    this.toggleTarget.classList.add('active')

    if (window.innerWidth < 640) {
      this.element.classList.add('mobile-music-playing')
    } else {
      this.element.classList.add('music-playing')
    }
    
    const trackName = this.currentTrack.dataset.trackName
    localStorage.setItem('summerofmakingmusic', 'true')
    localStorage.setItem('summerofmakingmusicTrack', trackName)
  }
  
  playNextTrack() {
    let currentIndex = Array.from(this.tracks).indexOf(this.currentTrack)
    let nextIndex = (currentIndex + 1) % this.tracks.length
    
    this.playMusic(nextIndex)
  }
  
  pauseMusic() {
    if (this.currentTrack) {
      this.currentTrack.pause()
    }
    this.isPlaying = false
    this.toggleTarget.classList.remove('active')
    if (window.innerWidth < 640) {
      this.element.classList.remove('mobile-music-playing')
    } else {
      this.element.classList.remove('music-playing')
    }
    localStorage.setItem('summerofmakingmusic', 'false')
  }
  
  disconnect() {
    if (this.currentTrack) {
      this.currentTrack.removeEventListener('ended', this.handleTrackEnded)
      this.currentTrack.pause()
      this.currentTrack = null
    }
  }

  _setupInteractionAutoplay(startIndex) {
    const handler = () => {
      try {
        this.playMusic(startIndex)
      } catch (_) {}
      document.removeEventListener('click', handler)
      document.removeEventListener('keydown', handler)
      document.removeEventListener('touchstart', handler)
    }
    document.addEventListener('click', handler)
    document.addEventListener('keydown', handler)
    document.addEventListener('touchstart', handler)
  }
} 