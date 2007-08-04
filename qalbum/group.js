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
      else if (hash.indexOf("#slider-") == 0)
        href = href.replace(/([^/]*)[.]html.*/, "slider.html#$1/"+hash.substring(8));
      links[i].href = href;
    }
  }
}

function sliderSelectCurStyle(id) {
  var tophash = top.location.hash;
  var sl = tophash.indexOf("/");
  if (sl > 0)
    id = id+"/"+tophash.substring(sl+1);
  top.slider.sliderSelectId(id);
}

function sliderSelectId(id) {
  var sl = id.indexOf("/");
  var style = "";
  if (sl > 0) {
    style = id.substring(sl+1);
    id = id.substring(0, sl);
  }
  top.slider.sliderSelect(top.slider.document.getElementById(id), style);
}
function sliderSelect(node, style) {
  if (top.selected)
    // The test for top.sliderBgcolor is for backward compatibility.
    top.selected.setAttribute("bgcolor", top.sliderBgcolor ? top.sliderBgcolor : "black");
  node.setAttribute("bgcolor", "red");
  top.selected = node;
  var url = node.id+".html";
  if (style=="medium-scaled")
    url = node.id+".html#medium-scaled";
  else if (style=="medium-scaled-only")
    url = node.id+".html#medium-scaled-only";
  else if (style=="large")
    url = node.id+"large.html";
  else if (style=="large-scaled")
    url = node.id+"large.html#large-scaled";
  else if (style=="medium-scaled-only")
    url = node.id+".html#medium-scaled-only";
  else if (style=="large-scaled-only")
    url = node.id+"large.html#large-scaled-only";
  else if (style!="" && style != "medium") // Error
    style = "";
  hash = style=="" ? node.id : node.id+"/"+style;
  top.main.location=url;
  // Konqueror doesn't like this: top.location.hash="#"+node.id;
  top.location.hash=hash;
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
      sliderSelectCurStyle(nextId);
      return false;
    }
  }
  if (key == 112) {
    var prevId = top.main.prevId;
    if (prevId) {
      sliderSelectCurStyle(prevId);
      return false;
    }
  }
  if (key == 117) { /* u==Up */
    top.location="index.html"+uphash;
    return true;
  }
  if (top.main.scaled && key == 104 ) {
    top.main.toggleHidePreamble();
    return false;
  }
  return true;
}
