<template>
  <div id="app">
    <WebGl></WebGl>
  </div>
</template>

<script>

import WebGl from "./components/mycanvas/MyCanvas";
export default {
  name: 'App',
  components: {
    WebGl
  }
}
</script>

<style>
  body, html, #app {
    margin: 0px;
    padding: 0px;
  }
</style>
