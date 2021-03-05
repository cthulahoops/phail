// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"
import {Socket} from "phoenix"
import NProgress from "nprogress"
import {LiveSocket} from "phoenix_live_view"

let Hooks = {}
Hooks.AddressSuggestion = {
  updated() {
    if (parseInt(this.el.attributes["phx-value-index"].value) === activeIndex) {
      this.el.classList.add("active-suggestion");
    }
  },
  mounted() {
    if (parseInt(this.el.attributes["phx-value-index"].value) === activeIndex) {
      this.el.classList.add("active-suggestion");
    }
    this.el.addEventListener("mouseover", event => {
      setActiveIndex(parseInt(this.el.attributes["phx-value-index"].value));
    })
    this.el.addEventListener("click", event => {
      this.pushEvent("add_to", {
        id: this.el.attributes["phx-value-id"].value
      })
    })
  }
}

let activeIndex = 0;
const setActiveIndex = (newIndex) => {
    const container = document.getElementById("to-address-container");
    if (newIndex >= container.children.length) {
        newIndex = container.children.length - 1;
    } else if (newIndex < 0) {
        newIndex = 0;
    }

    if (activeIndex !== newIndex) {
        if (activeIndex < container.children.length) {
            container.children[activeIndex].classList.remove("active-suggestion");
        }
        container.children[newIndex].classList.add("active-suggestion");
    }

    activeIndex = newIndex;
}

Hooks.AddressInput = {
    mounted() {
        this.el.addEventListener("keydown", event => {
            console.log(event.keyCode, event.key);
            switch (event.key) {
                case "ArrowDown":
                    setActiveIndex(activeIndex + 1);
                    break;
                case "ArrowUp":
                    setActiveIndex(activeIndex - 1);
                    break;
                case "Tab":
                case "Enter":
                    if (this.el.value === "") {
                      return
                    }
                    let container = document.getElementById("to-address-container");
                    if (container === null) {
                      this.pushEvent("add_to", {
                        address: this.el.value
                      })
                    } else {
                      let activeElement = container.children[activeIndex];
                      this.pushEvent("add_to", {
                        id: activeElement.attributes["phx-value-id"].value
                      })
                    }
                    this.el.value = "";
                    event.preventDefault()
                    break;
                case "Backspace":
                    if (this.el.value === "") {
                      const addresses = document.getElementById("to-input-div").children;
                      if (addresses.length > 1) {
                        const last = addresses[addresses.length - 2] // Very last element is the input box.
                        this.pushEvent("remove_to_address", {
                          id: last.querySelector("a.button").attributes["phx-value-id"].value
                        })
                      }
                    } else {
                      return
                    }
                case "Escape":
                    this.pushEvent("clear_suggestions", {})
                    break
                default:
                    return
            }
            event.preventDefault()
        })
        this.el.addEventListener("blur", event => {
          setTimeout(() => {
            console.log("Clearing suggestions.");
            this.pushEvent("clear_suggestions");
          }, 100);
        })
    }
}


let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks: Hooks})

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", info => NProgress.start())
window.addEventListener("phx:page-loading-stop", info => NProgress.done())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)
window.liveSocket = liveSocket
