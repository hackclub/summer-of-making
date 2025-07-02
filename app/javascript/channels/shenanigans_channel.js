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
    <div class="${bgColor} text-white px-4 md:px-6 py-3 shadow-lg flex items-center justify-between btn-pixel max-w-full break-words notice">
        ${message}
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
          createFlash(`everybody thank ${data.responsible_individual}! 🔔 live mas...`, "notice");
        });

        bong.play();
    }
  }
});
