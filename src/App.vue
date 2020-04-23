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
  html, body {
    overflow: hidden;
    margin: 0 !important;
    padding: 0 !important;
  }
</style>
