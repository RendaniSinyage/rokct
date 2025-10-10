<template>
  <div class="flex items-center justify-center h-screen">
    <div class="text-center">
      <h1 class="text-2xl font-bold mb-4">Welcome to Your New Frappe UI</h1>
      <Button variant="solid" @click="greet">
        Click Me!
      </Button>
    </div>
  </div>
</template>

<script setup>
import { Button, showToast } from 'frappe-ui'

const greet = () => {
  showToast({
    title: 'Hello from Frappe UI!',
    position: 'bottom-center'
  })
}
</script>