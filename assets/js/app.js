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
  mounted() {
    this.el.addEventListener("mouseover", event => {
      setActiveIndex(Array.from(this.el.parentNode.children).indexOf(this.el));
    })
    this.el.addEventListener("click", event => {
      this.pushEvent("add_to", {
        id: this.el.attributes.suggestion_id.value
      })
    })
  }
}

let activeIndex = 0;
const setActiveIndex = (newIndex) => {
    const container = document.getElementById("to-address-container");
    // remove active from old
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
                case "Enter":
                    let activeElement = document.getElementById("to-address-container").children[activeIndex];
                    this.pushEvent("add_to", {
                      id: activeElement.attributes["phx-value-id"].value
                    })
                    event.preventDefault()
                    break;
                case "Escape":
                    break;
                default:
                    return;
            }
            event.preventDefault()
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
