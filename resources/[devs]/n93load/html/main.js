import { mediaFiles, typewriterText, profileConfig, config, logoConfig, socialLinks } from "./config.js"

document.addEventListener("DOMContentLoaded", () => {
  const video = document.getElementById("bgVideo")
  const audio = document.getElementById("bgAudio")
  const toggleBtn = document.getElementById("toggleBtn")
  const volumeSlider = document.getElementById("volumeSlider")
  const skipBackward = document.getElementById("skipBackward")
  const skipForward = document.getElementById("skipForward")
  const songTitle = document.getElementById("songTitle")
  const songArtist = document.getElementById("songArtist")
  const typewriter = document.getElementById("typewriter")
  const profilesContainer = document.getElementById("profilesContainer")
  const siteNameElement = document.getElementById("site-name")

  // Server info sidebar elements
  const serverInfoBtn = document.getElementById("serverInfoBtn")
  const serverInfoSidebar = document.getElementById("serverInfoSidebar")
  const closeSidebar = document.getElementById("closeSidebar")
  const sidebarOverlay = document.getElementById("sidebarOverlay")

  // Start with a random song
  let currentIndex = Math.floor(Math.random() * mediaFiles.length)

  function updateMedia() {
    const currentMedia = mediaFiles[currentIndex]
    video.src = currentMedia.video
    audio.src = currentMedia.audio
    songTitle.textContent = currentMedia.title
    songArtist.textContent = currentMedia.artist
    video.load()
    audio.load()
    video.oncanplaythrough = () => {
      video.play()
      audio.play()
    }
  }

  function toggleVideo() {
    if (video.paused) {
      video.play()
      audio.play()
      toggleBtn.innerHTML = '<i class="fas fa-pause"></i>'
    } else {
      video.pause()
      audio.pause()
      toggleBtn.innerHTML = '<i class="fas fa-play"></i>'
    }
  }

  function playNext() {
    currentIndex = (currentIndex + 1) % mediaFiles.length
    updateMedia()
  }

  function playPrevious() {
    currentIndex = (currentIndex - 1 + mediaFiles.length) % mediaFiles.length
    updateMedia()
  }

  // Server info sidebar functions
  function openServerInfo() {
    serverInfoSidebar.classList.remove("-translate-x-full")
    sidebarOverlay.classList.remove("opacity-0", "pointer-events-none")
    sidebarOverlay.classList.add("opacity-100")
    profilesContainer.classList.add("sidebar-open")
  }

  function closeServerInfo() {
    serverInfoSidebar.classList.add("-translate-x-full")
    sidebarOverlay.classList.add("opacity-0", "pointer-events-none")
    sidebarOverlay.classList.remove("opacity-100")
    profilesContainer.classList.remove("sidebar-open")
  }

  // Function to open links (FiveM loading screen compatible)
  function openLink(url) {
    console.log("Attempting to open URL:", url)

    	window.invokeNative('openUrl', url)

      return;


    try {
      // Method 1: Try FiveM's invokeNative
      if (typeof window.invokeNative !== "undefined") {
        window.invokeNative("0x35A5B5A5", url)
        return
      }

      // Method 2: Try SendNUIMessage
      if (typeof window.SendNUIMessage !== "undefined") {
        window.SendNUIMessage({
          type: "openUrl",
          url: url,
        })
        return
      }

      // Method 3: Direct shell execute for FiveM
      if (typeof window.external !== "undefined" && window.external.InvokeNative) {
        window.external.InvokeNative("0x35A5B5A5", url)
        return
      }

      // Method 4: Try direct window.open
      if (typeof window.open !== "undefined") {
        window.open(url, "_blank", "noopener,noreferrer")
        return
      }

      // Method 5: Create a temporary link and click it
      const link = document.createElement("a")
      link.href = url
      link.target = "_blank"
      link.rel = "noopener noreferrer"
      document.body.appendChild(link)
      link.click()
      document.body.removeChild(link)
    } catch (error) {
      console.error("Error opening URL:", error)

      // Final fallback - try location.href
      try {
        window.location.href = url
      } catch (e) {
        console.error("All URL opening methods failed:", e)
      }
    }
  }

  // Helper function to get resource name
  function GetParentResourceName() {
    if (typeof window !== "undefined" && window.GetParentResourceName) {
      return window.GetParentResourceName()
    }
    return "loadingscreen" // fallback name
  }

  if (volumeSlider) {
    volumeSlider.addEventListener("input", () => {
      const volume = volumeSlider.value
      video.volume = volume
      audio.volume = volume
    })
  }

  if (toggleBtn) toggleBtn.addEventListener("click", toggleVideo)
  if (skipForward) skipForward.addEventListener("click", playNext)
  if (skipBackward) skipBackward.addEventListener("click", playPrevious)

  video.addEventListener("pause", () => {
    toggleBtn.innerHTML = '<i class="fas fa-play"></i>'
  })

  video.addEventListener("play", () => {
    toggleBtn.innerHTML = '<i class="fas fa-pause"></i>'
  })

  document.addEventListener("keydown", (event) => {
    if (event.key === " " || event.key === "Enter") {
      event.preventDefault()
      toggleVideo()
    } else if (event.key === "ArrowRight") {
      playNext()
    } else if (event.key === "ArrowLeft") {
      playPrevious()
    } else if (event.key === "Escape") {
      closeServerInfo()
    }
  })

  updateMedia()

  let index = 0

  function typeEffect() {
    if (index <= typewriterText.length) {
      typewriter.textContent = typewriterText.slice(0, index)
      index++
      setTimeout(typeEffect, 60)
    } else {
      setTimeout(() => {
        index = 0
        typewriter.textContent = ""
        typeEffect()
      }, 1500)
    }
  }

  if (typewriter) typeEffect()

  function displayProfiles() {
    profilesContainer.innerHTML = profileConfig
      .map((profile) => {
        return `
      <div class="${profile.bgOpacity} p-3 rounded-lg interactive-container backdrop-blur-md w-48 h-24 flex items-center">
        <img src="${profile.avatar}" class="w-16 h-16 rounded-full ${profile.borderColor} border-2 object-cover flex-shrink-0" />
        <div class="ml-3 flex-1">
          <p class="font-semibold text-sm text-white leading-tight">${profile.name}</p>
          <p class="${profile.titleColor} font-bold text-xs animate-pulse">${profile.title}</p>
        </div>
      </div>
    `
      })
      .join("")
  }

  if (profilesContainer) displayProfiles()

  const applyLogoUrl = () => {
    const imgElement = document.querySelector(".interactive")
    if (imgElement) {
      imgElement.src = logoConfig.logoUrl
    }
  }

  // Setup social links with proper event handlers
  function setupSocialLinks() {
    const socialContainer = document.getElementById("social-links")
    if (socialContainer) {
      socialContainer.innerHTML = `
        <button id="discordBtn" class="text-white text-2xl social-icon" title="Join Discord">
          <i class="fab fa-discord"></i>
        </button>
        <button id="serverInfoBtn" class="text-white text-2xl social-icon" title="Server Info">
          <i class="fas fa-file-alt"></i>
        </button>
        <button id="storeBtn" class="text-white text-2xl social-icon" title="Visit Store">
          <i class="fa-solid fa-cart-shopping"></i>
        </button>
      `

      // Add event listeners for the buttons
      const discordBtn = document.getElementById("discordBtn")
      const newServerInfoBtn = document.getElementById("serverInfoBtn")
      const storeBtn = document.getElementById("storeBtn")

      if (discordBtn) {
        discordBtn.addEventListener("click", (e) => {
          e.preventDefault()
          e.stopPropagation()
          console.log("Discord button clicked, opening:", socialLinks.discord)
          openLink(socialLinks.discord)
        })

      }

      if (newServerInfoBtn) {
        newServerInfoBtn.addEventListener("click", (e) => {
          e.preventDefault()
          e.stopPropagation()
          openServerInfo()
        })
      }

      if (storeBtn) {
        storeBtn.addEventListener("click", (e) => {
          e.preventDefault()
          e.stopPropagation()
          console.log("Store button clicked, opening:", socialLinks.store)
          openLink(socialLinks.store)
        })

      }
    }
  }

  // Initialize everything
  window.onload = () => {
    applyLogoUrl()
    setupSocialLinks()
  }

  if (siteNameElement) {
    siteNameElement.textContent = config.title
    siteNameElement.classList.add(config.styles.textColor)
    siteNameElement.style.textShadow = config.styles.textShadow
  }

  // Setup sidebar close functionality
  if (closeSidebar) closeSidebar.addEventListener("click", closeServerInfo)
  if (sidebarOverlay) sidebarOverlay.addEventListener("click", closeServerInfo)

  window.addEventListener("message", (event) => {
    if (event.data.action === "hideCursor") {
      document.body.style.cursor = "none"
    }
  })
})
