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

class MultiInput extends HTMLElement {
    constructor() {
      super()
      this._activeIndex = 0;
    }

    connectedCallback() {
      this.addEventListener("keydown", () => {
            console.log(event.keyCode, event.key);
            const input = event.originalTarget;
            switch (event.key) {
                case "ArrowDown":
                    this.activeIndex += 1
                    break;
                case "ArrowUp":
                    this.activeIndex -= 1
                    break;
                case "Tab":
                case "Enter":
                    event.preventDefault()
                    if (input.value === "") {
                      return
                    }

                    let detail;
                    if (this.activeElement === null) {
                      detail = { address: input.value }
                    } else {
                      console.log("Active: ", this.activeElement, this.activeIndex);
                      detail = { id: this.activeElement.suggestionId }
                    }

                    this.dispatchEvent(new CustomEvent("suggestionSelect", {
                      detail: detail
                    }))
                    input.value = "";
                    break;
                case "Backspace":
                    if (input.value === "") {
                      const addresses = this.children;
                      if (addresses.length > 1) {
                        const last = addresses[addresses.length - 2] // Very last element is the input box.
                        this.dispatchEvent(new CustomEvent("removeSelection", {
                          detail: {
                            id: last.querySelector("a.button").attributes["phx-value-id"].value
                          }
                        }))
                      }
                    } else {
                      return
                    }
                    break
                case "Escape":
                    this.dispatchEvent(new CustomEvent("clearSuggestions"))
                    break
                default:
                    return
            }
            event.preventDefault()
      });
      this.addEventListener("suggestionMouseOver", (event) => {
        console.log(event.originalTarget, event.originalTarget.index);
        this.activeIndex = event.originalTarget.index;
      })

      this.addEventListener("suggestionAdded", (event) => {
        if (event.originalTarget.index == this.activeIndex) {
          event.originalTarget.classList.add("active-suggestion");
        }
      })

      this.querySelector('input').addEventListener("blur", event => {
        setTimeout(() => {
          console.log("Clearing suggestions.");
          this.dispatchEvent(new CustomEvent("clearSuggestions"))
        }, 100);
      })
    }

    get activeIndex() {
      return this._activeIndex
    }

    set activeIndex(newIndex) {
      console.log("Set active: ", newIndex);
      const container = this.querySelector(".autocomplete_suggestions")
      if (newIndex >= container.children.length) {
          newIndex = container.children.length - 1;
      } else if (newIndex < 0) {
          newIndex = 0;
      }

      if (this._activeIndex !== newIndex) {
        if (this.activeIndex < container.children.length) {
            container.children[this._activeIndex].classList.remove("active-suggestion");
        }
        container.children[newIndex].classList.add("active-suggestion");

        this._activeIndex = newIndex;
      }
    }

    get activeElement() {
      let container = this.querySelector(".autocomplete_suggestions");
      if (container !== null) {
        return container.children[this.activeIndex];
      }
      else {
        return null;
      }
    }
}
customElements.define('multi-input', MultiInput)

class MultiInputSuggestion extends HTMLElement {
  connectedCallback() {
    console.log("Connected callback.");

    this.addEventListener("mouseover", event => {
      console.log("Mouse!");
      this.dispatchEvent(new CustomEvent("suggestionMouseOver", {
        bubbles: true
        }))
    })

    this.addEventListener("click", event => {
      this.dispatchEvent(new CustomEvent("suggestionSelect", {
        bubbles: true,
        detail: {
          id: this.suggestionId
        }
      }))
    })

    this.dispatchEvent(new CustomEvent("suggestionAdded", {
      bubbles: true,
    }));
  }

  get index() {
    console.log("This: ", this)
    return parseInt(this.attributes["index"].value);
  }

  get suggestionId() {
    return this.attributes["suggestion-id"].value;
  }
}

customElements.define('multi-input-suggestion', MultiInputSuggestion)

let Hooks = {}

Hooks.AddressInput = {
    mounted() {
        this.el.addEventListener("suggestionSelect", event => {
          this.pushEvent("add_to", event.detail);
        })

        this.el.addEventListener("clearSuggestions", event => {
          this.pushEvent("clear_suggestions", {});
        })

        this.el.addEventListener("removeSelection", event => {
          this.pushEvent("remove_to_address", event.detail);
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
