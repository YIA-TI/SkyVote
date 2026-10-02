import { defineStore } from "pinia";

let hideTimer = null;

export const useToastStore = defineStore("toast", {
  state: () => ({
    message: "",
    type: "success",
    visible: false,
  }),

  actions: {
    show(message, type = "success") {
      this.message = message;
      this.type = type;
      this.visible = true;
      clearTimeout(hideTimer);
      hideTimer = setTimeout(() => {
        this.visible = false;
      }, 3000);
    },
  },
});
