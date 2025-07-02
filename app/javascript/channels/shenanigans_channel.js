import consumer from "channels/consumer"
import {Howl} from "howler"

const bong = new Howl({
   src: "/bong.mp3"
});

function createFlash(message, type = "notice") {
  const flashContainer = document.getElementById("flash-container");
  if (!flashContainer) return;

  const flashElement = document.createElement("div");
  flashElement.className = "fixed top-4 right-4 left-4 md:left-auto z-50 transform transition-transform duration-500 ease-in-out translate-x-full";
  flashElement.setAttribute("data-controller", "flash");
  flashElement.setAttribute("data-flash-target", "message");
  flashElement.setAttribute("data-flash-hide-after-value", "5000");

  const bgColor = type === "alert" ? "bg-vintage-red" : "bg-forest";
  const icon = type === "alert" ? "warning.svg" : "check.svg";

  flashElement.innerHTML = `
    <div class="${bgColor} text-white px-4 md:px-6 py-3 shadow-lg flex items-center justify-between btn-pixel max-w-full break-words">
      <div class="flex items-center space-x-3 flex-grow mr-4">
        <p class="text-sm md:text-base">${message}</p>
      </div>
      <button class="flex-shrink-0 hover:scale-110 transition-transform duration-200" data-action="flash#close">
        <svg class="h-4 w-4 md:h-5 md:w-5" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"></path>
        </svg>
      </button>
    </div>
  `;

  flashContainer.appendChild(flashElement);
}

consumer.subscriptions.create("ShenanigansChannel", {
  connected() {
  },

  disconnected() {
  },

  received(data) {
    switch(data.type) {
      case "bong":
        bong.once("end", ()=>{
          createFlash(`everybody thank ${data.responsible_individual}! 🔔`, "notice");
        });

        bong.play();
    }
  }
});
