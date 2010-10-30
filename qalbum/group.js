// Copyright 2006, 2010 Per Bothner

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
    var href = links[i].href;
    if (links[i].getAttribute("fixup")) {
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
    else if (links[i].parentNode.id=="group-buttons") {
      links[i].href = href.replace(/[.]html/, ".html")+hash;
    }
  }
}

function sliderSelectCurStyle(id) {
  top.slider.sliderSelect(top.slider.document.getElementById(id), top.main.style_link, top.main.navigationSubHash);
}

function sliderSelectId(id) {
  var sl = id.indexOf("/");
  var style = "";
  if (sl > 0) {
    style = id.substring(sl+1);
    id = id.substring(0, sl);
  }
  var bstyle = "";
  var m = /(.*)info$/.exec(id);
  if (m) {
    id = m[1];
    bstyle = "info";
  }
  m = /(.*)large$/.exec(id);
  if (m) {
    id = m[1];
    bstyle = "large";
  }
  top.slider.sliderSelect(top.slider.document.getElementById(id), bstyle, style);
}
function sliderSelect(node, bstyle, style) {
  if (top.selected)
    // The test for top.sliderBgcolor is for backward compatibility.
    top.selected.setAttribute("bgcolor", top.sliderBgcolor ? top.sliderBgcolor : "black");
  node.setAttribute("bgcolor", "orange");
  top.selected = node;
  var url = node.id+bstyle+".html";
  hash = node.id + bstyle;
  if (style != "") {
    hash = hash+"/"+style;
    url = url+"#"+style;
  }
  top.main.location=url;
  top.location.hash=hash;
  var scrollTop = window.pageYOffset ? window.pageYOffset
    : document.body.scrollTop;
  var row = node.parentNode.parentNode;
  if (row.offsetTop+row.offsetHeight>scrollTop+innerHeight)
    scrollTo(0, row.offsetTop);
  else if (row.offsetTop < scrollTop)
    scrollTo(0, row.offsetTop+row.offsetHeight-innerHeight);
}

function setTopHash(hash) {
    location.hash = hash;
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
