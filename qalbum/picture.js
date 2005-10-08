var hidePreamble = hash.indexOf("scaled-only") > 0;
var up_button_link;
function OnLoad() {
  up_button_link = document.getElementById("up-button");
  if (up_button_link)
    up_button_link.href = "index.html"+hash;
}
function LoadSize() {
  OnLoad();
  preamble.style.visibility = hidePreamble ? "hidden" : "visible";
  image = document.getElementsByTagName("img")[0];
  image.origwidth = image.getAttribute("width");
  image.origheight = image.getAttribute("height");
  ScaleSize();
  image.style.visibility = "visible";
}
function changeStyle(style) {
}
function ScaleSize() {
  /* Window size calculation from S5 slides.css. by Eric Meyer. */
  var hSize, vSize;
   if (window.innerHeight) {
          vSize = window.innerHeight;
          hSize = window.innerWidth;
  } else if (document.documentElement.clientHeight) {
          vSize = document.documentElement.clientHeight;
          hSize = document.documentElement.clientWidth;
  } else if (document.body.clientHeight) {
          vSize = document.body.clientHeight;
          hSize = document.body.clientWidth;
  } else {
          vSize = 700;  // assuming 1024x768, minus chrome and such
          hSize = 1024; // these do not account for kiosk mode or Opera Show
  }
  var image = document.getElementsByTagName("img")[0];
  var wscale = hSize /  image.origwidth;
  var hscale = vSize / image.origheight;
  var scale = Math.min(wscale, hscale);
  image.style.width = scale * image.origwidth;
  image.style.height = scale * image.origheight;
}
