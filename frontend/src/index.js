import './main.css'
import { Elm } from './Main.elm'
import * as serviceWorker from './serviceWorker'

const app = Elm.Main.init({
  node: document.getElementById('root'),
  flags: process.env.NODE_ENV
})
app.ports.renderRecaptcha.subscribe(() => {
  requestAnimationFrame(() => {
    console.log('NODE_ENV', process.env.NODE_ENV)
    console.log('RECAPTCHA_PUBLIC_KEY', process.env.RECAPTCHA_PUBLIC_KEY)
    grecaptcha.render('recaptcha', {
      // Seems like in production we need the recaptcha
      ...(process.env.NODE_ENV === 'production' && { sitekey: process.env.RECAPTCHA_PUBLIC_KEY }),
      callback: (val) => {
        app.ports.submitRecaptcha.send(val)
      }
    })
  })
})

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
serviceWorker.unregister()

const showShareText = () => {
  const texts = document.getElementsByClassName('fv-share-text')
  for (let text of texts) {
    text.classList.remove('hidden')
  }
}

const clipboard = new ClipboardJS('.fv-share-copy')
clipboard.on('success', showShareText)
