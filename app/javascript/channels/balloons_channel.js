import consumer from "channels/consumer"

consumer.subscriptions.create("BalloonsChannel", {
  connected() {
  },

  disconnected() {
  },

  received(data) {
    console.log("ayo!", data)
  }
});
