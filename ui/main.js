import { createApp } from 'vue'
import { FrappeUI } from 'frappe-ui'
import App from './App.vue'
import './index.css'

const app = createApp(App)
app.use(FrappeUI)
app.mount('#app')