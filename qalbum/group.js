// Copyright 2006 Per Bothner

var hash = location.hash;
function handler(e) {
  var key = e ? e.which : event.keyCode;
  if (key == 117) { location="../index.html"; return false; }
  return true;
}
document.onkeypress = handler;
function fixLinks() {
  if (hash=="")
    return;
  var links = document.getElementsByTagName("a");
  for (var i = links.length; --i >= 0; ) {
    if (links[i].getAttribute("fixup")) {
      var href = links[i].href;
      if (hash=="#info")
        href = href.replace(/[.]html/, "info.html");
      else if (hash=="#large-scaled")
        href = href.replace(/[.]html/, "large.html#large-scaled");
      else if (hash=="#large-scaled-only")
        href = href.replace(/[.]html/, "large.html#large-scaled-only");
      else if (hash=="#large")
        href = href.replace(/[.]html/, "large.html");
      else if (hash=="#medium-scaled")
        href = href.replace(/[.]html/, ".html#medium-scaled");
      else if (hash=="#medium-scaled-only")
        href = href.replace(/[.]html/, ".html#medium-scaled-only");
      else if (hash=="#slider")
        href = href.replace(/([^/]*)[.]html.*/, "slider.html#$1");
      links[i].href = href;
    }
  }
}

function sliderSelectId(id) {
  top.slider.sliderSelect(top.slider.document.getElementById(id));
}
function sliderSelect(node) {
  if (top.selected)
    top.selected.setAttribute("bgcolor", "black");
  node.setAttribute("bgcolor", "red");
  top.selected = node;
  top.main.location=node.id+".html";
  // Konqueror doesn't like this: top.location.hash="#"+node.id;
  top.location.hash=node.id;
  var scrollTop = window.pageYOffset ? window.pageYOffset
    : document.body.scrollTop;
  var row = node.parentNode.parentNode;
  if (row.offsetTop+row.offsetHeight>scrollTop+innerHeight)
    scrollTo(0, row.offsetTop);
  else if (row.offsetTop < scrollTop)
    scrollTo(0, row.offsetTop+row.offsetHeight-innerHeight);
}

function sliderHandler (e) {
  var key = e ? e.which : event.keyCode;
  if (key >= 65 && key <= 90) key += 32; // Needed for Konqueor
  if (key == 110 || key == 32) {
    var nextId = top.main.nextId;
    if (nextId) {
      sliderSelectId(nextId);
      return false;
    }
  }
  if (key == 112) {
    var prevId = top.main.prevId;
    if (prevId) {
      sliderSelectId(prevId);
      return false;
    }
  }
  return true;
}
