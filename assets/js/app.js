// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import '../css/app.scss'

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import 'phoenix_html'
import { Socket } from 'phoenix'
import NProgress from 'nprogress'
import { LiveSocket } from 'phoenix_live_view'

import 'alpinejs'

window.multiInput = () => {
  return {
    active: 0,
    showSuggestions: true,
    setActive (newActive) {
      if (!this.$refs.suggestions) {
        newActive = 0
      } else if (newActive < 0) {
        newActive = 0
      } else if (newActive >= this.$refs.suggestions.children.length) {
        newActive = this.$refs.suggestions.children.length - 1
      }
      console.log('Active: ', this.active, newActive)
      this.active = newActive
    },
    activeSuggestion () {
      console.log('Refs: ', this.$refs, this.$refs.suggestions)
      if (this.$refs.suggestions) {
        return this.$refs.suggestions.children[this.active]
      } else {
        return null
      }
    },
    dispatch (eventName, data) {
      console.log('Dispatch', eventName, data, this.$refs)
    },

    addItem (event, dispatch) {
      const input = this.$refs.inputElement
      if (input.value === '') {
        return
      }

      const activeSuggestion = this.activeSuggestion()
      console.log('Active suggestion: ', this.activeSuggestion())

      let detail

      if (activeSuggestion === null) {
        detail = { address: input.value }
      } else {
        console.log('Active: ', this.activeElement, this.activeIndex)
        detail = { id: activeSuggestion.attributes['suggestion-id'].value }
      }

      dispatch('add_address', detail)
      input.value = ''

      event.preventDefault()
    },

    backspace (event, dispatch) {
      const input = this.$refs.inputElement
      if (input.value !== '') {
        return
      }
      const addresses = this.$el.children
      if (addresses.length > 1) {
        const last = addresses[addresses.length - 2]
        dispatch('remove_address', { id: last.querySelector('a.cross-icon').attributes['phx-value-id'].value })
      }
      event.preventDefault()
    },

    input: {
      '@keydown.arrow-down.prevent': 'setActive(active + 1)',
      '@keydown.arrow-up.prevent': 'setActive(active - 1)',
      '@keydown.tab': 'addItem($event, $dispatch)',
      '@keydown.enter.prevent': 'addItem($event, $dispatch)',
      '@keydown.backspace': 'backspace($event, $dispatch)',
      '@keydown.escape.prevent': '$dispatch("clear_suggestions")',
      '@click.away': 'showSuggestions = false',
      '@focus': 'showSuggestions = true'
    },

    suggestion: (index) => {
      return {
        '@click': "$dispatch('add_address', {id: $event.originalTarget.attributes['suggestion-id'].value})",
        '@mouseover': function () { this.active = index },
        'x-bind:class': function () { return { 'active-suggestion': this.active === index } }
      }
    }
  }
}

const Hooks = {}

Hooks.PushEvent = {
  mounted () {
    const eventNames = this.el.attributes['phx-push-event'].value.split(',')
    for (const eventName of eventNames) {
      this.el.addEventListener(eventName, (event) => {
        event.detail['input_id'] = this.el.id;
        this.pushEvent(eventName, event.detail)
      })
    }
  }
}

Hooks.LogHook = {
  updated () {
    console.log('Updated: ', this.el)
  },
  mounted () {
    console.log('Mounted: ', this.el)
  }
}

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute('content')
const liveSocket = new LiveSocket('/live', Socket, {
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
  dom: {
    onBeforeElUpdated (from, to) {
      if (from.__x) {
        window.Alpine.clone(from.__x, to)
      }
    }
  }
})

// Show progress bar on live navigation and form submits
window.addEventListener('phx:page-loading-start', info => NProgress.start())
window.addEventListener('phx:page-loading-stop', info => NProgress.done())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)
window.liveSocket = liveSocket
