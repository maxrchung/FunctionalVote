import './main.css';
import { Elm } from './Main.elm';
import * as serviceWorker from './serviceWorker';

Elm.Main.init({
  node: document.getElementById('root'),
  flags: process.env.NODE_ENV
});

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
serviceWorker.unregister();

const removeShareText = () => {
  const texts = document.getElementsByClassName('fv-share-text');
  for (let text of texts) {
    text.classList.remove('hidden');
  }
};

const clipboard = new ClipboardJS(".fv-share-copy");
clipboard.on('success', removeShareText);
clipboard.on('error', removeShareText);